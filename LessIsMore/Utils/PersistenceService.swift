//
//  PersistenceService.swift
//  LessIsMore
//
//  Created by Angel Geoffroy on 03/09/2025.
//

import Foundation

// MARK: - Protocole d'abstraction pour la persistance
protocol PersistenceServiceProtocol {
    func getBool(forKey key: String) -> Bool
    func setBool(_ value: Bool, forKey key: String)
    func getString(forKey key: String) -> String?
    func setString(_ value: String?, forKey key: String)
    func remove(forKey key: String)
}

// MARK: - Clés de persistance centralisées
enum PersistenceKey: String {
    case isAuthenticated
    case hasSeenOnboarding

    // Préfixe pour les filtres
    static func filter(_ filterType: String) -> String {
        return "filter_\(filterType)"
    }
}

// MARK: - Implémentation avec UserDefaults
final class PersistenceService: PersistenceServiceProtocol {

    static let shared = PersistenceService()

    private let defaults: UserDefaults

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    func getBool(forKey key: String) -> Bool {
        return defaults.bool(forKey: key)
    }

    func setBool(_ value: Bool, forKey key: String) {
        defaults.set(value, forKey: key)
    }

    func getString(forKey key: String) -> String? {
        return defaults.string(forKey: key)
    }

    func setString(_ value: String?, forKey key: String) {
        defaults.set(value, forKey: key)
    }

    func remove(forKey key: String) {
        defaults.removeObject(forKey: key)
    }

    // MARK: - Méthodes spécifiques pour l'app

    var isAuthenticated: Bool {
        get { getBool(forKey: PersistenceKey.isAuthenticated.rawValue) }
        set { setBool(newValue, forKey: PersistenceKey.isAuthenticated.rawValue) }
    }

    var hasSeenOnboarding: Bool {
        get { getBool(forKey: PersistenceKey.hasSeenOnboarding.rawValue) }
        set { setBool(newValue, forKey: PersistenceKey.hasSeenOnboarding.rawValue) }
    }

    func isFilterEnabled(_ filterType: String) -> Bool {
        return getBool(forKey: PersistenceKey.filter(filterType))
    }

    func setFilterEnabled(_ enabled: Bool, for filterType: String) {
        setBool(enabled, forKey: PersistenceKey.filter(filterType))
    }

    // MARK: - Reset toutes les données

    func resetAllFilters() {
        let filterKeys = ["reels", "explore", "stories", "suggestions", "likes", "following", "messages"]
        for key in filterKeys {
            setBool(false, forKey: PersistenceKey.filter(key))
        }
    }

    func resetAll() {
        setBool(false, forKey: PersistenceKey.isAuthenticated.rawValue)
        setBool(false, forKey: PersistenceKey.hasSeenOnboarding.rawValue)
        resetAllFilters()
    }
}
