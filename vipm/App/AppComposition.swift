import Foundation

func makeStudyViewModel(bundle: Bundle = .main, defaults: UserDefaults = .standard) -> StudyViewModel {
    // ponytail: Debug bypass only; replace the Release value with a verified StoreKit entitlement before selling Premium.
    #if DEBUG
    let isPremium = true
    #else
    let isPremium = false
    #endif
    return StudyViewModel(
        bankRepository: JSONQuestionBankRepository(url: bundle.url(forResource: "questions", withExtension: "json")),
        progressRepository: UserDefaultsStudyProgressRepository(defaults: defaults),
        isPremium: isPremium
    )
}
