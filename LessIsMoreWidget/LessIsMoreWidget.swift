//
//  LessIsMoreWidget.swift
//  LessIsMoreWidget
//
//  Created by Angel Geoffroy on 08/01/2026.
//

import WidgetKit
import SwiftUI

// MARK: - App Group Identifier
let appGroupIdentifier = "group.LessIsMoreWidget"

// MARK: - Widget Weekly Data Structure (must match UsageTracker.WeeklyUsageData)
struct WidgetWeeklyData: Identifiable, Codable {
    let id: UUID
    let day: String
    var categorySeconds: [String: Int]
    
    var totalSeconds: Int {
        categorySeconds.values.reduce(0, +)
    }
}

// MARK: - Widget Usage Category
enum WidgetUsageCategory: String, CaseIterable {
    case feed = "Feed"
    case reels = "Reels"
    case stories = "Stories"
    case messages = "Messages"
    case explore = "Explore"
    case other = "Other"
    
    var color: Color {
        // Monochrome DA: categories are told apart by grey shade
        let index = WidgetUsageCategory.allCases.firstIndex(of: self) ?? 0
        let step = 0.75 / Double(WidgetUsageCategory.allCases.count - 1)
        return Color.primary.opacity(1.0 - Double(index) * step)
    }
}

// MARK: - Shared Data Reader (Widget Side)

struct WidgetDataReader {
    private let sharedDefaults = UserDefaults(suiteName: appGroupIdentifier)
    
    // Usage Data
    var todayUsageSeconds: Int {
        sharedDefaults?.integer(forKey: "today_usage_seconds") ?? 0
    }
    
    var yesterdayUsageSeconds: Int {
        sharedDefaults?.integer(forKey: "yesterday_usage_seconds") ?? 0
    }
    
    var weeklyUsageTotal: Int {
        sharedDefaults?.integer(forKey: "weekly_usage_total") ?? 0
    }
    
    var usagePercentageChange: Double {
        sharedDefaults?.double(forKey: "usage_percentage_change") ?? 0.0
    }
    
    // Weekly Chart Data
    var weeklyUsageData: [WidgetWeeklyData] {
        guard let data = sharedDefaults?.data(forKey: "weekly_usage_data"),
              let decoded = try? JSONDecoder().decode([WidgetWeeklyData].self, from: data) else {
            // Return placeholder data
            return ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"].map { day in
                WidgetWeeklyData(id: UUID(), day: day, categorySeconds: [:])
            }
        }
        return decoded
    }
    
    // Streak Data
    var bestStreakDays: Int {
        sharedDefaults?.integer(forKey: "best_streak_days") ?? 0
    }
    
    var bestStreakFilterName: String {
        sharedDefaults?.string(forKey: "best_streak_filter_name") ?? ""
    }
    
    var bestStreakPersonalRecord: Int {
        sharedDefaults?.integer(forKey: "best_streak_personal_record") ?? 0
    }
    
    // Formatted Time
    var formattedTodayTime: String {
        formatTime(seconds: todayUsageSeconds)
    }
    
    var formattedWeeklyTime: String {
        formatTime(seconds: weeklyUsageTotal)
    }
    
    private func formatTime(seconds: Int) -> String {
        let hours = seconds / 3600
        let minutes = (seconds % 3600) / 60
        
        if hours > 0 {
            return "\(hours)h\(minutes > 0 ? " \(minutes)m" : "")"
        } else if minutes > 0 {
            return "\(minutes)m"
        }
        return "0m"
    }
}

// MARK: - Timeline Entry

struct LessIsMoreEntry: TimelineEntry {
    let date: Date
    let todaySeconds: Int
    let percentageChange: Double
    let streakDays: Int
    let streakFilterName: String
    let personalRecord: Int
    
    var formattedTime: String {
        let hours = todaySeconds / 3600
        let minutes = (todaySeconds % 3600) / 60
        if hours > 0 {
            return "\(hours)h\(minutes > 0 ? " \(minutes)m" : "")"
        } else if minutes > 0 {
            return "\(minutes)m"
        }
        return "0m"
    }
    
    // Color based on usage
    var usageColor: Color {
        let minutes = todaySeconds / 60
        switch minutes {
        case 0...30: return .primary.opacity(0.45)
        case 31...60: return .primary.opacity(0.65)
        case 61...90: return .primary.opacity(0.85)
        default: return .primary
        }
    }
    
