//
//  WebViewManager.swift
//  LessIsMore
//
//  Created by Angel Geoffroy on 03/09/2025.
//

import Foundation
import WebKit
import SwiftUI

class WebViewManager: NSObject, ObservableObject {
    @Published var isLoading = false
    @Published var canGoBack = false
    @Published var canGoForward = false
    @Published var url: String = ""
    
    weak var webView: WKWebView?
    
    override init() {
        super.init()
    }
    
    func setupWebView() -> WKWebView {
        let configuration = WKWebViewConfiguration()
        
        // Configuration pour permettre l'injection de JavaScript
        let userContentController = WKUserContentController()
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
        
        let webView = WKWebView(frame: .zero, configuration: configuration)
        webView.navigationDelegate = self
        webView.uiDelegate = self
        webView.allowsBackForwardNavigationGestures = true
        
        self.webView = webView
        return webView
    }
    
    func loadInstagram() {
        guard let webView = webView else { return }
        
        // Vérifier si le filtre Following est activé
        let followingFilterEnabled = FilterType.following.isEnabled
        
        let urlString = followingFilterEnabled ? 
            "https://www.instagram.com/?variant=following" : 
            "https://www.instagram.com"
        
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
        
        webView.evaluateJavaScript(checkScript) { result, error in
            if let resultString = result as? String, resultString == "already_injected" {
                print("Script déjà injecté, application directe des filtres")
                self.applyAllSavedFilters()
            } else {
                // Injection nécessaire
                let contentBlockerScript = ContentBlocker.getBlockingScript()
                webView.evaluateJavaScript(contentBlockerScript) { result, error in
                    if let error = error {
                        print("Erreur injection JavaScript: \(error.localizedDescription)")
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
        webView.evaluateJavaScript(script) { result, error in
            if let error = error {
                print("Erreur toggle filter: \(error.localizedDescription)")
            }
        }
    }
    
    func applyAllSavedFilters() {
        guard let webView = webView else { return }
        
        let script = ContentBlocker.getApplyAllFiltersScript()
        webView.evaluateJavaScript(script) { result, error in
            if let error = error {
                print("Erreur application des filtres: \(error.localizedDescription)")
            } else {
                print("Tous les filtres appliqués avec succès")
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
        
        webView.evaluateJavaScript(checkScript) { result, error in
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
}

// MARK: - WKNavigationDelegate
extension WebViewManager: WKNavigationDelegate {
    func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
        isLoading = true
        url = webView.url?.absoluteString ?? ""
    }
    
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        isLoading = false
        canGoBack = webView.canGoBack
        canGoForward = webView.canGoForward
        url = webView.url?.absoluteString ?? ""
        
        // Injection intelligente du script
        self.injectContentBlocker()
        
        // Vérification rapide en parallèle
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            self.reapplyFiltersIfNeeded()
        }
    }
    
    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        isLoading = false
        print("Erreur de navigation: \(error.localizedDescription)")
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
