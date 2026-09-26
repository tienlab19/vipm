import Foundation

enum AppFeatures {
    static let inAppPurchasesEnabled = true
    static let adsEnabled = true

    static func shouldShowAds(isPremium: Bool) -> Bool {
        adsEnabled && !isPremium
    }

    static func canRequestAds(isPremium: Bool, consentAllowsAds: Bool) -> Bool {
        shouldShowAds(isPremium: isPremium) && consentAllowsAds
    }

    static func shouldShowExamResultInterstitial(isPremium: Bool, isExam: Bool) -> Bool {
        shouldShowAds(isPremium: isPremium) && isExam
    }
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
