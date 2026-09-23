//
//  vipmApp.swift
//  vipm
//
//  Created by Tien Tran on 15/9/26.
//

import SwiftUI
import FirebaseCore

@main
struct vipmApp: App {
    @State private var viewModel = MarketingCapture.studyViewModel(reminderScheduler: LocalExamReminderScheduler())
    @State private var premiumStore = PremiumStore()
    @AppStorage("appLanguage") private var language = AppLanguage.defaultValue

    init() {
        if !MarketingCapture.isActive {
            FirebaseApp.configure()
            Track.log("app_open")
        }
    }

    var body: some Scene {
        WindowGroup {
            HomeView().environment(viewModel)
                .environment(premiumStore)
                .environment(\.locale, MarketingCapture.isActive ? Locale(identifier: "en") : language.locale)
                .task {
                    if MarketingCapture.isActive {
                        viewModel.setPremium(true)
                    } else if AppFeatures.inAppPurchasesEnabled {
                        await premiumStore.prepare()
                        viewModel.setPremium(premiumStore.isPremium)
                    }
                }
                .onChange(of: premiumStore.isPremium) { _, isPremium in
                    if AppFeatures.inAppPurchasesEnabled && !MarketingCapture.isActive {
                        viewModel.setPremium(isPremium)
                    }
                }
        }
    }
}

#Preview {
    HomeView()
        .environment(makeStudyViewModel())
        .environment(PremiumStore())
}
