import Foundation
import Observation

@Observable
final class StudyViewModel {
    private(set) var study: StudyUseCase
    private(set) var bankError: String?
    private let reminderScheduler: (any ExamReminderScheduling)?

    init(bankRepository: any QuestionBankRepository, progressRepository: any StudyProgressRepository,
         isPremium: Bool, reminderScheduler: (any ExamReminderScheduling)? = nil) {
        self.reminderScheduler = reminderScheduler
        let bank: QuestionBank
        do { bank = try bankRepository.load() }
        catch { bank = .empty; bankError = error.localizedDescription }
        study = StudyUseCase(bank: bank, progressRepository: progressRepository, isPremium: isPremium)
    }

    var persistenceError: String? { study.persistenceError?.localizedDescription }

    func setPremium(_ isPremium: Bool) { study.setPremium(isPremium) }
    func updateLearnerName(_ name: String) { study.updateLearnerName(name) }
    func updateExamProfile(name: String, plannedExamDate: Date) {
        study.updateExamProfile(name: name, plannedExamDate: plannedExamDate)
        reminderScheduler?.schedule(for: plannedExamDate)
    }
    func toggleBookmark(_ question: Question) { study.toggleBookmark(question) }
    func session(for key: String) -> QuizViewModel? { study.session(for: key).map(makeQuizViewModel) }
    func retake(_ previous: QuizViewModel) -> QuizViewModel { makeQuizViewModel(study.retake(previous.session)) }
    func saveDraft(_ quiz: QuizViewModel) { study.saveDraft(quiz.session) }

    func checkAnswer(_ quiz: QuizViewModel) {
        var session = quiz.session
        study.checkAnswer(&session)
        quiz.update(session)
    }

    func finish(_ quiz: QuizViewModel, at date: Date = .now) {
        var session = quiz.session
        study.finish(&session, at: date)
        quiz.update(session)
    }

    func updateTime(_ date: Date, for quiz: QuizViewModel) {
        if quiz.session.remaining(at: date) == 0 { finish(quiz, at: date) }
    }

    private func makeQuizViewModel(_ session: QuizSession) -> QuizViewModel {
        QuizViewModel(session: session, onChange: { [weak self] session in self?.study.saveDraft(session) })
    }
}
