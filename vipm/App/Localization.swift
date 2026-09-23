import SwiftUI

/// User-selectable UI language. Question and answer content stays in the bank's own language.
enum AppLanguage: String, CaseIterable, Identifiable {
    case en, vi

    var id: String { rawValue }

    static var defaultValue: AppLanguage {
        Locale.preferredLanguages.first?.lowercased().hasPrefix("vi") == true ? .vi : .en
    }

    var locale: Locale {
        switch self {
        case .en: Locale(identifier: "en")
        case .vi: Locale(identifier: "vi")
        }
    }

    /// Native name shown in the language picker (each in its own language, so it reads regardless of current UI language).
    var nativeName: String {
        switch self {
        case .en: "English"
        case .vi: "Tiếng Việt"
        }
    }
}
