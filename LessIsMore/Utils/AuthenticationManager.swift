//
//  AuthenticationManager.swift
//  LessIsMore
//
//  Created by Angel Geoffroy on 03/09/2025.
//

import Foundation
import Combine

class AuthenticationManager: ObservableObject {
    @Published var isAuthenticated: Bool {
        didSet {
            UserDefaults.standard.set(isAuthenticated, forKey: "isAuthenticated")
        }
    }
    
    @Published var hasSeenOnboarding: Bool {
        didSet {
            UserDefaults.standard.set(hasSeenOnboarding, forKey: "hasSeenOnboarding")
        }
    }
    
    init() {
        self.isAuthenticated = UserDefaults.standard.bool(forKey: "isAuthenticated")
        self.hasSeenOnboarding = UserDefaults.standard.bool(forKey: "hasSeenOnboarding")
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
