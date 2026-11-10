//
//  SubscriptionManager.swift
//  LessIsMore
//
//  Created by Angel Geoffroy on 03/09/2025.
//

import Foundation
import Combine
import SuperwallKit

class SubscriptionManager: ObservableObject {
    @Published var isPremium: Bool = false
    
    /// Notification posted when all filters are disabled due to subscription expiration
    static let filtersDisabledNotification = Notification.Name("SubscriptionManager.filtersDisabled")

    private var cancellables = Set<AnyCancellable>()

    init() {
        // Observer le statut d'abonnement de Superwall
        observeSubscriptionStatus()
    }

    #if DEBUG
    /// Debug-only override to test premium features without a purchase. Compiled out of release builds.
    private static let debugForcePremiumKey = "debug_forcePremium"

    var debugForcePremium: Bool {
        get { UserDefaults.standard.bool(forKey: Self.debugForcePremiumKey) }
        set {
            UserDefaults.standard.set(newValue, forKey: Self.debugForcePremiumKey)
            if newValue {
                isPremium = true
            } else if !Superwall.shared.subscriptionStatus.isActive {
                isPremium = false
                disableAllFiltersIfAnyEnabled()
            }
        }
    }
    #endif

    private func observeSubscriptionStatus() {
        Superwall.shared.$subscriptionStatus
            .sink { [weak self] status in
                guard let self = self else { return }

                #if DEBUG
                if self.debugForcePremium {
                    self.isPremium = true
                    return
                }
                #endif

                switch status {
                case .active:
                    self.isPremium = true
                case .inactive, .unknown:
                    self.isPremium = false
                    
                    // Si l'utilisateur n'est pas premium, désactiver tous les filtres actifs
                    // Cela s'applique au démarrage ET lors d'un changement de statut
                    self.disableAllFiltersIfAnyEnabled()
                @unknown default:
                    self.isPremium = false
                    self.disableAllFiltersIfAnyEnabled()
                }
            }
            .store(in: &cancellables)
    }
    
    /// Désactive tous les filtres premium et leurs streaks associés (si au moins un filtre est actif)
    private func disableAllFiltersIfAnyEnabled() {
        // Vérifier si au moins un filtre est activé
        let hasAnyFilterEnabled = FilterType.allCases.contains { $0.isEnabled }
        guard hasAnyFilterEnabled else { return }
        print("SubscriptionManager: Abonnement expiré - Désactivation de tous les filtres")
        
        // Désactiver chaque filtre
        for filterType in FilterType.allCases {
            if filterType.isEnabled {
                // Désactiver le filtre
                filterType.setEnabled(false)
                
                // Désactiver le streak associé
                StreakTracker.shared.deactivateStreak(for: filterType)
                
                print("SubscriptionManager: Filtre \(filterType.rawValue) désactivé")
            }
        }
        
        // Poster une notification pour informer les autres composants (notamment le WebView)
        NotificationCenter.default.post(
            name: SubscriptionManager.filtersDisabledNotification,
            object: nil
        )
        
        print("SubscriptionManager: Tous les filtres ont été désactivés")
    }

    func showPaywall() {
        // Présenter le paywall avec le placement configuré
        Superwall.shared.register(placement: "campaign_trigger")
    }
}
