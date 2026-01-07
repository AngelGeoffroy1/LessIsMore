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
    
    struct MonthlyWeekData: Identifiable, Codable {
        let id: UUID
        let weekLabel: String // "Week 1", "Week 2", etc.
        let weekNumber: Int // 1, 2, 3, 4, 5
        var categorySeconds: [String: Int]
        
        var totalSeconds: Int {
            categorySeconds.values.reduce(0, +)
        }
        
        init(weekLabel: String, weekNumber: Int, categorySeconds: [String: Int] = [:]) {
            self.id = UUID()
            self.weekLabel = weekLabel
            self.weekNumber = weekNumber
            self.categorySeconds = categorySeconds
        }
    }

    @Published var currentCategory: UsageCategory = .feed
    @Published var todayUsageSeconds: Int = 0
    @Published var weeklyUsage: [WeeklyUsageData] = []
    @Published var monthlyUsage: [MonthlyWeekData] = []

    private var timer: Timer?
    private var isTracking = false
    private let userDefaults = UserDefaults.standard

    private let usageSecondsKey = "usage_today_seconds"
    private let lastDateKey = "usage_last_date"

    private init() {
        initializeWeeklyUsage()
        initializeMonthlyUsage()
        loadUsage()
        updateTodayInWeekly()
        updateCurrentWeekInMonthly()
        setupNotifications()
        startTracking()
    }

    private func initializeWeeklyUsage() {
        let dayNames = ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"]
        weeklyUsage = dayNames.map { WeeklyUsageData(day: $0) }
    }
    
    private func initializeMonthlyUsage() {
        // Calculer le nombre de semaines dans le mois actuel
        let weeksInMonth = getWeeksInCurrentMonth()
        monthlyUsage = (1...weeksInMonth).map { weekNum in
            MonthlyWeekData(weekLabel: "Week \(weekNum)", weekNumber: weekNum)
        }
    }
    
    private func getWeeksInCurrentMonth() -> Int {
        let calendar = Calendar.current
        let now = Date()
        guard let range = calendar.range(of: .weekOfMonth, in: .month, for: now) else {
            return 4 // Fallback
        }
        return range.count
    }
    
    private func getCurrentWeekOfMonth() -> Int {
        let calendar = Calendar.current
        return calendar.component(.weekOfMonth, from: Date())
    }
    
    /// Synchronise les données hebdomadaires vers les données mensuelles
    /// Cette fonction reconstruit les données mensuelles à partir des données hebdomadaires existantes
    private func syncWeeklyToMonthly() {
        let calendar = Calendar.current
        let today = Date()
        
        // Réinitialiser les données mensuelles
        for i in 0..<monthlyUsage.count {
            monthlyUsage[i].categorySeconds = [:]
        }
        
        // Pour chaque jour de la semaine avec des données
        let dayNames = ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"]
        
        for dayData in weeklyUsage {
            guard dayData.totalSeconds > 0 else { continue }
            
            // Trouver la date de ce jour dans la semaine actuelle
            guard let dayIndex = dayNames.firstIndex(of: dayData.day) else { continue }
            
            // Calculer la date de ce jour
            let todayWeekday = calendar.component(.weekday, from: today) // 1 = Sunday
            let daysDiff = dayIndex - (todayWeekday - 1)
            
            guard let dayDate = calendar.date(byAdding: .day, value: daysDiff, to: today) else { continue }
            
            // Vérifier si ce jour est dans le mois actuel
            let dayMonth = calendar.component(.month, from: dayDate)
            let currentMonth = calendar.component(.month, from: today)
            
            guard dayMonth == currentMonth else { continue }
            
            // Obtenir la semaine du mois pour ce jour
            let weekOfMonth = calendar.component(.weekOfMonth, from: dayDate)
            
            // Ajouter les données à la semaine correspondante
            if let weekIndex = monthlyUsage.firstIndex(where: { $0.weekNumber == weekOfMonth }) {
                for (category, seconds) in dayData.categorySeconds {
                    let currentVal = monthlyUsage[weekIndex].categorySeconds[category] ?? 0
                    monthlyUsage[weekIndex].categorySeconds[category] = currentVal + seconds
                }
            }
        }
    }
    
    private func updateCurrentWeekInMonthly() {
        // Synchroniser les données hebdomadaires vers les données mensuelles
        syncWeeklyToMonthly()
    }
    
    /// Get the current month name for display
    var currentMonthName: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        return formatter.string(from: Date())
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

    /// Returns the percentage difference compared to yesterday.
    /// Positive means more usage today, negative means less.
    func getComparisonToYesterday() -> Double {
        let calendar = Calendar.current
        guard let yesterdayDate = calendar.date(byAdding: .day, value: -1, to: Date()) else { return 0 }
        
        let weekday = calendar.component(.weekday, from: yesterdayDate)
        let dayNames = ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"]
        let yesterdayDayName = dayNames[weekday - 1]
        
        guard let yesterdayData = weeklyUsage.first(where: { $0.day == yesterdayDayName }) else { return 0 }
        
        let yesterdaySeconds = yesterdayData.totalSeconds
        if yesterdaySeconds == 0 { return 0 }
        
        let diff = Double(todayUsageSeconds - yesterdaySeconds)
        return (diff / Double(yesterdaySeconds)) * 100
    }
    
    // MARK: - Monthly Mode Methods
    
    /// Returns the total seconds for the current week of the month
    var currentWeekTotalSeconds: Int {
        let currentWeek = getCurrentWeekOfMonth()
        guard let weekData = monthlyUsage.first(where: { $0.weekNumber == currentWeek }) else { return 0 }
        return weekData.totalSeconds
    }
    
    /// Returns formatted time for the current week
    var formattedCurrentWeekTime: String {
        let seconds = currentWeekTotalSeconds
        let hours = seconds / 3600
        let minutes = (seconds % 3600) / 60
        
        if hours > 0 {
            return "\(hours)h\(minutes > 0 ? " \(minutes)m" : "")"
        }
        return "\(minutes)m"
    }
    
    /// Returns the percentage difference compared to last week.
    /// Positive means more usage this week, negative means less.
    func getComparisonToLastWeek() -> Double {
        let currentWeek = getCurrentWeekOfMonth()
        let lastWeek = currentWeek - 1
        
        guard lastWeek >= 1 else { return 0 }
        
        guard let lastWeekData = monthlyUsage.first(where: { $0.weekNumber == lastWeek }) else { return 0 }
        
        let lastWeekSeconds = lastWeekData.totalSeconds
        if lastWeekSeconds == 0 { return 0 }
        
        let diff = Double(currentWeekTotalSeconds - lastWeekSeconds)
        return (diff / Double(lastWeekSeconds)) * 100
    }

    // MARK: - Private Methods

    private func loadUsage() {
        let savedDate = userDefaults.string(forKey: lastDateKey) ?? ""
        let savedMonth = userDefaults.string(forKey: "usage_last_month") ?? ""
        let today = currentDateString()
        let currentMonth = currentMonthString()

        // Load weekly data if exists
        if let data = userDefaults.data(forKey: "weekly_usage_detailed"),
           let decoded = try? JSONDecoder().decode([WeeklyUsageData].self, from: data) {
            weeklyUsage = decoded
        }
        
        // Load monthly data if exists
        if let monthData = userDefaults.data(forKey: "monthly_usage_detailed"),
           let decodedMonth = try? JSONDecoder().decode([MonthlyWeekData].self, from: monthData) {
            monthlyUsage = decodedMonth
        }
        
        // Check if month changed - reset monthly data
        if savedMonth != currentMonth {
            initializeMonthlyUsage()
            userDefaults.set(currentMonth, forKey: "usage_last_month")
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
        updateCurrentWeekInMonthly()
    }
    
    private func currentMonthString() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM"
        return formatter.string(from: Date())
    }

    private func saveUsage() {
        if let encoded = try? JSONEncoder().encode(weeklyUsage) {
            userDefaults.set(encoded, forKey: "weekly_usage_detailed")
        }
        if let monthEncoded = try? JSONEncoder().encode(monthlyUsage) {
            userDefaults.set(monthEncoded, forKey: "monthly_usage_detailed")
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
                let catKey = self.currentCategory.rawValue
                
                // Update weekly data
                if let index = self.weeklyUsage.firstIndex(where: { $0.day == currentDayName }) {
                    let currentVal = self.weeklyUsage[index].categorySeconds[catKey] ?? 0
                    self.weeklyUsage[index].categorySeconds[catKey] = currentVal + 1
                    
                    self.todayUsageSeconds = self.weeklyUsage[index].totalSeconds
                }
                
                // Update monthly data (current week)
                let currentWeek = self.getCurrentWeekOfMonth()
                if let weekIndex = self.monthlyUsage.firstIndex(where: { $0.weekNumber == currentWeek }) {
                    let currentMonthVal = self.monthlyUsage[weekIndex].categorySeconds[catKey] ?? 0
                    self.monthlyUsage[weekIndex].categorySeconds[catKey] = currentMonthVal + 1
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
