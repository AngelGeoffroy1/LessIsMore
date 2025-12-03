//
//  ContentView.swift
//  LessIsMore
//
//  Created by Angel Geoffroy on 03/09/2025.
//

import SwiftUI
import SuperwallKit

struct ContentView: View {
    @StateObject private var authManager = AuthenticationManager()
    @StateObject private var webViewManager = WebViewManager()
    @StateObject private var subscriptionManager = SubscriptionManager()
    @State private var hasShownPaywall = false

    var body: some View {
        if authManager.isAuthenticated {
            if authManager.hasSeenOnboarding {
                // Utilisateur authentifié et ayant vu l'onboarding - aller à Instagram
                InstagramWebViewContainer(
                    webViewManager: webViewManager,
                    authManager: authManager,
                    subscriptionManager: subscriptionManager
                )
                .onAppear {
                    // Présenter le paywall uniquement la première fois après l'authentification
                    if !hasShownPaywall {
                        subscriptionManager.showPaywall()
                        hasShownPaywall = true
                    }
                }
            } else {
                // Utilisateur authentifié mais pas encore l'onboarding
                OnboardingView(authManager: authManager)
            }
        } else {
            // Utilisateur non authentifié - afficher l'écran de connexion
            AuthenticationView(authManager: authManager)
        }
    }
}

#Preview {
    ContentView()
}
