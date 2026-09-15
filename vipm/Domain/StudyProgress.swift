import Foundation

struct StudyProgress: Codable {
    var learnerName: String?
    var bookmarks: Set<String> = []
    var answered: Set<String> = []
    var wrong: Set<String> = []
    var missed: Set<String> = []
    var drafts: [String: QuizDraft] = [:]
    var completedAttempts = 0
    var bestScore: Double = 0
}
