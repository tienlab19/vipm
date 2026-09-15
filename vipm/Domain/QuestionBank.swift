import Foundation

struct Answer: Identifiable {
    let id: Int
    let text: String
    let imageURL: URL?
}

struct QuestionBlock: Identifiable {
    let id: Int
    let text: String
    let imageURL: URL?
}

struct Question: Identifiable {
    var id = ""
    let question: String
    let explanation: String
    let answers: [Answer]
    let correct: Set<Int>
    let isEssay: Bool
    let essayAnswer: String
    let essayImageURL: URL?
    let imageURL: URL?
    let paragraphs: [QuestionBlock]
    let explanationParagraphs: [QuestionBlock]
    let isMulti: Bool
    let pickCount: Int

}

struct Part: Identifiable {
    let id: String
    let name: String
    let isPremium: Bool
    let questions: [Question]
}

struct QuestionBank {
    let title: String
    let updatedTime: String
    let parts: [Part]
    let isDemo: Bool

    var all: [Question] { parts.flatMap(\.questions) }

    static let empty = QuestionBank(title: "PSPOPrep", updatedTime: "", parts: [], isDemo: false)
}
