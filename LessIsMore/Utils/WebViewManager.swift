//
//  WebViewManager.swift
//  LessIsMore
//
//  Created by Angel Geoffroy on 03/09/2025.
//

import Foundation
import WebKit
import SwiftUI

// MARK: - Modèle d'erreur WebView
struct WebViewError: Identifiable {
    let id = UUID()
    let title: String
    let message: String
    let isRecoverable: Bool

    static func navigation(_ error: Error) -> WebViewError {
        WebViewError(
            title: "Erreur de navigation",
            message: error.localizedDescription,
            isRecoverable: true
        )
    }

    static func javascript(_ error: Error) -> WebViewError {
        WebViewError(
            title: "Erreur de script",
            message: "Impossible d'appliquer les filtres: \(error.localizedDescription)",
            isRecoverable: true
        )
    }

    static func network() -> WebViewError {
        WebViewError(
            title: "Pas de connexion",
            message: "Vérifiez votre connexion internet et réessayez.",
            isRecoverable: true
        )
    }

    static func loadFailed() -> WebViewError {
        WebViewError(
            title: "Chargement impossible",
            message: "Instagram n'a pas pu être chargé. Réessayez plus tard.",
            isRecoverable: true
        )
    }
}

class WebViewManager: NSObject, ObservableObject {
    @Published var isLoading = false
    @Published var canGoBack = false
    @Published var canGoForward = false
    @Published var url: String = ""
    @Published var currentError: WebViewError?
    @Published var showError = false

    weak var webView: WKWebView?

    /// Flag pour éviter les chargements multiples
    private var hasInitiallyLoaded = false

    /// Flag pour éviter les doubles injections lors des redirections
    private var hasInjectedFilters = false

    /// URL de la dernière navigation pour détecter les vraies navigations vs redirections
    private var lastNavigationURL: String?

