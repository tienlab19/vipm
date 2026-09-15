import Foundation

struct JSONQuestionBankRepository: QuestionBankRepository {
    let url: URL?

    func load() throws -> QuestionBank {
        guard let url else { throw QuestionBankDecodingError.invalid("questions.json is missing from the app bundle.") }
        return try JSONDecoder().decode(QuestionBankDTO.self, from: Data(contentsOf: url)).value
    }
}

/// True when HTML has no visible text once tags and no-break spaces are stripped — an answer slot that would render blank.
private func htmlRendersEmpty(_ html: String) -> Bool {
    html.replacingOccurrences(of: "<[^>]+>", with: "", options: .regularExpression)
        .replacingOccurrences(of: "&nbsp;", with: " ")
        .replacingOccurrences(of: "&#160;", with: " ")
        .trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
}

struct QuestionDTO: Decodable {
    let value: Question

    init(from decoder: Decoder) throws {
        let fields = try decoder.container(keyedBy: FieldKey.self)
        let question = try fields.text("question")
        let explanation = try fields.text("explanation")
        let isEssay = try fields.flag("is_question_essay")
        let isMulti = try fields.flag("is_multi_choices")
        let essayAnswer = try fields.text("answer_for_essay")
        let essayImageURL = try fields.image("image_url_for_essay_answer")
        let imageURL = try fields.image("image_url")
        let paragraphs: [QuestionBlock] = try (1...4).compactMap { number in
            let text = try fields.text("paragraph_\(number)")
            let image = try fields.image("image_url_of_paragraph_\(number)")
            return text.isEmpty && image == nil ? nil : QuestionBlock(id: number, text: text, imageURL: image)
        }
        let explanationParagraphs: [QuestionBlock] = try (1...10).compactMap { number in
            let text = try fields.text("paragraph_\(number)_of_explanation")
            let image = try fields.image("image_url_of_paragraph_\(number)_of_explanation")
            return text.isEmpty && image == nil ? nil : QuestionBlock(id: number, text: text, imageURL: image)
        }
        let answers: [Answer] = try (1...8).compactMap { number in
            let text = try fields.text("answer_\(number)")
            let image = try fields.image("image_url_at_answer_\(number)")
            // ponytail: some exports carry visually empty HTML (e.g. "<p><br></p>") in unused answer slots;
            // test emptiness on the stripped text so those never render as blank, tappable options.
            return htmlRendersEmpty(text) && image == nil
                ? nil : Answer(id: number, text: text, imageURL: image)
        }
        let correct: Set<Int>
        if isEssay {
            correct = []
        } else if isMulti {
            let tokens = try fields.text("correct_answers").split(separator: ",", omittingEmptySubsequences: false)
            let numbers = tokens.compactMap { Int($0.trimmingCharacters(in: .whitespacesAndNewlines)) }
            guard !numbers.isEmpty, numbers.count == tokens.count, Set(numbers).count == numbers.count else {
                throw QuestionBankDecodingError.invalid("correct_answers must contain distinct, comma-separated answer numbers.")
            }
            correct = Set(numbers)
        } else {
            correct = [try fields.number("correct_answer") ?? 0]
        }
        let pickCount = isMulti ? try fields.number("how_many_choices") ?? correct.count : 1
        guard !question.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || !paragraphs.isEmpty || imageURL != nil else {
            throw QuestionBankDecodingError.invalid("A question has no content.")
        }
        if !isEssay {
            guard answers.count >= 2, !correct.isEmpty, correct.isSubset(of: Set(answers.map(\.id))),
                  pickCount == correct.count else {
                throw QuestionBankDecodingError.invalid("A question has missing answers or an invalid answer key.")
            }
        }
        value = Question(question: question, explanation: explanation, answers: answers, correct: correct,
                         isEssay: isEssay, essayAnswer: essayAnswer, essayImageURL: essayImageURL, imageURL: imageURL,
                         paragraphs: paragraphs, explanationParagraphs: explanationParagraphs, isMulti: isMulti, pickCount: pickCount)
    }
}

enum QuestionBankDecodingError: LocalizedError {
    case invalid(String)
    var errorDescription: String? {
        switch self { case .invalid(let message): message }
    }
}

struct QuestionBankDTO: Decodable {
    let title: String
    let updatedTime: String
    let parts: [Part]
    let isDemo: Bool

