//
//  SharedDataManager.swift
//  LessIsMore
//
//  Created by Angel Geoffroy on 08/01/2026.
//
//  This file manages shared data between the main app and widgets
//  using App Groups for data persistence.

import Foundation
import WidgetKit

/// Keys for shared UserDefaults
enum SharedDataKey: String {
    // Usage data
    case todayUsageSeconds = "today_usage_seconds"
    case yesterdayUsageSeconds = "yesterday_usage_seconds"
    case weeklyUsageTotal = "weekly_usage_total"
    case usagePercentageChange = "usage_percentage_change"
    case lastUpdateDate = "last_update_date"
    
    // Streak data
    case bestStreakDays = "best_streak_days"
    case bestStreakFilterName = "best_streak_filter_name"
    case bestStreakPersonalRecord = "best_streak_personal_record"
    
    // Individual filter streaks
    case reelsStreakDays = "reels_streak_days"
    case exploreStreakDays = "explore_streak_days"
    case storiesStreakDays = "stories_streak_days"
    case suggestionsStreakDays = "suggestions_streak_days"
    case likesStreakDays = "likes_streak_days"
    case followingStreakDays = "following_streak_days"
    case messagesStreakDays = "messages_streak_days"
}

/// Manages shared data between the main app and widget extension
class SharedDataManager {
    
    static let shared = SharedDataManager()
    
    /// App Group identifier - must match the one in entitlements
    private let appGroupIdentifier = "group.LessIsMoreWidget"
    
    /// Shared UserDefaults instance
    private lazy var sharedDefaults: UserDefaults? = {
        return UserDefaults(suiteName: appGroupIdentifier)
    }()
    
    private init() {}
    
    // MARK: - Generic Setters & Getters
    
    func setInt(_ value: Int, forKey key: SharedDataKey) {
        sharedDefaults?.set(value, forKey: key.rawValue)
    }
    
    func getInt(forKey key: SharedDataKey) -> Int {
        return sharedDefaults?.integer(forKey: key.rawValue) ?? 0
    }
    
    func setDouble(_ value: Double, forKey key: SharedDataKey) {
        sharedDefaults?.set(value, forKey: key.rawValue)
    }
    
    func getDouble(forKey key: SharedDataKey) -> Double {
        return sharedDefaults?.double(forKey: key.rawValue) ?? 0.0
    }
    
    func setString(_ value: String, forKey key: SharedDataKey) {
        sharedDefaults?.set(value, forKey: key.rawValue)
    }
    
    func getString(forKey key: SharedDataKey) -> String {
        return sharedDefaults?.string(forKey: key.rawValue) ?? ""
    }
    
    func setDate(_ value: Date, forKey key: SharedDataKey) {
        sharedDefaults?.set(value, forKey: key.rawValue)
    }
    
    func getDate(forKey key: SharedDataKey) -> Date? {
        return sharedDefaults?.object(forKey: key.rawValue) as? Date
    }
    
    // MARK: - Usage Data
    
    func updateUsageData(
        todaySeconds: Int,
        yesterdaySeconds: Int,
        weeklyTotal: Int,
        percentageChange: Double
    ) {
        setInt(todaySeconds, forKey: .todayUsageSeconds)
        setInt(yesterdaySeconds, forKey: .yesterdayUsageSeconds)
        setInt(weeklyTotal, forKey: .weeklyUsageTotal)
        setDouble(percentageChange, forKey: .usagePercentageChange)
        setDate(Date(), forKey: .lastUpdateDate)
        
        // Request widget refresh
        refreshWidgets()
    }
    
    // MARK: - Streak Data
    
    func updateStreakData(
        bestDays: Int,
        filterName: String,
        personalRecord: Int
    ) {
        setInt(bestDays, forKey: .bestStreakDays)
        setString(filterName, forKey: .bestStreakFilterName)
        setInt(personalRecord, forKey: .bestStreakPersonalRecord)
        
        // Request widget refresh
        refreshWidgets()
    }
    
    func updateIndividualStreak(filterType: String, days: Int) {
        let key: SharedDataKey
        switch filterType {
        case "reels": key = .reelsStreakDays
        case "explore": key = .exploreStreakDays
        case "stories": key = .storiesStreakDays
        case "suggestions": key = .suggestionsStreakDays
        case "likes": key = .likesStreakDays
        case "following": key = .followingStreakDays
        case "messages": key = .messagesStreakDays
        default: return
        }
        setInt(days, forKey: key)
    }
    
    // MARK: - Widget Refresh
    
    /// Tells iOS to refresh all LessIsMore widgets
    func refreshWidgets() {
        WidgetCenter.shared.reloadAllTimelines()
    }
    
    /// Tells iOS to refresh a specific widget kind
    func refreshWidget(kind: String) {
        WidgetCenter.shared.reloadTimelines(ofKind: kind)
    }
}