    override init() {
        super.init()
        
        // Observer la désactivation des filtres lors de l'expiration de l'abonnement
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleFiltersDisabled),
            name: SubscriptionManager.filtersDisabledNotification,
            object: nil
        )
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    /// Appelé quand tous les filtres sont désactivés suite à l'expiration de l'abonnement
    @objc private func handleFiltersDisabled() {
        print("WebViewManager: Réception de la notification - Réapplication des filtres désactivés")
        
        // Réappliquer tous les filtres (maintenant tous désactivés) dans le WebView
        DispatchQueue.main.async { [weak self] in
            self?.applyAllSavedFilters()
        }
    }

    // MARK: - Gestion des erreurs
    private func handleError(_ error: WebViewError) {
        DispatchQueue.main.async {
            self.currentError = error
            self.showError = true
        }
    }

    func dismissError() {
        showError = false
        currentError = nil
    }

    func retryAfterError() {
        dismissError()
        loadInstagram(force: true)
    }
    
    func setupWebView() -> WKWebView {
        // Retourner la WebView existante si elle existe déjà (évite les recréations par SwiftUI)
        if let existingWebView = webView {
            return existingWebView
        }

        let configuration = WKWebViewConfiguration()

        // Configuration pour permettre l'injection de JavaScript
        let userContentController = WKUserContentController()
        userContentController.add(self, name: "lessIsMoreTracker")
        configuration.userContentController = userContentController

        // Injection du script dès le début du chargement (plus rapide)
        let contentBlockerScript = WKUserScript(
            source: ContentBlocker.getBlockingScript(),
            injectionTime: .atDocumentStart,
            forMainFrameOnly: false
        )
        userContentController.addUserScript(contentBlockerScript)

        // Permettre la lecture des médias
        configuration.allowsInlineMediaPlayback = true
        configuration.mediaTypesRequiringUserActionForPlayback = []

        let newWebView = WKWebView(frame: .zero, configuration: configuration)
        newWebView.navigationDelegate = self
        newWebView.uiDelegate = self
        newWebView.allowsBackForwardNavigationGestures = true

        // Force mobile User-Agent on iPad to prevent Instagram desktop login loop
        newWebView.customUserAgent = "Mozilla/5.0 (iPhone; CPU iPhone OS 17_0 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.0 Mobile/15E148 Safari/604.1"

        // Masquer les indicateurs de scroll natifs
        newWebView.scrollView.showsVerticalScrollIndicator = false
        newWebView.scrollView.showsHorizontalScrollIndicator = false

        self.webView = newWebView
        return newWebView
    }
    
    func loadInstagram(force: Bool = false) {
        guard let webView = webView else { return }

        // Éviter les chargements multiples lors du lancement
        if hasInitiallyLoaded && !force {
            return
        }
        hasInitiallyLoaded = true

        // Vérifier si le filtre Following est activé
        let followingFilterEnabled = FilterType.following.isEnabled

        // Toujours spécifier le variant pour éviter la redirection automatique d'Instagram
        // Instagram redirige instagram.com vers instagram.com/?variant=foryou, ce qui cause un double chargement
        let urlString = followingFilterEnabled ?
            "https://www.instagram.com/?variant=following" :
            "https://www.instagram.com/?variant=foryou"

        if let url = URL(string: urlString) {
            let request = URLRequest(url: url)
            webView.load(request)
        }
    }
    
    func injectContentBlocker() {
        guard let webView = webView else { return }

        // Vérifier d'abord si le script est déjà injecté
        let checkScript = """
        if (typeof window.lessIsMoreToggleFilter === 'function') {
            'already_injected';
        } else {
            'needs_injection';
        }
        """

        webView.evaluateJavaScript(checkScript) { [weak self] result, error in
            guard let self = self else { return }

            if let error = error {
                print("Erreur vérification script: \(error.localizedDescription)")
                // Continuer malgré l'erreur - tenter l'injection
            }

            if let resultString = result as? String, resultString == "already_injected" {
                print("Script déjà injecté, application directe des filtres")
                self.applyAllSavedFilters()
            } else {
                // Injection nécessaire
                let contentBlockerScript = ContentBlocker.getBlockingScript()
                webView.evaluateJavaScript(contentBlockerScript) { [weak self] result, error in
                    guard let self = self else { return }

                    if let error = error {
                        print("Erreur injection JavaScript: \(error.localizedDescription)")
                        self.handleError(.javascript(error))
                    } else {
                        print("Script de blocage injecté avec succès")
                        // Application immédiate après injection
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                            self.applyAllSavedFilters()
                        }
                    }
                }
            }
        }
    }
    
    func toggleFilter(_ filterType: FilterType) {
        guard let webView = webView else { return }

        let script = ContentBlocker.getToggleScript(for: filterType)
        webView.evaluateJavaScript(script) { [weak self] result, error in
            if let error = error {
                print("Erreur toggle filter: \(error.localizedDescription)")
                self?.handleError(.javascript(error))
            }
        }
    }

    func applyAllSavedFilters() {
        guard let webView = webView else { return }

        let script = ContentBlocker.getApplyAllFiltersScript()
        webView.evaluateJavaScript(script) { [weak self] _, error in
            if let error = error {
                print("Erreur application des filtres: \(error.localizedDescription)")
            } else {
                print("Tous les filtres appliqués avec succès")
                // Appliquer le thème après les filtres
                self?.applyCurrentTheme()
            }
        }
    }
    
    func reapplyFiltersIfNeeded() {
        guard let webView = webView else { return }

        // Vérifier si les fonctions JavaScript sont toujours disponibles
        let checkScript = """
        if (typeof window.lessIsMoreApplyAllFilters === 'function') {
            'functions_available';
        } else {
            'functions_missing';
        }
        """

        webView.evaluateJavaScript(checkScript) { [weak self] result, error in
            guard let self = self else { return }

            if let resultString = result as? String {
                if resultString == "functions_missing" {
                    print("Fonctions JavaScript manquantes, réinjection nécessaire")
                    self.injectContentBlocker()
                } else {
                    print("Réapplication des filtres par sécurité")
                    self.applyAllSavedFilters()
                }
            }
        }
    }
    
    // MARK: - Theme Application
    
    func applyTheme(_ theme: InstagramTheme) {
        guard let webView = webView else { return }
        
        let script = ContentBlocker.getApplyThemeScript(theme: theme)
        webView.evaluateJavaScript(script) { _, error in
            if let error = error {
                print("Erreur application du thème: \(error.localizedDescription)")
            } else {
                print("Thème '\(theme.rawValue)' appliqué avec succès")
            }
        }
    }
    
    func applyCurrentTheme() {
        let currentTheme = InstagramTheme.current
        if currentTheme != .default {
            applyTheme(currentTheme)
        }
    }
}

