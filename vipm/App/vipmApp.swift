//
//  vipmApp.swift
//  vipm
//
//  Created by Tien Tran on 15/9/26.
//

import SwiftUI

@main
struct vipmApp: App {
    @State private var viewModel = makeStudyViewModel()
    @AppStorage("appLanguage") private var language = AppLanguage.system

    var body: some Scene {
        WindowGroup {
            HomeView().environment(viewModel)
                .environment(\.locale, language.locale ?? Locale.autoupdatingCurrent)
        }
    }
}

#Preview { HomeView().environment(makeStudyViewModel()) }
