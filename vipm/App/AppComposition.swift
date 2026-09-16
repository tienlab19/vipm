import Foundation

func makeStudyViewModel(bundle: Bundle = .main, defaults: UserDefaults = .standard,
                        reminderScheduler: (any ExamReminderScheduling)? = nil) -> StudyViewModel {
    return StudyViewModel(
        bankRepository: JSONQuestionBankRepository(url: bundle.url(forResource: "questions", withExtension: "json")),
        progressRepository: UserDefaultsStudyProgressRepository(defaults: defaults),
        isPremium: false,
        reminderScheduler: reminderScheduler
    )
}