// MARK: - WKNavigationDelegate
extension WebViewManager: WKNavigationDelegate {
    func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
        isLoading = true
        let currentURL = webView.url?.absoluteString ?? ""
        url = currentURL

        // Détecter si c'est une nouvelle navigation (pas une redirection)
        let isNewNavigation = lastNavigationURL == nil ||
            !currentURL.hasPrefix("https://www.instagram.com") ||
            currentURL.contains("/p/") ||
            currentURL.contains("/reels/") ||
            currentURL.contains("/stories/") ||
            currentURL.contains("/accounts/")  // Login/onetap nécessite une réinjection

        if isNewNavigation {
            // Réinitialiser le flag pour les nouvelles navigations
            hasInjectedFilters = false
        }

        lastNavigationURL = currentURL
        print("WebViewManager: didStart - URL: \(currentURL), isNewNavigation: \(isNewNavigation)")
    }

    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        isLoading = false
        canGoBack = webView.canGoBack
        canGoForward = webView.canGoForward
        let currentURL = webView.url?.absoluteString ?? ""
        url = currentURL

        print("WebViewManager: didFinish - URL: \(currentURL), hasInjectedFilters: \(hasInjectedFilters)")

        // Vérifier si les fonctions JavaScript sont disponibles avant de skip
        if hasInjectedFilters {
            let checkScript = """
            if (typeof window.lessIsMoreApplyAllFilters === 'function') {
                'functions_available';
            } else {
                'functions_missing';
            }
            """

            webView.evaluateJavaScript(checkScript) { [weak self] result, error in
                guard let self = self else { return }

                if let resultString = result as? String, resultString == "functions_available" {
                    print("WebViewManager: Filtres déjà injectés et fonctionnels, skip")
                } else {
                    print("WebViewManager: Filtres marqués comme injectés mais fonctions manquantes, réinjection")
                    self.injectContentBlocker()
                }
            }
            return
        }

        hasInjectedFilters = true

        // Skip content blocker injection on login/account pages to prevent login loop on iPad
        if currentURL.contains("/accounts/") || currentURL.contains("/login") || currentURL.contains("/challenge/") {
            print("WebViewManager: Page de login/compte détectée, skip injection des filtres")
            return
        }

        // Injection intelligente du script (applique déjà les filtres)
        self.injectContentBlocker()
    }
    
    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        isLoading = false
        print("Erreur de navigation: \(error.localizedDescription)")

        // Ignorer les erreurs d'annulation (utilisateur a navigué ailleurs)
        let nsError = error as NSError
        if nsError.code == NSURLErrorCancelled {
            return
        }

        // Vérifier si c'est une erreur réseau
        if nsError.code == NSURLErrorNotConnectedToInternet ||
           nsError.code == NSURLErrorNetworkConnectionLost {
            handleError(.network())
        } else {
            handleError(.navigation(error))
        }
    }

    func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
        isLoading = false
        print("Erreur de chargement initial: \(error.localizedDescription)")

        let nsError = error as NSError
        if nsError.code == NSURLErrorCancelled {
            return
        }

        if nsError.code == NSURLErrorNotConnectedToInternet ||
           nsError.code == NSURLErrorNetworkConnectionLost {
            handleError(.network())
        } else {
            handleError(.loadFailed())
        }
    }
}

// MARK: - WKScriptMessageHandler
extension WebViewManager: WKScriptMessageHandler {
    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        if message.name == "lessIsMoreTracker", let categoryName = message.body as? String {
            if let category = UsageTracker.UsageCategory(rawValue: categoryName) {
                print("Usage Tracker: Switched to category \(category)")
                UsageTracker.shared.currentCategory = category
            }
        }
    }
}

// MARK: - WKUIDelegate
extension WebViewManager: WKUIDelegate {
    func webView(_ webView: WKWebView, createWebViewWith configuration: WKWebViewConfiguration, for navigationAction: WKNavigationAction, windowFeatures: WKWindowFeatures) -> WKWebView? {
        // Ouvrir les nouveaux liens dans la même webview
        if let url = navigationAction.request.url {
            webView.load(URLRequest(url: url))
        }
        return nil
    }
}