    static var placeholder: LessIsMoreEntry {
        LessIsMoreEntry(
            date: Date(),
            todaySeconds: 2700, // 45 min
            percentageChange: -15.0,
            streakDays: 7,
            streakFilterName: "Reels",
            personalRecord: 12
        )
    }
}

// MARK: - Timeline Provider

struct LessIsMoreProvider: TimelineProvider {
    func placeholder(in context: Context) -> LessIsMoreEntry {
        .placeholder
    }
    
    func getSnapshot(in context: Context, completion: @escaping (LessIsMoreEntry) -> Void) {
        let entry = readCurrentData()
        completion(entry)
    }
    
    func getTimeline(in context: Context, completion: @escaping (Timeline<LessIsMoreEntry>) -> Void) {
        let entry = readCurrentData()
        
        // Update every 15 minutes
        let nextUpdate = Calendar.current.date(byAdding: .minute, value: 15, to: Date())!
        let timeline = Timeline(entries: [entry], policy: .after(nextUpdate))
        completion(timeline)
    }
    
    private func readCurrentData() -> LessIsMoreEntry {
        let reader = WidgetDataReader()
        
        return LessIsMoreEntry(
            date: Date(),
            todaySeconds: reader.todayUsageSeconds,
            percentageChange: reader.usagePercentageChange,
            streakDays: reader.bestStreakDays,
            streakFilterName: reader.bestStreakFilterName,
            personalRecord: reader.bestStreakPersonalRecord
        )
    }
}

// MARK: - Instagram Gradient

let instagramGradient = LinearGradient(
    colors: [
        Color.primary,
        Color.primary // Monochrome DA
    ],
    startPoint: .leading,
    endPoint: .trailing
)

// MARK: - Small Streak Widget View

struct SmallStreakWidgetView: View {
    let entry: LessIsMoreEntry
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        VStack(spacing: 6) {
            // Header
            Text("STREAK")
                .font(.system(size: 10, weight: .semibold))
                .foregroundColor(.secondary)
                .tracking(1)
            
            Spacer()
            
            if entry.streakDays > 0 {
                // Flame emoji
                Text("🔥")
                    .font(.system(size: 36))
                
                // Days count
                Text("\(entry.streakDays)")
                    .font(.system(size: 32, weight: .bold, design: .rounded))
                    .foregroundStyle(instagramGradient)
                
                Text(entry.streakDays == 1 ? "day" : "days")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.secondary)
                
                // Filter name
                Text("No \(entry.streakFilterName)")
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(.secondary.opacity(0.8))
                    .lineLimit(1)
            } else {
                // No active streak
                Text("🔒")
                    .font(.system(size: 36))
                
                Text("No streak")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.secondary)
                
                Text("Tap to start")
                    .font(.system(size: 10))
                    .foregroundColor(.secondary.opacity(0.6))
            }
            
            Spacer()
            
            // Personal record (if exists)
            if entry.personalRecord > 0 && entry.streakDays > 0 {
                HStack(spacing: 2) {
                    Image(systemName: "trophy.fill")
                        .font(.system(size: 8))
                    Text("\(entry.personalRecord)")
                        .font(.system(size: 10, weight: .semibold))
                }
                .foregroundColor(.primary.opacity(0.8))
            }
        }
        .padding(12)
    }
}

// MARK: - Small Time Widget View

struct SmallTimeWidgetView: View {
    let entry: LessIsMoreEntry
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        VStack(spacing: 6) {
            // Header
            Text("TODAY")
                .font(.system(size: 10, weight: .semibold))
                .foregroundColor(.secondary)
                .tracking(1)
            
            Spacer()
            
            // Time display
            Text(entry.formattedTime)
                .font(.system(size: 34, weight: .bold, design: .rounded))
                .foregroundColor(entry.usageColor)
                .minimumScaleFactor(0.6)
                .lineLimit(1)
            
            // Usage indicator bar
            UsageProgressBar(minutes: entry.todaySeconds / 60)
                .frame(height: 6)
                .padding(.horizontal, 8)
            
            Spacer()
            
            // Trend
            if entry.percentageChange != 0 {
                HStack(spacing: 3) {
                    Image(systemName: entry.percentageChange < 0 ? "arrow.down" : "arrow.up")
                        .font(.system(size: 9, weight: .bold))
                    
                    Text("\(abs(Int(entry.percentageChange)))%")
                        .font(.system(size: 11, weight: .semibold))
                }
                .foregroundColor(.primary)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(
                    Capsule()
                        .fill(Color.primary.opacity(0.1))
                )
            } else {
                Text("vs yesterday")
                    .font(.system(size: 10))
                    .foregroundColor(.secondary.opacity(0.6))
            }
        }
        .padding(12)
    }
}

