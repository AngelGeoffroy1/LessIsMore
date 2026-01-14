//
//  MixpanelManager.swift
//  LessIsMore
//
//  Created by Angel Geoffroy on 13/01/2026.
//

import Foundation
import Mixpanel

/// Centralized manager for Mixpanel analytics
class MixpanelManager {
    static let shared = MixpanelManager()
    
    private let token = "495caa297efd8ee2630b9f5af6a9d6d3"
    
    private init() {}
    
    /// Configure Mixpanel on app launch
    func configure() {
        #if DEBUG
        // Enable debug mode for development
        Mixpanel.initialize(token: token, trackAutomaticEvents: true, flushInterval: 5, serverURL: "https://api-eu.mixpanel.com")
        Mixpanel.mainInstance().loggingEnabled = true
        print("[Mixpanel] ✅ Configured in DEBUG mode (EU servers) with token: \(token)")
        #else
        Mixpanel.initialize(token: token, trackAutomaticEvents: true, serverURL: "https://api-eu.mixpanel.com")
        print("[Mixpanel] ✅ Configured for PRODUCTION (EU servers)")
        #endif
    }
    
    // MARK: - Core Events
    
    func trackAppLaunch() {
        track(event: "App Launched")
    }
    
    func trackSessionStart() {
        track(event: "Session Started")
    }
    
    // MARK: - Onboarding Events
    
    func trackOnboardingPage(_ page: Int, pageName: String) {
        track(event: "Onboarding Page Viewed", properties: [
            "page": page,
            "page_name": pageName
        ])
    }
    
    func trackOnboardingCompleted() {
        track(event: "Onboarding Completed")
    }
    
    // MARK: - Paywall Events
    
    func trackPaywallViewed(placement: String) {
        track(event: "Paywall Viewed", properties: [
            "placement": placement
        ])
    }
    
    func trackPaywallDismissed(placement: String) {
        track(event: "Paywall Dismissed", properties: [
            "placement": placement
        ])
    }
    
    func trackSubscriptionStarted(plan: String = "premium") {
        track(event: "Subscription Started", properties: [
            "plan": plan
        ])
        
        // Set user as premium
        Mixpanel.mainInstance().people.set(properties: ["is_premium": true])
    }
    
    func trackSubscriptionCancelled() {
        track(event: "Subscription Cancelled")
        Mixpanel.mainInstance().people.set(properties: ["is_premium": false])
    }
    
    // MARK: - Feature Events
    
    func trackLanguageChanged(from: String, to: String) {
        track(event: "Language Changed", properties: [
            "from": from,
            "to": to
        ])
        
        // Update user property
        Mixpanel.mainInstance().people.set(properties: ["language": to])
    }
    
    func trackFilterToggled(filterType: String, enabled: Bool) {
        track(event: "Filter Toggled", properties: [
            "filter_type": filterType,
            "enabled": enabled
        ])
    }
    
    func trackShareStats() {
        track(event: "Stats Shared")
    }
    
    func trackStreakMilestone(days: Int, type: String) {
        track(event: "Streak Milestone", properties: [
            "days": days,
            "type": type
        ])
    }
    
    func trackSettingsOpened() {
        track(event: "Settings Opened")
    }
    
    func trackContactSupport() {
        track(event: "Contact Support Opened")
    }
    
    func trackAboutViewed() {
        track(event: "About Viewed")
    }
    
    // MARK: - Notification Events
    
    func trackNotificationPermission(granted: Bool) {
        track(event: "Notification Permission", properties: [
            "granted": granted
        ])
    }
    
    func trackNotificationTapped(notificationId: String) {
        track(event: "Notification Tapped", properties: [
            "notification_id": notificationId
        ])
    }
    
    // MARK: - Helper Methods
    
    private func track(event: String, properties: [String: MixpanelType]? = nil) {
        Mixpanel.mainInstance().track(event: event, properties: properties)
        
        #if DEBUG
        // Force flush in debug to see events immediately
        Mixpanel.mainInstance().flush()
        print("[Mixpanel] 📊 \(event)")
        if let props = properties {
            print("[Mixpanel]    Properties: \(props)")
        }
        #endif
    }
}
