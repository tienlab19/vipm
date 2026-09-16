import Foundation

protocol QuestionBankRepository {
    func load() throws -> QuestionBank
}

protocol StudyProgressRepository {
    func load() throws -> StudyProgress
    func save(_ progress: StudyProgress) throws
}

protocol ExamReminderScheduling {
    func schedule(for examDate: Date)
}