// MARK: - Usage Progress Bar

struct UsageProgressBar: View {
    let minutes: Int
    private let maxMinutes: CGFloat = 120 // 2 hours max
    
    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                // Background
                RoundedRectangle(cornerRadius: 3)
                    .fill(Color.primary.opacity(0.1))
                
                // Progress
                RoundedRectangle(cornerRadius: 3)
                    .fill(progressColor)
                    .frame(width: progressWidth(in: geometry.size.width))
            }
        }
    }
    
    private var progressColor: Color {
        switch minutes {
        case 0...30: return .primary.opacity(0.45)
        case 31...60: return .primary.opacity(0.65)
        case 61...90: return .primary.opacity(0.85)
        default: return .primary
        }
    }
    
    private func progressWidth(in totalWidth: CGFloat) -> CGFloat {
        let progress = min(CGFloat(minutes) / maxMinutes, 1.0)
        return totalWidth * progress
    }
}

// MARK: - Medium Combo Widget View

struct MediumComboWidgetView: View {
    let entry: LessIsMoreEntry
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        HStack(spacing: 16) {
            // Left side: Streak
            VStack(spacing: 4) {
                if entry.streakDays > 0 {
                    Text("🔥")
                        .font(.system(size: 30))
                    
                    Text("\(entry.streakDays)")
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                        .foregroundStyle(instagramGradient)
                    
                    Text(entry.streakDays == 1 ? "day" : "days")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(.secondary)
                    
                    Text("No \(entry.streakFilterName)")
                        .font(.system(size: 9, weight: .medium))
                        .foregroundColor(.secondary.opacity(0.7))
                        .lineLimit(1)
                } else {
                    Text("🔒")
                        .font(.system(size: 30))
                    
                    Text("Start a")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.secondary)
                    
                    Text("streak!")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.secondary)
                }
            }
            .frame(maxWidth: .infinity)
            
            // Divider
            Rectangle()
                .fill(Color.primary.opacity(0.1))
                .frame(width: 1)
                .padding(.vertical, 12)
            
            // Right side: Time
            VStack(spacing: 4) {
                Text("TODAY")
                    .font(.system(size: 9, weight: .semibold))
                    .foregroundColor(.secondary)
                    .tracking(1)
                
                Text(entry.formattedTime)
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundColor(entry.usageColor)
                    .minimumScaleFactor(0.7)
                    .lineLimit(1)
                
                UsageProgressBar(minutes: entry.todaySeconds / 60)
                    .frame(height: 5)
                    .padding(.horizontal, 4)
                
                if entry.percentageChange != 0 {
                    HStack(spacing: 2) {
                        Image(systemName: entry.percentageChange < 0 ? "arrow.down" : "arrow.up")
                            .font(.system(size: 8, weight: .bold))
                        
                        Text("\(abs(Int(entry.percentageChange)))% vs hier")
                            .font(.system(size: 9, weight: .medium))
                    }
                    .foregroundColor(.primary)
                }
            }
            .frame(maxWidth: .infinity)
        }
        .padding(16)
    }
}

// MARK: - Streak Widget Configuration

struct StreakWidget: Widget {
    let kind: String = "StreakWidget"
    
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: LessIsMoreProvider()) { entry in
            if #available(iOS 17.0, *) {
                SmallStreakWidgetView(entry: entry)
                    .containerBackground(.fill.tertiary, for: .widget)
            } else {
                SmallStreakWidgetView(entry: entry)
            }
        }
        .configurationDisplayName("Streak")
        .description("Your current filter streak")
        .supportedFamilies([.systemSmall])
    }
}

// MARK: - Time Widget Configuration

struct TimeWidget: Widget {
    let kind: String = "TimeWidget"
    
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: LessIsMoreProvider()) { entry in
            if #available(iOS 17.0, *) {
                SmallTimeWidgetView(entry: entry)
                    .containerBackground(.fill.tertiary, for: .widget)
            } else {
                SmallTimeWidgetView(entry: entry)
            }
        }
        .configurationDisplayName("Time Today")
        .description("Your Instagram usage today")
        .supportedFamilies([.systemSmall])
    }
}

// MARK: - Combo Widget Configuration

struct ComboWidget: Widget {
    let kind: String = "ComboWidget"
    
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: LessIsMoreProvider()) { entry in
            if #available(iOS 17.0, *) {
                MediumComboWidgetView(entry: entry)
                    .containerBackground(.fill.tertiary, for: .widget)
            } else {
                MediumComboWidgetView(entry: entry)
            }
        }
        .configurationDisplayName("Streak & Time")
        .description("Your streak and daily usage")
        .supportedFamilies([.systemMedium])
    }
}

