//
//  AuthenticationManager.swift
//  LessIsMore
//
//  Created by Angel Geoffroy on 03/09/2025.
//

import Foundation
import Combine

class AuthenticationManager: ObservableObject {
    private let persistence: PersistenceService

    @Published var isAuthenticated: Bool {
        didSet {
            persistence.isAuthenticated = isAuthenticated
        }
    }

    @Published var hasSeenOnboarding: Bool {
        didSet {
            persistence.hasSeenOnboarding = hasSeenOnboarding
        }
    }

    init(persistence: PersistenceService = .shared) {
        self.persistence = persistence
        self.isAuthenticated = persistence.isAuthenticated
        self.hasSeenOnboarding = persistence.hasSeenOnboarding
    }

    func logout() {
        isAuthenticated = false
        hasSeenOnboarding = false
    }

    func login() {
        isAuthenticated = true
    }

    func completeOnboarding() {
        hasSeenOnboarding = true
    }

    func resetOnboarding() {
        hasSeenOnboarding = false
    }
}
