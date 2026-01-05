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
    @State private var showControlPanel = false
    @Environment(\.colorScheme) var colorScheme

    var body: some View {
        VStack(spacing: 0) {
            // Header avec indicateur pour ouvrir le panneau
            HeaderSwipeZone(showControlPanel: $showControlPanel)

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
        .background(colorScheme == .dark ? Color(red: 11/255, green: 16/255, blue: 20/255) : Color.white)
        .ignoresSafeArea(edges: .bottom)
        .sheet(isPresented: $showControlPanel) {
            ControlPanelView(
                webViewManager: webViewManager,
                subscriptionManager: subscriptionManager
            )
            .presentationDetents([.medium, .large])
            .presentationDragIndicator(.hidden)
            .presentationBackground(.thinMaterial)
        }
        .alert(
            webViewManager.currentError?.title ?? "Erreur",
            isPresented: $webViewManager.showError,
            presenting: webViewManager.currentError
        ) { error in
            if error.isRecoverable {
                Button("Réessayer") {
                    webViewManager.retryAfterError()
                }
                Button("Annuler", role: .cancel) {
                    webViewManager.dismissError()
                }
            } else {
                Button("OK", role: .cancel) {
                    webViewManager.dismissError()
                }
            }
        } message: { error in
            Text(error.message)
        }
    }
}

// MARK: - Header Swipe Zone

struct HeaderSwipeZone: View {
    @Binding var showControlPanel: Bool
    @Environment(\.colorScheme) var colorScheme

    // Couleur exacte du background Instagram dark mode (#0b1014)
    private let instagramDarkBg = Color(red: 11/255, green: 16/255, blue: 20/255)

    var body: some View {
        // Zone en haut avec indicateur
        VStack {
            Spacer()

            Capsule()
                .fill(colorScheme == .dark ? Color.white.opacity(0.25) : Color.black.opacity(0.15))
                .frame(width: 36, height: 4)
                .padding(.bottom, 6)
        }
        .frame(maxWidth: .infinity)
        .frame(height: 28)
        .background(colorScheme == .dark ? instagramDarkBg : Color.white)
        .contentShape(Rectangle())
        .onTapGesture {
            openPanel()
        }
        .gesture(
            DragGesture()
                .onEnded { value in
                    if value.translation.height > 30 {
                        openPanel()
                    }
                }
        )
    }

    private func openPanel() {
        let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
        impactFeedback.impactOccurred()
        showControlPanel = true
    }
}

#Preview {
    InstagramWebViewContainer(
        webViewManager: WebViewManager(),
        authManager: AuthenticationManager(),
        subscriptionManager: SubscriptionManager()
    )
}
