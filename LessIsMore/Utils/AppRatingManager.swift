//
//  AppRatingManager.swift
//  LessIsMore
//
//  Created by Angel Geoffroy on 09/02/2026.
//

import StoreKit
import SwiftUI

/// Manager pour gérer la demande de notation de l'app
/// Affiche la pop-up native au 2ème lancement de l'app
class AppRatingManager {
    static let shared = AppRatingManager()
    
    private let launchCountKey = "appLaunchCount"
    private let hasRequestedReviewKey = "hasRequestedReview"
    
    private init() {}
    
    /// Incrémente le compteur de lancements et demande une notation si c'est le 2ème lancement
    func incrementLaunchCountAndRequestReviewIfNeeded() {
        let currentCount = UserDefaults.standard.integer(forKey: launchCountKey)
        let newCount = currentCount + 1
        UserDefaults.standard.set(newCount, forKey: launchCountKey)
        
        let hasRequestedReview = UserDefaults.standard.bool(forKey: hasRequestedReviewKey)
        
        // Au 2ème lancement et si on n'a pas encore demandé de review
        if newCount == 2 && !hasRequestedReview {
            requestReview()
            UserDefaults.standard.set(true, forKey: hasRequestedReviewKey)
        }
    }
    
    /// Demande une notation via SKStoreReviewController
    private func requestReview() {
        // Petit délai pour laisser l'app se charger complètement
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            if let windowScene = UIApplication.shared.connectedScenes
                .first(where: { $0.activationState == .foregroundActive }) as? UIWindowScene {
                SKStoreReviewController.requestReview(in: windowScene)
            }
        }
    }
    
    /// Réinitialise le compteur (utile pour les tests)
    func resetLaunchCount() {
        UserDefaults.standard.set(0, forKey: launchCountKey)
        UserDefaults.standard.set(false, forKey: hasRequestedReviewKey)
    }
    
    /// Retourne le nombre actuel de lancements
    var launchCount: Int {
        UserDefaults.standard.integer(forKey: launchCountKey)
    }
}
