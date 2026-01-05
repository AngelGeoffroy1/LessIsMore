//
//  UsageTracker.swift
//  LessIsMore
//
//  Created by Angel Geoffroy on 05/01/2026.
//

import Foundation
import Combine
import UIKit
import SwiftUI

class UsageTracker: ObservableObject {
    static let shared = UsageTracker()

    enum UsageCategory: String, CaseIterable, Codable {
        case feed = "Feed"
        case reels = "Reels"
        case stories = "Stories"
        case messages = "Messages"
        case explore = "Explore"
        case other = "Other"
        
        var color: Color {
            switch self {
            case .feed: return .blue
            case .reels: return Color(red: 0.98, green: 0.05, blue: 0.44) // Rose Insta
            case .stories: return Color(red: 1.0, green: 0.60, blue: 0.0) // Orange Insta
            case .messages: return .purple
            case .explore: return .green
            case .other: return .gray
            }
        }
    }

    struct WeeklyUsageData: Identifiable, Codable {
        let id: UUID
        let day: String
        var categorySeconds: [String: Int] // Use String key for Codable compatibility
        
        var totalSeconds: Int {
            categorySeconds.values.reduce(0, +)
        }

        init(day: String, seconds: Int = 0) {
            self.id = UUID()
            self.day = day
            self.categorySeconds = [UsageCategory.feed.rawValue: seconds]
        }
    }

    @Published var currentCategory: UsageCategory = .feed
    @Published var todayUsageSeconds: Int = 0
    @Published var weeklyUsage: [WeeklyUsageData] = []

    private var timer: Timer?
    private var isTracking = false
    private let userDefaults = UserDefaults.standard

    private let usageSecondsKey = "usage_today_seconds"
    private let lastDateKey = "usage_last_date"

    private init() {
        initializeWeeklyUsage()
        loadUsage()
        updateTodayInWeekly()
        setupNotifications()
        startTracking()
    }

    private func initializeWeeklyUsage() {
        let dayNames = ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"]
        weeklyUsage = dayNames.map { WeeklyUsageData(day: $0) }
    }

    private func updateTodayInWeekly() {
        let currentDayName = getCurrentDayName()
        if let index = weeklyUsage.firstIndex(where: { $0.day == currentDayName }) {
            // This is just to sync the UI when loading, 
            // the tracking logic already updates the specific categories.
            todayUsageSeconds = weeklyUsage[index].totalSeconds
        }
    }

    private func getCurrentDayName() -> String {
        let calendar = Calendar.current
        let weekday = calendar.component(.weekday, from: Date())
        // Adjusting to Mon-Sun
        let dayNames = ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"]
        return dayNames[weekday - 1]
    }


    deinit {
        stopTracking()
        NotificationCenter.default.removeObserver(self)
    }

    // MARK: - Public Methods

    var formattedTime: String {
        let hours = todayUsageSeconds / 3600
        let minutes = (todayUsageSeconds % 3600) / 60

        if hours > 0 {
            return "\(hours)h \(minutes)m"
        } else if minutes > 0 {
            return "\(minutes)m"
        } else {
            return "0m"
        }
    }

    var formattedTimeShort: String {
        let minutes = todayUsageSeconds / 60
        if minutes >= 60 {
            let hours = minutes / 60
            let remainingMinutes = minutes % 60
            return "\(hours)h\(remainingMinutes > 0 ? " \(remainingMinutes)m" : "")"
        }
        return "\(minutes)m"
    }

    // MARK: - Private Methods

    private func loadUsage() {
        let savedDate = userDefaults.string(forKey: lastDateKey) ?? ""
        let today = currentDateString()

        // Load weekly data if exists
        if let data = userDefaults.data(forKey: "weekly_usage_detailed"),
           let decoded = try? JSONDecoder().decode([WeeklyUsageData].self, from: data) {
            weeklyUsage = decoded
        }

        if savedDate != today {
            // New day: cleanup but keep weekly history (max 7 days logic would go here)
            // For now we just reset the current day entry in weeklyUsage
            let currentDayName = getCurrentDayName()
            if let index = weeklyUsage.firstIndex(where: { $0.day == currentDayName }) {
                weeklyUsage[index].categorySeconds = [:]
            }
            userDefaults.set(today, forKey: lastDateKey)
            saveUsage()
        }
        
        updateTodayInWeekly()
    }

    private func saveUsage() {
        if let encoded = try? JSONEncoder().encode(weeklyUsage) {
            userDefaults.set(encoded, forKey: "weekly_usage_detailed")
        }
        userDefaults.set(currentDateString(), forKey: lastDateKey)
    }

    private func setupNotifications() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(appDidBecomeActive),
            name: UIApplication.didBecomeActiveNotification,
            object: nil
        )

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(appWillResignActive),
            name: UIApplication.willResignActiveNotification,
            object: nil
        )

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(appWillTerminate),
            name: UIApplication.willTerminateNotification,
            object: nil
        )
    }

    @objc private func appDidBecomeActive() {
        loadUsage() // Recharger au cas où le jour a changé
        startTracking()
    }

    @objc private func appWillResignActive() {
        stopTracking()
        saveUsage()
    }

    @objc private func appWillTerminate() {
        stopTracking()
        saveUsage()
    }

    private func startTracking() {
        guard !isTracking else { return }
        isTracking = true

        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            DispatchQueue.main.async {
                let currentDayName = self.getCurrentDayName()
                if let index = self.weeklyUsage.firstIndex(where: { $0.day == currentDayName }) {
                    let catKey = self.currentCategory.rawValue
                    let currentVal = self.weeklyUsage[index].categorySeconds[catKey] ?? 0
                    self.weeklyUsage[index].categorySeconds[catKey] = currentVal + 1
                    
                    self.todayUsageSeconds = self.weeklyUsage[index].totalSeconds
                }

                // Sauvegarder toutes les 30 secondes
                if self.todayUsageSeconds % 30 == 0 {
                    self.saveUsage()
                }
            }
        }
    }

    private func stopTracking() {
        timer?.invalidate()
        timer = nil
        isTracking = false
    }

    private func currentDateString() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: Date())
    }
}
