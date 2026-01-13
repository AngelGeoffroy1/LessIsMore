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

    private var cancellables = Set<AnyCancellable>()

    init() {
        // Observer le statut d'abonnement de Superwall
        observeSubscriptionStatus()
    }

    private func observeSubscriptionStatus() {
        Superwall.shared.$subscriptionStatus
            .sink { [weak self] status in
                switch status {
                case .active:
                    if self?.isPremium == false {
                        // User just became premium
                        TelemetryManager.shared.trackSubscriptionStarted()
                    }
                    self?.isPremium = true
                case .inactive, .unknown:
                    if self?.isPremium == true {
                        // User lost premium status
                        TelemetryManager.shared.trackSubscriptionCancelled()
                    }
                    self?.isPremium = false
                @unknown default:
                    self?.isPremium = false
                }
            }
            .store(in: &cancellables)
    }

    func showPaywall() {
        // Présenter le paywall avec le placement configuré
        Superwall.shared.register(placement: "campaign_trigger")
    }
}
