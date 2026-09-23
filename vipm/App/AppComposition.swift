import Foundation

enum AppFeatures {
    // ponytail: First release includes full access; enable IAP only in a new reviewed build.
    static let inAppPurchasesEnabled = false
}

func makeStudyViewModel(bundle: Bundle = .main, defaults: UserDefaults = .standard,
                        reminderScheduler: (any ExamReminderScheduling)? = nil) -> StudyViewModel {
    return StudyViewModel(
        bankRepository: JSONQuestionBankRepository(url: bundle.url(forResource: "questions", withExtension: "json")),
        progressRepository: UserDefaultsStudyProgressRepository(defaults: defaults),
        isPremium: !AppFeatures.inAppPurchasesEnabled,
        reminderScheduler: reminderScheduler
    )
}
