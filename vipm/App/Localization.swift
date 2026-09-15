import SwiftUI

/// User-selectable UI language. Question and answer content stays in the bank's own language.
enum AppLanguage: String, CaseIterable, Identifiable {
    case system, en, vi

    var id: String { rawValue }

    /// Locale to inject into the environment; `nil` means follow the device.
    var locale: Locale? {
        switch self {
        case .system: nil
        case .en: Locale(identifier: "en")
        case .vi: Locale(identifier: "vi")
        }
    }

    /// Native name shown in the language picker (each in its own language, so it reads regardless of current UI language).
    var nativeName: String {
        switch self {
        case .system: String(localized: "Match device")
        case .en: "English"
        case .vi: "Tiếng Việt"
        }
    }
}
