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
    private let supportedLanguages = ["en", "fr"]
    
    // MARK: - Computed Properties
    
    /// Returns whether the current language is French
    var isFrench: Bool {
        currentLanguage == "fr"
    }
    
    /// Returns whether the current language is English
    var isEnglish: Bool {
        currentLanguage == "en"
    }
    
    /// Display name for current language
    var currentLanguageDisplayName: String {
        switch currentLanguage {
        case "fr": return "Français"
        case "en": return "English"
        default: return "English"
        }
    }
    
    /// All available languages with display names
    var availableLanguages: [(code: String, name: String)] {
        [
            ("en", "English"),
            ("fr", "Français")
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
            let deviceLanguage = Locale.current.language.languageCode?.identifier ?? "en"
            self.currentLanguage = supportedLanguages.contains(deviceLanguage) ? deviceLanguage : "en"
        }
    }
    
    // MARK: - Public Methods
    
    /// Set the app language
    func setLanguage(_ languageCode: String) {
        guard supportedLanguages.contains(languageCode) else { return }
        currentLanguage = languageCode
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
