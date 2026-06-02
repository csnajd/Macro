import SwiftUI
import Observation

// MARK: - App Language
enum AppLanguage: String, CaseIterable {
    case arabic = "ar"
    case english = "en"

    var layoutDirection: LayoutDirection {
        self == .arabic ? .rightToLeft : .leftToRight
    }

    var locale: Locale {
        Locale(identifier: rawValue)
    }
}

// MARK: - Language Manager
// Holds the current language and looks up localized strings from an in-memory
// table. Being @Observable, any view that reads `lang.current` or calls
// `lang.t(...)` updates instantly when the language changes — which is what
// makes the in-app toggle switch the whole UI without an app restart.
@Observable
@MainActor
final class LanguageManager {

    var current: AppLanguage {
        didSet {
            UserDefaults.standard.set(current.rawValue, forKey: "appLanguage")
        }
    }

    init() {
        // Default to Arabic on first launch; otherwise restore the saved choice.
        let saved = UserDefaults.standard.string(forKey: "appLanguage")
        self.current = AppLanguage(rawValue: saved ?? "") ?? .arabic
    }

    func toggle() {
        current = (current == .arabic) ? .english : .arabic
    }

    /// Look up a localized string by key for the current language.
    /// Falls back to the key itself if missing (so missing keys are visible
    /// during development rather than silently blank).
    func t(_ key: String) -> String {
        let table = (current == .arabic) ? Self.ar : Self.en
        return table[key] ?? key
    }

    // MARK: - String Tables
    // Phase 4b fills these in for every screen. Starting with the strings
    // needed for the welcome screen + tab bar so 4a has something to show.
    // Keys are stable identifiers; values are the display text per language.

    static let en: [String: String] = [
        // Welcome
        "welcome.tagline": "Your journey starts\nwith a brick.",
        "welcome.getStarted": "Get started",
        "welcome.signInApple": "Sign in with Apple",
        // Tabs
        "tab.summary": "Summary",
        "tab.house": "House",
        "tab.portfolio": "Portfolio"
    ]

    static let ar: [String: String] = [
        // Welcome
        "welcome.tagline": "رحلتك تبدأ\nبطابوقة.",
        "welcome.getStarted": "ابدأ الآن",
        "welcome.signInApple": "تسجيل الدخول عبر Apple",
        // Tabs
        "tab.summary": "الملخص",
        "tab.house": "المنزل",
        "tab.portfolio": "المحفظة"
    ]
}