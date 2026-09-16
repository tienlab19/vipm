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
    @State private var viewModel = makeStudyViewModel(reminderScheduler: LocalExamReminderScheduler())
    @State private var premiumStore = PremiumStore()
    @AppStorage("appLanguage") private var language = AppLanguage.system

    init() {
        FirebaseApp.configure()
        Track.log("app_open")
    }

    var body: some Scene {
        WindowGroup {
            HomeView().environment(viewModel)
                .environment(premiumStore)
                .environment(\.locale, language.locale ?? Locale.autoupdatingCurrent)
                .task {
                    await premiumStore.prepare()
                    viewModel.setPremium(premiumStore.isPremium)
                }
                .onChange(of: premiumStore.isPremium) { _, isPremium in
                    viewModel.setPremium(isPremium)
                }
        }
    }
}

#Preview {
    HomeView()
        .environment(makeStudyViewModel())
        .environment(PremiumStore())
}
