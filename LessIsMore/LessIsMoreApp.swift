//
//  LessIsMoreApp.swift
//  LessIsMore
//
//  Created by Angel Geoffroy on 03/09/2025.
//

import SwiftUI
import AuthenticationServices
import SuperwallKit

@main
struct LessIsMoreApp: App {
    init() {
        // Configuration de Superwall au lancement de l'app
        Superwall.configure(apiKey: "pk_RyjdqJMj414PB37Pgr5GF")
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
