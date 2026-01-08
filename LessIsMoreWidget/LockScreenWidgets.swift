//
//  LockScreenWidgets.swift
//  LessIsMoreWidget
//
//  Created by Angel Geoffroy on 08/01/2026.
//

import WidgetKit
import SwiftUI

// MARK: - Lock Screen Streak Widget (Circular)

struct LockScreenStreakCircularView: View {
    let entry: LessIsMoreEntry
    
    var body: some View {
        ZStack {
            if entry.streakDays > 0 {
                // Ring background
                AccessoryWidgetBackground()
                
                VStack(spacing: -2) {
                    Text("🔥")
                        .font(.system(size: 14))
                    
                    Text("\(entry.streakDays)")
                        .font(.system(size: 16, weight: .bold, design: .rounded))
                        .minimumScaleFactor(0.5)
                }
            } else {
                AccessoryWidgetBackground()
                
                Image(systemName: "flame.fill")
                    .font(.system(size: 20))
                    .foregroundColor(.secondary)
            }
        }
    }
}

// MARK: - Lock Screen Time Widget (Circular)

struct LockScreenTimeCircularView: View {
    let entry: LessIsMoreEntry
    
    private var minutes: Int {
        entry.todaySeconds / 60
    }
    
    private var formattedShort: String {
        if minutes >= 60 {
            return "\(minutes / 60)h"
        }
        return "\(minutes)m"
    }
    
    var body: some View {
        ZStack {
            AccessoryWidgetBackground()
            
            // Progress ring
            Gauge(value: min(Double(minutes) / 120.0, 1.0)) {
                Text("")
            } currentValueLabel: {
                Text(formattedShort)
                    .font(.system(size: 14, weight: .bold, design: .rounded))
                    .minimumScaleFactor(0.6)
            }
            .gaugeStyle(.accessoryCircular)
        }
    }
}

// MARK: - Lock Screen Rectangular Widget

struct LockScreenRectangularView: View {
    let entry: LessIsMoreEntry
    
    var body: some View {
        HStack(spacing: 8) {
            // Streak section
            if entry.streakDays > 0 {
                HStack(spacing: 3) {
                    Text("🔥")
                        .font(.system(size: 14))
                    Text("\(entry.streakDays)d")
                        .font(.system(size: 14, weight: .bold, design: .rounded))
                }
            }
            
            // Divider
            if entry.streakDays > 0 {
                Text("│")
                    .foregroundColor(.secondary.opacity(0.5))
            }
            
            // Time section
            HStack(spacing: 3) {
                Image(systemName: "clock.fill")
                    .font(.system(size: 11))
                    .foregroundColor(.secondary)
                
                Text(entry.formattedTime)
                    .font(.system(size: 14, weight: .semibold, design: .rounded))
            }
            
            // Trend arrow
            if entry.percentageChange != 0 {
                Image(systemName: entry.percentageChange < 0 ? "arrow.down" : "arrow.up")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(entry.percentageChange < 0 ? .green : .red)
            }
        }
    }
}

// MARK: - Lock Screen Inline Widget

struct LockScreenInlineView: View {
    let entry: LessIsMoreEntry
    
    var body: some View {
        if entry.streakDays > 0 {
            Text("🔥 \(entry.streakDays)d streak • \(entry.formattedTime) today")
        } else {
            Text("📱 \(entry.formattedTime) on Instagram today")
        }
    }
}

// MARK: - Lock Screen Streak Widget Configuration

struct LockScreenStreakWidget: Widget {
    let kind: String = "LockScreenStreakWidget"
    
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: LessIsMoreProvider()) { entry in
            if #available(iOS 17.0, *) {
                LockScreenStreakCircularView(entry: entry)
                    .containerBackground(.fill.tertiary, for: .widget)
            } else {
                LockScreenStreakCircularView(entry: entry)
            }
        }
        .configurationDisplayName("Streak")
        .description("Your current streak")
        .supportedFamilies([.accessoryCircular])
    }
}

// MARK: - Lock Screen Time Widget Configuration

struct LockScreenTimeWidget: Widget {
    let kind: String = "LockScreenTimeWidget"
    
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: LessIsMoreProvider()) { entry in
            if #available(iOS 17.0, *) {
                LockScreenTimeCircularView(entry: entry)
                    .containerBackground(.fill.tertiary, for: .widget)
            } else {
                LockScreenTimeCircularView(entry: entry)
            }
        }
        .configurationDisplayName("Time")
        .description("Today's usage")
        .supportedFamilies([.accessoryCircular])
    }
}

// MARK: - Lock Screen Rectangular Widget Configuration

struct LockScreenRectangularWidget: Widget {
    let kind: String = "LockScreenRectangularWidget"
    
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: LessIsMoreProvider()) { entry in
            if #available(iOS 17.0, *) {
                LockScreenRectangularView(entry: entry)
                    .containerBackground(.fill.tertiary, for: .widget)
            } else {
                LockScreenRectangularView(entry: entry)
            }
        }
        .configurationDisplayName("Streak & Time")
        .description("Your streak and usage")
        .supportedFamilies([.accessoryRectangular])
    }
}

// MARK: - Lock Screen Inline Widget Configuration

struct LockScreenInlineWidget: Widget {
    let kind: String = "LockScreenInlineWidget"
    
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: LessIsMoreProvider()) { entry in
            if #available(iOS 17.0, *) {
                LockScreenInlineView(entry: entry)
                    .containerBackground(.fill.tertiary, for: .widget)
            } else {
                LockScreenInlineView(entry: entry)
            }
        }
        .configurationDisplayName("Status")
        .description("Quick status line")
        .supportedFamilies([.accessoryInline])
    }
}

// MARK: - Previews

#Preview("Circular Streak", as: .accessoryCircular) {
    LockScreenStreakWidget()
} timeline: {
    LessIsMoreEntry.placeholder
}

#Preview("Circular Time", as: .accessoryCircular) {
    LockScreenTimeWidget()
} timeline: {
    LessIsMoreEntry.placeholder
}

#Preview("Rectangular", as: .accessoryRectangular) {
    LockScreenRectangularWidget()
} timeline: {
    LessIsMoreEntry.placeholder
}

#Preview("Inline", as: .accessoryInline) {
    LockScreenInlineWidget()
} timeline: {
    LessIsMoreEntry.placeholder
}
