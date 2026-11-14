//
//  NotificationManager.swift
//  LessIsMore
//
//  Created on 14/01/2026.
//

import Foundation
import UserNotifications
import SwiftUI

/// Manages local push notifications for wellness reminders
class NotificationManager: NSObject, ObservableObject {
    static let shared = NotificationManager()
    
    @Published var isAuthorized = false
    @Published var authorizationStatus: UNAuthorizationStatus = .notDetermined
    
    // MARK: - Notification Identifiers
    private enum NotificationID {
        static let eveningDisconnect = "com.lessismore.evening.disconnect"
        static let weekendDetox = "com.lessismore.weekend.detox"
        static let nightReminder = "com.lessismore.night.reminder"
    }
    
    // MARK: - User Defaults Keys
    private enum SettingsKey {
        static let eveningNotificationEnabled = "notification.evening.enabled"
        static let weekendNotificationEnabled = "notification.weekend.enabled"
        static let nightNotificationEnabled = "notification.night.enabled"
        static let notificationsConfigured = "notifications.configured"
    }
    
    // MARK: - Published Settings
    @Published var eveningNotificationEnabled: Bool {
        didSet {
            UserDefaults.standard.set(eveningNotificationEnabled, forKey: SettingsKey.eveningNotificationEnabled)
            updateScheduledNotifications()
        }
    }
    
    @Published var weekendNotificationEnabled: Bool {
        didSet {
            UserDefaults.standard.set(weekendNotificationEnabled, forKey: SettingsKey.weekendNotificationEnabled)
            updateScheduledNotifications()
        }
    }
    
    @Published var nightNotificationEnabled: Bool {
        didSet {
            UserDefaults.standard.set(nightNotificationEnabled, forKey: SettingsKey.nightNotificationEnabled)
            updateScheduledNotifications()
        }
    }
    
    private override init() {
        // Load saved settings
        self.eveningNotificationEnabled = UserDefaults.standard.bool(forKey: SettingsKey.eveningNotificationEnabled)
        self.weekendNotificationEnabled = UserDefaults.standard.bool(forKey: SettingsKey.weekendNotificationEnabled)
        self.nightNotificationEnabled = UserDefaults.standard.bool(forKey: SettingsKey.nightNotificationEnabled)
        
        super.init()
        
        // Set delegate
        UNUserNotificationCenter.current().delegate = self
        
        // Check current authorization status
        checkAuthorizationStatus()
    }
    
    // MARK: - Authorization
    
    /// Check current notification authorization status
    func checkAuthorizationStatus() {
        UNUserNotificationCenter.current().getNotificationSettings { [weak self] settings in
            DispatchQueue.main.async {
                self?.authorizationStatus = settings.authorizationStatus
                self?.isAuthorized = settings.authorizationStatus == .authorized
            }
        }
    }
    
    /// Request notification authorization
    func requestAuthorization(completion: @escaping (Bool) -> Void) {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { [weak self] granted, error in
            DispatchQueue.main.async {
                self?.isAuthorized = granted
                self?.authorizationStatus = granted ? .authorized : .denied
                
                if granted {
                    // Enable all notifications by default on first authorization
                    if !UserDefaults.standard.bool(forKey: SettingsKey.notificationsConfigured) {
                        self?.eveningNotificationEnabled = true
                        self?.weekendNotificationEnabled = true
                        self?.nightNotificationEnabled = true
                        UserDefaults.standard.set(true, forKey: SettingsKey.notificationsConfigured)
                    }
                    self?.scheduleAllNotifications()
                }
                
                completion(granted)
                
                if let error = error {
                    print("❌ Notification authorization error: \(error.localizedDescription)")
                }
            }
        }
    }
    
    // MARK: - Scheduling
    
    /// Schedule all enabled notifications
    func scheduleAllNotifications() {
        guard isAuthorized else { return }
        
        // Cancel all existing notifications first
        cancelAllNotifications()
        
        if eveningNotificationEnabled {
            scheduleEveningDisconnectNotification()
        }
        
        if weekendNotificationEnabled {
            scheduleWeekendDetoxNotification()
        }
        
        if nightNotificationEnabled {
            scheduleNightReminderNotification()
        }
        
        print("✅ Notifications scheduled")
    }
    
    /// Update scheduled notifications based on current settings
    private func updateScheduledNotifications() {
        guard isAuthorized else { return }
        scheduleAllNotifications()
    }
    