// MARK: - Legacy Main Widget (keeping for compatibility)

struct LessIsMoreWidget: Widget {
    let kind: String = "LessIsMoreWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: LessIsMoreProvider()) { entry in
            if #available(iOS 17.0, *) {
                SmallStreakWidgetView(entry: entry)
                    .containerBackground(.fill.tertiary, for: .widget)
            } else {
                SmallStreakWidgetView(entry: entry)
            }
        }
        .configurationDisplayName("LessIsMore")
        .description("Track your Instagram usage and streaks")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

// MARK: - Large Chart Entry

struct LargeChartEntry: TimelineEntry {
    let date: Date
    let weeklyData: [WidgetWeeklyData]
    let todaySeconds: Int
    let percentageChange: Double
    let streakDays: Int
    let streakFilterName: String
    
    var formattedTime: String {
        let hours = todaySeconds / 3600
        let minutes = (todaySeconds % 3600) / 60
        if hours > 0 {
            return "\(hours)h\(minutes > 0 ? " \(minutes)m" : "")"
        } else if minutes > 0 {
            return "\(minutes)m"
        }
        return "0m"
    }
    
    var formattedWeeklyTime: String {
        let totalSeconds = weeklyData.reduce(0) { $0 + $1.totalSeconds }
        let hours = totalSeconds / 3600
        let minutes = (totalSeconds % 3600) / 60
        if hours > 0 {
            return "\(hours)h\(minutes > 0 ? " \(minutes)m" : "")"
        } else if minutes > 0 {
            return "\(minutes)m"
        }
        return "0m"
    }
    
    static var placeholder: LargeChartEntry {
        let placeholderData = ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"].enumerated().map { index, day in
            WidgetWeeklyData(
                id: UUID(),
                day: day,
                categorySeconds: [
                    "Feed": (index + 1) * 600,
                    "Reels": (index + 1) * 900,
                    "Stories": (index + 1) * 300
                ]
            )
        }
        return LargeChartEntry(
            date: Date(),
            weeklyData: placeholderData,
            todaySeconds: 2700,
            percentageChange: -15.0,
            streakDays: 7,
            streakFilterName: "Reels"
        )
    }
}

// MARK: - Large Chart Provider

struct LargeChartProvider: TimelineProvider {
    typealias Entry = LargeChartEntry
    
    func placeholder(in context: Context) -> LargeChartEntry {
        .placeholder
    }
    
    func getSnapshot(in context: Context, completion: @escaping (LargeChartEntry) -> Void) {
        let entry = readCurrentData()
        completion(entry)
    }
    
    func getTimeline(in context: Context, completion: @escaping (Timeline<LargeChartEntry>) -> Void) {
        let entry = readCurrentData()
        
        let nextUpdate = Calendar.current.date(byAdding: .minute, value: 15, to: Date())!
        let timeline = Timeline(entries: [entry], policy: .after(nextUpdate))
        completion(timeline)
    }
    
    private func readCurrentData() -> LargeChartEntry {
        let reader = WidgetDataReader()
        
        return LargeChartEntry(
            date: Date(),
            weeklyData: reader.weeklyUsageData,
            todaySeconds: reader.todayUsageSeconds,
            percentageChange: reader.usagePercentageChange,
            streakDays: reader.bestStreakDays,
            streakFilterName: reader.bestStreakFilterName
        )
    }
}

// MARK: - Large Chart Widget View

struct LargeChartWidgetView: View {
    let entry: LargeChartEntry
    @Environment(\.colorScheme) var colorScheme
    
    private var currentDayName: String {
        let calendar = Calendar.current
        let weekday = calendar.component(.weekday, from: Date())
        let dayNames = ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"]
        return dayNames[weekday - 1]
    }
    
    private let chartHeight: CGFloat = 120
    
    var body: some View {
        VStack(spacing: 12) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("THIS WEEK")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundColor(.secondary)
                        .tracking(1)
                    
                    Text(entry.formattedWeeklyTime)
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                        .foregroundColor(.primary)
                }
                
                Spacer()
                
                // Trend Badge
                if entry.percentageChange != 0 {
                    HStack(spacing: 4) {
                        Image(systemName: entry.percentageChange < 0 ? "arrow.down" : "arrow.up")
                            .font(.system(size: 10, weight: .bold))
                        Text("\(abs(Int(entry.percentageChange)))%")
                            .font(.system(size: 12, weight: .semibold))
                    }
                    .foregroundColor(.primary)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(
                        Capsule()
                            .fill(Color.primary.opacity(0.1))
                    )
                }
                
