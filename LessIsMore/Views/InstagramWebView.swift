//
//  InstagramWebView.swift
//  LessIsMore
//
//  Created by Angel Geoffroy on 03/09/2025.
//

import SwiftUI
import WebKit

struct InstagramWebView: UIViewRepresentable {
    @ObservedObject var webViewManager: WebViewManager
    
    func makeUIView(context: Context) -> WKWebView {
        let webView = webViewManager.setupWebView()
        return webView
    }
    
    func updateUIView(_ uiView: WKWebView, context: Context) {
        // Pas de mise à jour nécessaire pour le moment
    }
}

struct InstagramWebViewContainer: View {
    @ObservedObject var webViewManager: WebViewManager
    @ObservedObject var authManager: AuthenticationManager
    @ObservedObject var subscriptionManager: SubscriptionManager
    @State private var showSettings = false
    @Environment(\.colorScheme) var colorScheme
    
    // Couleur adaptée au thème Instagram
    private var instagramHeaderColor: Color {
        colorScheme == .dark ? Color.black : Color.white
    }
    
    // Couleur des icônes adaptée au thème
    private var iconColor: Color {
        colorScheme == .dark ? Color.white : Color.black
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Barre de navigation personnalisée
                HStack {
                    Button(action: {
                        // Actualisation via JavaScript pour éviter la double actualisation
                        webViewManager.webView?.evaluateJavaScript("window.location.reload();", completionHandler: nil)
                    }) {
                        Image(systemName: "arrow.clockwise")
                            .foregroundColor(iconColor)
                            .frame(width: 44, height: 44)
                    }
                    .buttonStyle(PlainButtonStyle())
                    
                    Spacer()
                    
                    Text("LessIsMore")
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(iconColor.opacity(0.4))
                    
                    Spacer()
                    
                    Button(action: {
                        showSettings = true
                    }) {
                        Image(systemName: "gearshape.fill")
                            .foregroundColor(iconColor)
                            .frame(width: 44, height: 44)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
                .padding(.horizontal)
                .padding(.vertical, 8)
                .background(instagramHeaderColor)
                
                // Barre de progression
                if webViewManager.isLoading {
                    ProgressView()
                        .progressViewStyle(LinearProgressViewStyle())
                        .frame(height: 2)
                }
                
                // WebView Instagram
                InstagramWebView(webViewManager: webViewManager)
                    .onAppear {
                        webViewManager.loadInstagram()
                    }
            }
        }
        .navigationViewStyle(StackNavigationViewStyle())
        .navigationBarHidden(true)
        .sheet(isPresented: $showSettings) {
            SettingsView(webViewManager: webViewManager, authManager: authManager, subscriptionManager: subscriptionManager)
        }
    }
}

#Preview {
    InstagramWebViewContainer(webViewManager: WebViewManager(), authManager: AuthenticationManager(), subscriptionManager: SubscriptionManager())
}
