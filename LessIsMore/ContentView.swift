//
//  ContentView.swift
//  LessIsMore
//
//  Created by Angel Geoffroy on 03/09/2025.
//

import SwiftUI
import SuperwallKit
import WidgetKit

struct ContentView: View {
    @StateObject private var authManager = AuthenticationManager()
    @StateObject private var webViewManager = WebViewManager()
    @StateObject private var subscriptionManager = SubscriptionManager()
    @State private var hasShownPaywall = false
    @Environment(\.scenePhase) private var scenePhase

    var body: some View {
        Group {
            if authManager.hasSeenOnboarding {
                // Utilisateur ayant complété l'onboarding - aller à Instagram
                InstagramWebViewContainer(
                    webViewManager: webViewManager,
                    authManager: authManager,
                    subscriptionManager: subscriptionManager
                )
                .onAppear {
                    // Présenter le paywall uniquement la première fois après l'onboarding
                    if !hasShownPaywall {
                        subscriptionManager.showPaywall()
                        hasShownPaywall = true
                    }
                }
            } else {
                // Nouvel utilisateur - afficher l'onboarding
                OnboardingView(authManager: authManager)
            }
        }
        .onChange(of: scenePhase) { _, newPhase in
            if newPhase == .active {
                // Sync data to widgets when app becomes active
                syncWidgetData()
            }
        }
        .onAppear {
            // Initial sync
            syncWidgetData()
        }
    }
    
    /// Syncs all relevant data to widgets
    private func syncWidgetData() {
        UsageTracker.shared.forceSyncToWidget()
        StreakTracker.shared.forceSyncToWidget()
    }
}

#Preview {
    ContentView()
}
