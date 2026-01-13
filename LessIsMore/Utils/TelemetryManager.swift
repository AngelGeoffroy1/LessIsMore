//
//  TelemetryManager.swift
//  LessIsMore
//
//  Created by Angel Geoffroy on 13/01/2026.
//

import Foundation
import TelemetryDeck

/// Centralized manager for TelemetryDeck analytics
/// Privacy-first analytics tracking for user behavior and app usage
class TelemetryManager {
    static let shared = TelemetryManager()
    
    private let appID = "C53B89DD-7963-48AE-9AF6-A0FA85769184"
    
    private init() {}
    
    /// Configure TelemetryDeck on app launch
    func configure() {
        let configuration = TelemetryDeck.Config(appID: appID)
        TelemetryDeck.initialize(config: configuration)
        
        #if DEBUG
        print("[TelemetryDeck] Configured with App ID: \(appID)")
        #endif
    }
    
    // MARK: - Core Events
    
    /// Track app launch
    func trackAppLaunch() {
        signal("app.launched")
    }
    
    /// Track screen view
    func trackScreenView(_ screenName: String) {
        signal("screen.viewed", parameters: ["screen_name": screenName])
    }
    
    // MARK: - Onboarding Events
    
    /// Track onboarding page view
    func trackOnboardingPage(_ page: Int, pageName: String) {
        signal("onboarding.page_viewed", parameters: [
            "page": String(page),
            "page_name": pageName
        ])
    }
    
    /// Track onboarding completion
    func trackOnboardingCompleted() {
        signal("onboarding.completed")
    }
    
    /// Track onboarding skip
    func trackOnboardingSkipped(atPage: Int) {
        signal("onboarding.skipped", parameters: [
            "page": String(atPage)
        ])
    }
    
    // MARK: - Paywall & Conversion Events
    
    /// Track paywall impression
    func trackPaywallImpression(placement: String) {
        signal("paywall.impression", parameters: [
            "placement": placement
        ])
    }
    
    /// Track paywall dismissed
    func trackPaywallDismissed(placement: String) {
        signal("paywall.dismissed", parameters: [
            "placement": placement
        ])
    }
    
    /// Track subscription started
    func trackSubscriptionStarted(plan: String = "premium") {
        signal("subscription.started", parameters: [
            "plan": plan
        ])
    }
    
    /// Track subscription cancelled
    func trackSubscriptionCancelled() {
        signal("subscription.cancelled")
    }
    
    // MARK: - Feature Usage Events
    
    /// Track language change
    func trackLanguageChanged(from: String, to: String) {
        signal("settings.language_changed", parameters: [
            "from": from,
            "to": to
        ])
    }
    
    /// Track filter toggle
    func trackFilterToggled(filterType: String, enabled: Bool) {
        signal("filter.toggled", parameters: [
            "filter_type": filterType,
            "enabled": String(enabled)
        ])
    }
    
    /// Track share action
    func trackShareStats() {
        signal("share.stats")
    }
    
    /// Track streak milestone
    func trackStreakMilestone(days: Int, type: String) {
        signal("streak.milestone", parameters: [
            "days": String(days),
            "type": type
        ])
    }
    
    /// Track settings opened
    func trackSettingsOpened() {
        signal("settings.opened")
    }
    
    /// Track contact support
    func trackContactSupport() {
        signal("support.contact_opened")
    }
    
    /// Track about page viewed
    func trackAboutViewed() {
        signal("about.viewed")
    }
    
    // MARK: - User Engagement Events
    
    /// Track session start
    func trackSessionStart() {
        signal("session.started")
    }
    
    /// Track feature used with custom metadata
    func trackFeatureUsed(_ featureName: String, metadata: [String: String] = [:]) {
        signal("feature.used", parameters: ["feature_name": featureName].merging(metadata) { _, new in new })
    }
    
    // MARK: - Helper Methods
    
    /// Send a signal to TelemetryDeck
    private func signal(_ eventName: String, parameters: [String: String] = [:]) {
        TelemetryDeck.signal(eventName, parameters: parameters)
        
        #if DEBUG
        print("[TelemetryDeck] 📊 Event: \(eventName)")
        if !parameters.isEmpty {
            print("[TelemetryDeck]    Parameters: \(parameters)")
        }
        #endif
    }
}
