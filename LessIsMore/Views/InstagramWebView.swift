//
//  InstagramWebView.swift
//  LessIsMore
//
//  Created by Angel Geoffroy on 03/09/2025.
//

import SwiftUI
import WebKit

// MARK: - Swipe Tutorial Overlay

struct SwipeTutorialOverlay: View {
    @Binding var isVisible: Bool
    @State private var handOffset: CGFloat = 0
    @State private var handOpacity: Double = 1
    @Environment(\.colorScheme) var colorScheme

    var body: some View {
        ZStack {
            // Fond semi-transparent
            Color.black.opacity(0.5)
                .ignoresSafeArea()

            VStack(spacing: 24) {
                // Zone d'animation de la main
                VStack(spacing: 16) {
                    // Indicateur de la zone de swipe (replica du header)
                    Capsule()
                        .fill(Color.white.opacity(0.4))
                        .frame(width: 36, height: 4)

                    // Main animée
                    Image(systemName: "hand.point.up.fill")
                        .font(.system(size: 44))
                        .foregroundColor(.white)
                        .offset(y: handOffset)
                        .opacity(handOpacity)
                }
                .padding(.top, 40)

                // Texte explicatif
                VStack(spacing: 8) {
                    Text("Swipe down to open controls")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.white)

                    Text("Access filters and settings")
                        .font(.system(size: 14))
                        .foregroundColor(.white.opacity(0.7))
                }
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)

                Spacer()

                // Bouton pour fermer
                Button(action: dismissTutorial) {
                    Text("Got it!")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.black)
                        .padding(.horizontal, 32)
                        .padding(.vertical, 14)
                        .background(Color.white)
                        .clipShape(Capsule())
                }
                .padding(.bottom, 60)
            }
        }
        .onAppear {
            startAnimation()
        }
        .onTapGesture {
            dismissTutorial()
        }
    }

    private func startAnimation() {
        // Animation continue de la main qui swipe vers le bas
        withAnimation(
            Animation.easeInOut(duration: 1.0)
                .repeatForever(autoreverses: true)
        ) {
            handOffset = 30
        }
    }

    private func dismissTutorial() {
        let impactFeedback = UIImpactFeedbackGenerator(style: .light)
        impactFeedback.impactOccurred()

        withAnimation(.easeOut(duration: 0.3)) {
            isVisible = false
        }

        // Sauvegarder que l'utilisateur a vu le tutoriel
        PersistenceService.shared.hasSeenSwipeTutorial = true
    }
}

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
    @State private var showSwipeTutorial = false
    @Environment(\.colorScheme) var colorScheme

    var body: some View {
        ZStack {
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

            // Overlay de tutoriel pour le premier lancement
            if showSwipeTutorial {
                SwipeTutorialOverlay(isVisible: $showSwipeTutorial)
                    .transition(.opacity)
                    .zIndex(100)
            }
        }
        .onAppear {
            // Afficher le tutoriel seulement si l'utilisateur ne l'a jamais vu
            if !PersistenceService.shared.hasSeenSwipeTutorial {
                // Petit délai pour laisser le temps au feed de charger
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                    withAnimation(.easeIn(duration: 0.3)) {
                        showSwipeTutorial = true
                    }
                }
            }
        }
        .onChange(of: showControlPanel) { _, isOpen in
            // Si l'utilisateur ouvre le control panel, masquer le tutoriel
            if isOpen && showSwipeTutorial {
                showSwipeTutorial = false
                PersistenceService.shared.hasSeenSwipeTutorial = true
            }
        }
        .background(colorScheme == .dark ? Color(red: 11/255, green: 16/255, blue: 20/255) : Color.white)
        .ignoresSafeArea(edges: .bottom)
        .sheet(isPresented: $showControlPanel) {
            ControlPanelView(
                webViewManager: webViewManager,
                authManager: authManager,
                subscriptionManager: subscriptionManager
            )
            .presentationDetents([.medium, .large])
            .presentationDragIndicator(.hidden)
            .presentationBackground(.clear)
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
