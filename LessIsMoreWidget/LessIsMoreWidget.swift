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
        case 0...30: return .green
        case 31...60: return .yellow
        case 61...90: return .orange
        default: return .red
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
        Color(red: 1.0, green: 0.60, blue: 0.0),    // Orange
        Color(red: 0.98, green: 0.05, blue: 0.44),  // Rose/Pink
        Color(red: 0.73, green: 0.20, blue: 0.82)   // Purple
    ],
    startPoint: .leading,
    endPoint: .trailing
)

// MARK: - Small Streak Widget View

struct SmallStreakWidgetView: View {
    let entry: LessIsMoreEntry
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        ZStack {
            // Background
            ContainerRelativeShape()
                .fill(colorScheme == .dark 
                    ? Color(red: 0.1, green: 0.1, blue: 0.12) 
                    : Color(red: 0.96, green: 0.96, blue: 0.98))
            
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
                    .foregroundColor(.yellow.opacity(0.8))
                }
            }
            .padding(12)
        }
    }
}

// MARK: - Small Time Widget View

struct SmallTimeWidgetView: View {
    let entry: LessIsMoreEntry
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        ZStack {
            // Background
            ContainerRelativeShape()
                .fill(colorScheme == .dark 
                    ? Color(red: 0.1, green: 0.1, blue: 0.12) 
                    : Color(red: 0.96, green: 0.96, blue: 0.98))
            
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
                    .foregroundColor(entry.percentageChange < 0 ? .green : .red)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(
                        Capsule()
                            .fill((entry.percentageChange < 0 ? Color.green : Color.red).opacity(0.15))
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
        case 0...30: return .green
        case 31...60: return .yellow
        case 61...90: return .orange
        default: return .red
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
        ZStack {
            // Background
            ContainerRelativeShape()
                .fill(colorScheme == .dark 
                    ? Color(red: 0.1, green: 0.1, blue: 0.12) 
                    : Color(red: 0.96, green: 0.96, blue: 0.98))
            
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
                        .foregroundColor(entry.percentageChange < 0 ? .green : .red)
                    }
                }
                .frame(maxWidth: .infinity)
            }
            .padding(16)
        }
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
