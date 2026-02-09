//
//  LessIsMoreApp.swift
//  LessIsMore
//
//  Created by Angel Geoffroy on 03/09/2025.
//

import SwiftUI
import AuthenticationServices
import SuperwallKit
import StoreKit

@main
struct LessIsMoreApp: App {
    init() {
        // Configuration de Mixpanel
        MixpanelManager.shared.configure()
        MixpanelManager.shared.trackAppLaunch()
        
        // Demande de notation au 2ème lancement
        AppRatingManager.shared.incrementLaunchCountAndRequestReviewIfNeeded()
        
        // Configuration de Superwall avec la clé depuis Info.plist
        if let apiKey = Bundle.main.object(forInfoDictionaryKey: "SUPERWALL_API_KEY") as? String {
            Superwall.configure(apiKey: apiKey)
        } else {
            #if DEBUG
            fatalError("SUPERWALL_API_KEY manquante dans Info.plist")
            #endif
        }
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .preferredColorScheme(.dark)
        }
    }
}