                // Streak if active
                if entry.streakDays > 0 {
                    HStack(spacing: 4) {
                        Text("🔥")
                            .font(.system(size: 14))
                        Text("\(entry.streakDays)")
                            .font(.system(size: 14, weight: .bold, design: .rounded))
                            .foregroundStyle(instagramGradient)
                    }
                }
            }
            
            // Chart
            HStack(alignment: .bottom, spacing: 6) {
                ForEach(entry.weeklyData) { item in
                    VStack(spacing: 4) {
                        // Stacked Bar
                        ZStack(alignment: .bottom) {
                            RoundedRectangle(cornerRadius: 4)
                                .fill(Color.primary.opacity(0.05))
                                .frame(maxWidth: .infinity)
                                .frame(height: chartHeight)
                            
                            if item.totalSeconds == 0 {
                                let simulatedHeight: CGFloat = 8 + CGFloat(abs(item.day.hashValue % 15))
                                RoundedRectangle(cornerRadius: 4)
                                    .fill(Color.primary.opacity(0.1))
                                    .frame(maxWidth: .infinity)
                                    .frame(height: simulatedHeight)
                            }
                            
                            let maxSeconds = entry.weeklyData.map { $0.totalSeconds }.max() ?? 1
                            let barHeight = item.totalSeconds > 0 
                                ? CGFloat(item.totalSeconds) / CGFloat(max(maxSeconds, 1)) * chartHeight 
                                : 0
                            
                            VStack(spacing: 0) {
                                ForEach(Array(WidgetUsageCategory.allCases.reversed()), id: \.self) { category in
                                    let seconds = item.categorySeconds[category.rawValue] ?? 0
                                    if seconds > 0 && item.totalSeconds > 0 {
                                        Rectangle()
                                            .fill(category.color.opacity(item.day == currentDayName ? 1.0 : 0.5))
                                            .frame(height: CGFloat(seconds) / CGFloat(item.totalSeconds) * barHeight)
                                    }
                                }
                            }
                            .frame(height: barHeight)
                            .clipShape(RoundedRectangle(cornerRadius: 4))
                        }
                        
                        Text(item.day)
                            .font(.system(size: 9, weight: .bold))
                            .foregroundColor(item.day == currentDayName ? .primary : .secondary)
                    }
                }
            }
            .frame(height: chartHeight + 16)
            
            // Legend
            HStack(spacing: 12) {
                ForEach(WidgetUsageCategory.allCases.prefix(4), id: \.self) { category in
                    HStack(spacing: 3) {
                        Circle()
                            .fill(category.color)
                            .frame(width: 6, height: 6)
                        Text(category.rawValue)
                            .font(.system(size: 9, weight: .medium))
                            .foregroundColor(.secondary)
                    }
                }
            }
        }
        .padding(16)
    }
}

// MARK: - Chart Widget Configuration

struct ChartWidget: Widget {
    let kind: String = "ChartWidget"
    
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: LargeChartProvider()) { entry in
            if #available(iOS 17.0, *) {
                LargeChartWidgetView(entry: entry)
                    .containerBackground(.fill.tertiary, for: .widget)
            } else {
                LargeChartWidgetView(entry: entry)
            }
        }
        .configurationDisplayName("Weekly Chart")
        .description("Your weekly usage breakdown by category")
        .supportedFamilies([.systemLarge])
    }
}

// MARK: - Previews

#Preview("Streak Small", as: .systemSmall) {
    StreakWidget()
} timeline: {
    LessIsMoreEntry.placeholder
    LessIsMoreEntry(date: .now, todaySeconds: 3600, percentageChange: 10, streakDays: 0, streakFilterName: "", personalRecord: 0)
}

#Preview("Time Small", as: .systemSmall) {
    TimeWidget()
} timeline: {
    LessIsMoreEntry.placeholder
    LessIsMoreEntry(date: .now, todaySeconds: 5400, percentageChange: -25, streakDays: 7, streakFilterName: "Reels", personalRecord: 12)
}

#Preview("Combo Medium", as: .systemMedium) {
    ComboWidget()
} timeline: {
    LessIsMoreEntry.placeholder
}

#Preview("Chart Large", as: .systemLarge) {
    ChartWidget()
} timeline: {
    LargeChartEntry.placeholder
}