    /// Cancel all scheduled notifications
    func cancelAllNotifications() {
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
    }
    
    // MARK: - Evening Disconnect Notification (21h daily)
    
    /// 🌙 "Il est 21h. Pensez à activer le mode 'Following Only' pour une soirée plus calme"
    private func scheduleEveningDisconnectNotification() {
        let content = UNMutableNotificationContent()
        content.title = "notification.evening.title".localized
        content.body = "notification.evening.body".localized
        content.sound = .default
        content.categoryIdentifier = "WELLNESS_REMINDER"
        
        // Schedule for 21:00 every day
        var dateComponents = DateComponents()
        dateComponents.hour = 21
        dateComponents.minute = 0
        
        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
        let request = UNNotificationRequest(identifier: NotificationID.eveningDisconnect, content: content, trigger: trigger)
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("❌ Failed to schedule evening notification: \(error.localizedDescription)")
            }
        }
    }
    
    // MARK: - Weekend Detox Notification (Saturday & Sunday at 10h)
    
    /// ☀️ "C'est le week-end ! Bloquez les Reels et profitez du monde réel"
    private func scheduleWeekendDetoxNotification() {
        let content = UNMutableNotificationContent()
        content.title = "notification.weekend.title".localized
        content.body = "notification.weekend.body".localized
        content.sound = .default
        content.categoryIdentifier = "WELLNESS_REMINDER"
        
        // Schedule for Saturday at 10:00
        var saturdayComponents = DateComponents()
        saturdayComponents.weekday = 7 // Saturday
        saturdayComponents.hour = 10
        saturdayComponents.minute = 0
        
        let saturdayTrigger = UNCalendarNotificationTrigger(dateMatching: saturdayComponents, repeats: true)
        let saturdayRequest = UNNotificationRequest(identifier: "\(NotificationID.weekendDetox).saturday", content: content, trigger: saturdayTrigger)
        
        UNUserNotificationCenter.current().add(saturdayRequest) { error in
            if let error = error {
                print("❌ Failed to schedule Saturday notification: \(error.localizedDescription)")
            }
        }
        
        // Schedule for Sunday at 10:00
        var sundayComponents = DateComponents()
        sundayComponents.weekday = 1 // Sunday
        sundayComponents.hour = 10
        sundayComponents.minute = 0
        
        let sundayTrigger = UNCalendarNotificationTrigger(dateMatching: sundayComponents, repeats: true)
        let sundayRequest = UNNotificationRequest(identifier: "\(NotificationID.weekendDetox).sunday", content: content, trigger: sundayTrigger)
        
        UNUserNotificationCenter.current().add(sundayRequest) { error in
            if let error = error {
                print("❌ Failed to schedule Sunday notification: \(error.localizedDescription)")
            }
        }
    }
    
    // MARK: - Night Reminder Notification (23h daily)
    
    /// 😴 "Il est tard. Fermez Instagram et reposez-vous !"
    private func scheduleNightReminderNotification() {
        let content = UNMutableNotificationContent()
        content.title = "notification.night.title".localized
        content.body = "notification.night.body".localized
        content.sound = .default
        content.categoryIdentifier = "WELLNESS_REMINDER"
        
        // Schedule for 23:00 every day
        var dateComponents = DateComponents()
        dateComponents.hour = 23
        dateComponents.minute = 0
        
        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
        let request = UNNotificationRequest(identifier: NotificationID.nightReminder, content: content, trigger: trigger)
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("❌ Failed to schedule night notification: \(error.localizedDescription)")
            }
        }
    }
    
    // MARK: - Debug Helper
    
    /// List all pending notifications (for debugging)
    func listPendingNotifications() {
        UNUserNotificationCenter.current().getPendingNotificationRequests { requests in
            print("📋 Pending notifications: \(requests.count)")
            for request in requests {
                print("  - \(request.identifier): \(request.content.body)")
            }
        }
    }
}

// MARK: - UNUserNotificationCenterDelegate

extension NotificationManager: UNUserNotificationCenterDelegate {
    /// Handle notification when app is in foreground
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        // Show notification even when app is in foreground
        completionHandler([.banner, .sound])
    }
    
    /// Handle notification tap
    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        let identifier = response.notification.request.identifier
        
        // Track notification interaction
        MixpanelManager.shared.trackNotificationTapped(notificationId: identifier)
        
        completionHandler()
    }
}
