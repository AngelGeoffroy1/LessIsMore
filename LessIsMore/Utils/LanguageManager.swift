//
//  LanguageManager.swift
//  LessIsMore
//
//  Created by Angel Geoffroy on 12/01/2026.
//

import Foundation
import SwiftUI

/// Manages app language selection and localization
class LanguageManager: ObservableObject {
    static let shared = LanguageManager()
    
    // MARK: - Published Properties
    
    @Published var currentLanguage: String {
        didSet {
            UserDefaults.standard.set(currentLanguage, forKey: languageKey)
            // Notify the app to refresh
            NotificationCenter.default.post(name: .languageChanged, object: nil)
        }
    }
    
    // MARK: - Private Properties
    
    private let languageKey = "app_language"
    private let supportedLanguages = ["en", "fr", "de", "es", "pt-BR"]
    
    // MARK: - Computed Properties
    
    /// Returns whether the current language is French
    var isFrench: Bool {
        currentLanguage == "fr"
    }
    
    /// Returns whether the current language is English
    var isEnglish: Bool {
        currentLanguage == "en"
    }
    
    /// Returns whether the current language is German
    var isGerman: Bool {
        currentLanguage == "de"
    }
    
    /// Returns whether the current language is Spanish
    var isSpanish: Bool {
        currentLanguage == "es"
    }
    
    /// Returns whether the current language is Portuguese
    var isPortuguese: Bool {
        currentLanguage == "pt-BR"
    }
    
    /// Display name for current language
    var currentLanguageDisplayName: String {
        switch currentLanguage {
        case "fr": return "Français"
        case "en": return "English"
        case "de": return "Deutsch"
        case "es": return "Español"
        case "pt-BR": return "Português"
        default: return "English"
        }
    }
    
    /// All available languages with display names
    var availableLanguages: [(code: String, name: String)] {
        [
            ("en", "English"),
            ("fr", "Français"),
            ("de", "Deutsch"),
            ("es", "Español"),
            ("pt-BR", "Português")
        ]
    }
    
    // MARK: - Initialization
    
    private init() {
        // Check for saved preference first
        if let savedLanguage = UserDefaults.standard.string(forKey: languageKey),
           supportedLanguages.contains(savedLanguage) {
            self.currentLanguage = savedLanguage
        } else {
            // Fall back to device language
            self.currentLanguage = Self.detectDeviceLanguage(supportedLanguages: supportedLanguages)
        }
    }
    
    /// Detect the device language and match it to supported languages
    private static func detectDeviceLanguage(supportedLanguages: [String]) -> String {
        // Get the device's preferred language
        let preferredLanguages = Locale.preferredLanguages
        
        for preferredLang in preferredLanguages {
            // Check for exact match first (e.g., "pt-BR")
            if supportedLanguages.contains(preferredLang) {
                return preferredLang
            }
            
            // Extract base language code (e.g., "pt-BR" -> "pt")
            let baseLanguage = preferredLang.components(separatedBy: "-").first ?? preferredLang
            
            // Check for exact match with base language
            if supportedLanguages.contains(baseLanguage) {
                return baseLanguage
            }
            
            // Check if any supported language starts with this base (e.g., "pt" matches "pt-BR")
            if let match = supportedLanguages.first(where: { $0.hasPrefix(baseLanguage + "-") || $0 == baseLanguage }) {
                return match
            }
        }
        
        // Default to English
        return "en"
    }

    
    // MARK: - Public Methods
    
    /// Set the app language
    func setLanguage(_ languageCode: String) {
        guard supportedLanguages.contains(languageCode) else { return }
        let previousLanguage = currentLanguage
        currentLanguage = languageCode
        
        // Track language change
        MixpanelManager.shared.trackLanguageChanged(from: previousLanguage, to: languageCode)
    }
    
    /// Get the bundle for the current language
    func currentBundle() -> Bundle {
        guard let path = Bundle.main.path(forResource: currentLanguage, ofType: "lproj"),
              let bundle = Bundle(path: path) else {
            return Bundle.main
        }
        return bundle
    }
    
    /// Localize a string key
    func localized(_ key: String) -> String {
        return NSLocalizedString(key, bundle: currentBundle(), comment: "")
    }
    
    /// Localize a string key with arguments
    func localized(_ key: String, _ arguments: CVarArg...) -> String {
        let format = NSLocalizedString(key, bundle: currentBundle(), comment: "")
        return String(format: format, arguments: arguments)
    }
}

// MARK: - Notification Extension

extension Notification.Name {
    static let languageChanged = Notification.Name("languageChanged")
}

// MARK: - String Extension for Easy Localization

extension String {
    /// Returns the localized version of this string key
    var localized: String {
        return LanguageManager.shared.localized(self)
    }
    
    /// Returns the localized version with format arguments
    func localized(_ arguments: CVarArg...) -> String {
        let format = LanguageManager.shared.localized(self)
        return String(format: format, arguments: arguments)
    }
}

// MARK: - View Extension for Language Updates

struct LocalizedView<Content: View>: View {
    @ObservedObject private var languageManager = LanguageManager.shared
    let content: () -> Content
    
    init(@ViewBuilder content: @escaping () -> Content) {
        self.content = content
    }
    
    var body: some View {
        content()
            .id(languageManager.currentLanguage) // Force refresh on language change
    }
}
