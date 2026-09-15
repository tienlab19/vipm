import Foundation

struct QuizDraft: Codable, Equatable {
    var id = UUID()
    let key: String
    let title: String
    let questionIDs: [String]
    let startedAt: Date
    let deadline: Date?
    var index = 0
    var picks: [String: Set<Int>] = [:]
    var essays: [String: String] = [:]
    var checked: Set<String> = []
    // ponytail: optional keeps drafts saved before flags existed decodable; make it non-optional when the key is universal.
    var flags: Set<String>?
}

struct QuizSession {
    let questions: [Question]
    var draft: QuizDraft
    private(set) var finishedAt: Date?

    init(questions: [Question], key: String = "practice", title: String, minutes: Int? = nil, startedAt: Date = .now) {
        self.questions = questions
        draft = QuizDraft(key: key, title: title, questionIDs: questions.map(\.id), startedAt: startedAt,
                          deadline: minutes.map { startedAt.addingTimeInterval(TimeInterval($0 * 60)) })
    }

    init(questions: [Question], draft: QuizDraft) { self.questions = questions; self.draft = draft }

    var title: String { draft.title }
    var index: Int { draft.index }
    var current: Question? { questions.indices.contains(index) ? questions[index] : nil }
    var picks: [String: Set<Int>] { draft.picks }
    var flags: Set<String> { draft.flags ?? [] }
    var answeredCount: Int { questions.filter(isAnswered).count }
    var deadline: Date? { draft.deadline }
    var finished: Bool { finishedAt != nil }
    var progress: Double { questions.isEmpty ? 0 : Double(index + 1) / Double(questions.count) }
    var isLast: Bool { index >= questions.count - 1 }
    var gradedQuestions: [Question] { questions.filter { !$0.isEssay } }
    var correctCount: Int { gradedQuestions.filter(isCorrect).count }
    var wrongCount: Int { gradedQuestions.filter { isAnswered($0) && !isCorrect($0) }.count }
    var missedCount: Int { questions.filter { !isAnswered($0) }.count }
    var score: Double { gradedQuestions.isEmpty ? 0 : Double(correctCount) / Double(gradedQuestions.count) }
    var elapsed: Int { max(0, Int((finishedAt ?? .now).timeIntervalSince(draft.startedAt))) }

    func remaining(at date: Date) -> Int? { deadline.map { max(0, Int(ceil($0.timeIntervalSince(date)))) } }

    mutating func toggle(_ option: Int, on question: Question) {
        guard !finished, !draft.checked.contains(question.id), question.answers.contains(where: { $0.id == option }) else { return }
        var selection = picks[question.id] ?? []
        if question.isMulti {
            if selection.contains(option) { selection.remove(option) }
            else if selection.count < question.pickCount { selection.insert(option) }
        } else { selection = selection == [option] ? [] : [option] }
        draft.picks[question.id] = selection
    }

    func isAnswered(_ question: Question) -> Bool {
        if question.isEssay { return !(draft.essays[question.id] ?? "").trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
        return !(picks[question.id] ?? []).isEmpty
    }

    func canCheck(_ question: Question) -> Bool {
        question.isEssay || (picks[question.id]?.count ?? 0) == question.pickCount
    }

    func isCorrect(_ question: Question) -> Bool { !question.isEssay && picks[question.id] == question.correct }

    mutating func checkAnswer() {
        guard !finished, let question = current, canCheck(question) else { return }
        draft.checked.insert(question.id)
    }

    mutating func updateEssay(_ text: String, for question: Question) {
        guard !finished, question.isEssay, !draft.checked.contains(question.id) else { return }
        draft.essays[question.id] = text
    }

    mutating func toggleFlag(_ question: Question) {
        guard !finished else { return }
        var flags = self.flags
        if flags.contains(question.id) { flags.remove(question.id) } else { flags.insert(question.id) }
        draft.flags = flags
    }

    mutating func jump(to index: Int) {
        guard !finished, questions.indices.contains(index) else { return }
        draft.index = index
    }

    mutating func move(by offset: Int) {
        guard !finished else { return }
        draft.index = min(max(0, draft.index + offset), max(0, questions.count - 1))
    }

    mutating func finish(at date: Date) { if !finished { finishedAt = min(date, deadline ?? date) } }
}