    var value: QuestionBank { QuestionBank(title: title, updatedTime: updatedTime, parts: parts, isDemo: isDemo) }

    init(from decoder: Decoder) throws {
        let root = try decoder.container(keyedBy: FieldKey.self)
        if root.contains(FieldKey("$examples")) {
            let examples = try root.nestedContainer(keyedBy: FieldKey.self, forKey: FieldKey("$examples"))
            let config = try examples.nestedContainer(keyedBy: FieldKey.self, forKey: FieldKey("config"))
            title = try config.text("module_title")
            updatedTime = "Illustrative schema examples"
            var single = try examples.decode(QuestionDTO.self, forKey: FieldKey("single_choice_question")).value
            var multi = try examples.decode(QuestionDTO.self, forKey: FieldKey("multi_choice_question")).value
            single.id = "examples/single"
            multi.id = "examples/multi"
            parts = [Part(id: "examples", name: "Scrum fundamentals", isPremium: false, questions: [single, multi])]
            isDemo = true
            return
        }
        let config = try root.nestedContainer(keyedBy: FieldKey.self, forKey: FieldKey("config"))
        title = try config.text("module_title")
        updatedTime = try config.text("updated_time")
        let modules = try root.nestedContainer(keyedBy: FieldKey.self, forKey: FieldKey("modules"))
        let module = try modules.nestedContainer(keyedBy: FieldKey.self, forKey: FieldKey("-Ng-ViDLQtXSAAAFYzJA"))
        let nodes = try module.nestedContainer(keyedBy: FieldKey.self, forKey: FieldKey("quiz_parts"))
        parts = try nodes.allKeys.filter { !$0.stringValue.hasPrefix("$") }.sorted { $0.stringValue < $1.stringValue }.map { partKey in
            let part = try nodes.nestedContainer(keyedBy: FieldKey.self, forKey: partKey)
            let questionNodes = try part.nestedContainer(keyedBy: FieldKey.self, forKey: FieldKey("questions"))
            let questions = try questionNodes.allKeys.filter { !$0.stringValue.hasPrefix("$") }
                .sorted { $0.stringValue < $1.stringValue }.map { questionKey in
                    var question = try questionNodes.decode(QuestionDTO.self, forKey: questionKey).value
                    question.id = "\(partKey.stringValue)/\(questionKey.stringValue)"
                    return question
                }
            let name = try part.text("name")
            guard !name.isEmpty else { throw QuestionBankDecodingError.invalid("A quiz part is missing its name.") }
            return Part(id: partKey.stringValue, name: name, isPremium: try part.flag("is_premium"), questions: questions)
        }
        guard parts.contains(where: { !$0.questions.isEmpty }) else { throw QuestionBankDecodingError.invalid("The question bank is empty.") }
        isDemo = false
    }
}

struct FieldKey: CodingKey {
    let stringValue: String
    var intValue: Int? { nil }
    init(_ value: String) { stringValue = value }
    init?(stringValue: String) { self.init(stringValue) }
    init?(intValue: Int) { return nil }
}

extension KeyedDecodingContainer where Key == FieldKey {
    func text(_ name: String) throws -> String {
        try decodeIfPresent(String.self, forKey: FieldKey(name)) ?? ""
    }

    func number(_ name: String) throws -> Int? {
        let key = FieldKey(name)
        guard contains(key), try !decodeNil(forKey: key) else { return nil }
        if let value = try? decode(Int.self, forKey: key) { return value }
        if let value = try? decode(String.self, forKey: key), let number = Int(value.trimmingCharacters(in: .whitespaces)) { return number }
        throw QuestionBankDecodingError.invalid("\(name) must be an integer or an integer string.")
    }

    func flag(_ name: String) throws -> Bool {
        if let value = try? decode(Bool.self, forKey: FieldKey(name)) { return value }
        guard let number = try number(name) else { return false }
        guard number == 0 || number == 1 else { throw QuestionBankDecodingError.invalid("\(name) must be 0, 1, or a boolean.") }
        return number == 1
    }

    func image(_ name: String) throws -> URL? {
        let value = try text(name).trimmingCharacters(in: .whitespacesAndNewlines)
        guard !value.isEmpty else { return nil }
        guard let url = URL(string: value), url.scheme?.lowercased() == "https", url.host != nil else {
            throw QuestionBankDecodingError.invalid("\(name) must be an HTTPS image URL.")
        }
        return url
    }
}
