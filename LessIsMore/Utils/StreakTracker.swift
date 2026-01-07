//
//  StreakTracker.swift
//  LessIsMore
//
//  Created by Angel Geoffroy on 07/01/2026.
//

import Foundation
import Combine
import SwiftUI

/// Tracks filter usage streaks (consecutive days with a filter enabled)
class StreakTracker: ObservableObject {
    static let shared = StreakTracker()
    
    // MARK: - Data Structures
    
    struct FilterStreak: Codable, Identifiable {
        var id: String { filterType }
        let filterType: String           // "reels", "stories", etc.
        var startDate: Date?             // Date when filter was activated (nil if inactive)
        var isActive: Bool               // Filter currently enabled
        var longestStreak: Int           // Personal record in days
        
        /// Current streak in days (0 if inactive)
        var currentStreak: Int {
            guard isActive, let start = startDate else { return 0 }
            let calendar = Calendar.current
            let days = calendar.dateComponents([.day], from: calendar.startOfDay(for: start), to: calendar.startOfDay(for: Date())).day ?? 0
            return max(0, days) + 1 // +1 because the first day counts
        }
        
        init(filterType: String) {
            self.filterType = filterType
            self.startDate = nil
            self.isActive = false
            self.longestStreak = 0
        }
    }
    
    // MARK: - Published Properties
    
    @Published var streaks: [String: FilterStreak] = [:]
    
    // MARK: - Private Properties
    
    private let userDefaults = UserDefaults.standard
    private let streaksKey = "filter_streaks_data"
    
    // MARK: - Initialization
    
    private init() {
        loadStreaks()
        initializeMissingStreaks()
    }
    
    // MARK: - Public Methods
    
    /// Get streak for a specific filter type
    func getStreak(for filterType: FilterType) -> FilterStreak {
        return streaks[filterType.rawValue] ?? FilterStreak(filterType: filterType.rawValue)
    }
    
    /// Get current streak days for a filter
    func getCurrentStreakDays(for filterType: FilterType) -> Int {
        return getStreak(for: filterType).currentStreak
    }
    
    /// Get personal record for a filter
    func getLongestStreak(for filterType: FilterType) -> Int {
        return getStreak(for: filterType).longestStreak
    }
    
    /// Check if a filter has an active streak (> 0 days)
    func hasActiveStreak(for filterType: FilterType) -> Bool {
        return getCurrentStreakDays(for: filterType) > 0
    }
    
    /// Activate a filter streak (called when filter is turned ON)
    func activateStreak(for filterType: FilterType) {
        var streak = getStreak(for: filterType)
        
        // Only set start date if not already active
        if !streak.isActive {
            streak.startDate = Date()
            streak.isActive = true
        }
        
        streaks[filterType.rawValue] = streak
        saveStreaks()
    }
    
    /// Deactivate a filter streak (called when filter is turned OFF)
    /// Returns the streak that was lost (for display in modal)
    @discardableResult
    func deactivateStreak(for filterType: FilterType) -> Int {
        var streak = getStreak(for: filterType)
        let lostStreak = streak.currentStreak
        
        // Update personal record if current streak was higher
        if lostStreak > streak.longestStreak {
            streak.longestStreak = lostStreak
        }
        
        // Reset streak
        streak.startDate = nil
        streak.isActive = false
        
        streaks[filterType.rawValue] = streak
        saveStreaks()
        
        return lostStreak
    }
    
    /// Sync streak state with actual filter state (call on app launch)
    func syncWithFilterStates() {
        for filterType in FilterType.allCases {
            let isFilterEnabled = filterType.isEnabled
            var streak = getStreak(for: filterType)
            
            if isFilterEnabled && !streak.isActive {
                // Filter was enabled outside of streak tracking
                activateStreak(for: filterType)
            } else if !isFilterEnabled && streak.isActive {
                // Filter was disabled outside of streak tracking
                deactivateStreak(for: filterType)
            }
        }
    }
    
    /// Get the best active streak across all filters
    var bestActiveStreak: (filterType: FilterType, days: Int)? {
        var best: (FilterType, Int)? = nil
        
        for filterType in FilterType.allCases {
            let days = getCurrentStreakDays(for: filterType)
            if days > 0 {
                if best == nil || days > best!.1 {
                    best = (filterType, days)
                }
            }
        }
        
        return best
    }
    
    /// Get all active streaks sorted by days (descending)
    var allActiveStreaks: [(filterType: FilterType, days: Int)] {
        return FilterType.allCases
            .map { ($0, getCurrentStreakDays(for: $0)) }
            .filter { $0.1 > 0 }
            .sorted { $0.1 > $1.1 }
    }
    
    // MARK: - Private Methods
    
    private func loadStreaks() {
        guard let data = userDefaults.data(forKey: streaksKey),
              let decoded = try? JSONDecoder().decode([String: FilterStreak].self, from: data) else {
            return
        }
        streaks = decoded
    }
    
    private func saveStreaks() {
        if let encoded = try? JSONEncoder().encode(streaks) {
            userDefaults.set(encoded, forKey: streaksKey)
        }
    }
    
    private func initializeMissingStreaks() {
        for filterType in FilterType.allCases {
            if streaks[filterType.rawValue] == nil {
                streaks[filterType.rawValue] = FilterStreak(filterType: filterType.rawValue)
            }
        }
        saveStreaks()
    }
}

// MARK: - Instagram Gradient Flame View

struct GradientFlameView: View {
    var size: CGFloat = 14
    
    // Instagram gradient colors
    private let instagramGradient = LinearGradient(
        colors: [
            Color(red: 1.0, green: 0.60, blue: 0.0),    // Orange
            Color(red: 0.98, green: 0.05, blue: 0.44),  // Rose/Pink
            Color(red: 0.73, green: 0.20, blue: 0.82)   // Purple
        ],
        startPoint: .bottom,
        endPoint: .top
    )
    
    var body: some View {
        Text("🔥")
            .font(.system(size: size))
            .overlay(
                instagramGradient
                    .mask(
                        Text("🔥")
                            .font(.system(size: size))
                    )
            )
    }
}

// MARK: - Streak Badge Component

struct StreakBadge: View {
    let days: Int
    var compact: Bool = true
    
    private let instagramGradient = LinearGradient(
        colors: [
            Color(red: 1.0, green: 0.60, blue: 0.0),    // Orange
            Color(red: 0.98, green: 0.05, blue: 0.44),  // Rose/Pink
            Color(red: 0.73, green: 0.20, blue: 0.82)   // Purple
        ],
        startPoint: .leading,
        endPoint: .trailing
    )
    
    var body: some View {
        if days > 0 {
            HStack(spacing: 2) {
                GradientFlameView(size: compact ? 12 : 16)
                
                Text("\(days)")
                    .font(.system(size: compact ? 11 : 14, weight: .bold, design: .rounded))
                    .foregroundStyle(instagramGradient)
            }
            .padding(.horizontal, compact ? 6 : 8)
            .padding(.vertical, compact ? 3 : 5)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.primary.opacity(0.05))
            )
        }
    }
}

// MARK: - Streak Highlight Header Component

struct StreakHighlightView: View {
    @ObservedObject var streakTracker: StreakTracker
    
    private let instagramGradient = LinearGradient(
        colors: [
            Color(red: 1.0, green: 0.60, blue: 0.0),    // Orange
            Color(red: 0.98, green: 0.05, blue: 0.44),  // Rose/Pink
            Color(red: 0.73, green: 0.20, blue: 0.82)   // Purple
        ],
        startPoint: .leading,
        endPoint: .trailing
    )
    
    var body: some View {
        if let best = streakTracker.bestActiveStreak {
            VStack(alignment: .leading, spacing: 4) {
                Text("BEST STREAK")
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(.secondary)
                    .tracking(1.5)
                
                HStack(alignment: .lastTextBaseline, spacing: 6) {
                    GradientFlameView(size: 24)
                    
                    Text("\(best.days)")
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                        .foregroundStyle(instagramGradient)
                    
                    Text(best.days == 1 ? "day" : "days")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.secondary)
                }
                
                Text("without \(best.filterType.displayName)")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(.secondary)
            }
        }
    }
}

// MARK: - Break Streak Confirmation Modal

struct BreakStreakModal: View {
    let filterType: FilterType
    let currentStreak: Int
    let personalRecord: Int
    let onCancel: () -> Void
    let onConfirm: () -> Void
    
    @Environment(\.colorScheme) var colorScheme
    @State private var appeared = false
    
    private let instagramGradient = LinearGradient(
        colors: [
            Color(red: 1.0, green: 0.60, blue: 0.0),    // Orange
            Color(red: 0.98, green: 0.05, blue: 0.44),  // Rose/Pink
            Color(red: 0.73, green: 0.20, blue: 0.82)   // Purple
        ],
        startPoint: .leading,
        endPoint: .trailing
    )
    
    var body: some View {
        VStack(spacing: 24) {
            // Warning Icon
            ZStack {
                Circle()
                    .fill(instagramGradient.opacity(0.15))
                    .frame(width: 80, height: 80)
                
                GradientFlameView(size: 40)
            }
            
            // Title
            VStack(spacing: 8) {
                Text("Break Your Streak?")
                    .font(AppFonts.title3(22))
                    .foregroundColor(.primary)
                
                Text("You've been \(filterType.displayName)-free for")
                    .font(AppFonts.subheadline(15))
                    .foregroundColor(.secondary)
                
                HStack(spacing: 4) {
                    Text("\(currentStreak)")
                        .font(AppFonts.title(32))
                        .foregroundStyle(instagramGradient)
                    
                    Text(currentStreak == 1 ? "day" : "days")
                        .font(AppFonts.body(18))
                        .foregroundColor(.secondary)
                }
            }
            
            // Buttons
            VStack(spacing: 12) {
                // Keep Streak Button (Primary)
                Button(action: onCancel) {
                    HStack {
                        GradientFlameView(size: 16)
                        Text("Keep My Streak")
                            .font(AppFonts.headline(16))
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(instagramGradient)
                    .cornerRadius(14)
                }
                
                // Break Streak Button (Secondary) - No background
                Button(action: onConfirm) {
                    Text("Disable & Reset")
                        .font(AppFonts.subheadline(15))
                        .foregroundColor(.secondary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                }
            }
        }
        .padding(24)
        .background(
            ZStack {
                // Glassmorphism background - less translucent
                VisualEffectView(effect: UIBlurEffect(style: colorScheme == .dark ? .systemMaterialDark : .systemMaterialLight))
                    .opacity(0.85)
            }
        )
        .clipShape(RoundedRectangle(cornerRadius: 24))
        .overlay(
            RoundedRectangle(cornerRadius: 24)
                .stroke(Color.primary.opacity(0.1), lineWidth: 0.5)
        )
        .padding(.horizontal, 24)
        .scaleEffect(appeared ? 1 : 0.85)
        .opacity(appeared ? 1 : 0)
        .onAppear {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.75)) {
                appeared = true
            }
        }
    }
}

#Preview {
    VStack(spacing: 30) {
        StreakBadge(days: 7)
        StreakBadge(days: 15, compact: false)
        GradientFlameView(size: 30)
        
        BreakStreakModal(
            filterType: .reels,
            currentStreak: 7,
            personalRecord: 12,
            onCancel: {},
            onConfirm: {}
        )
    }
    .padding()
    .background(Color.gray.opacity(0.1))
}

// MARK: - Time Saved Explanation Modal

struct TimeSavedExplanationModal: View {
    let onDismiss: () -> Void
    @Environment(\.colorScheme) var colorScheme
    @State private var appeared = false
    
    var body: some View {
        VStack(spacing: 24) {
            // Icon
            ZStack {
                Circle()
                    .fill(Color.green.opacity(0.1))
                    .frame(width: 70, height: 70)
                
                Image(systemName: "clock.arrow.circlepath")
                    .font(.system(size: 30))
                    .foregroundColor(.green)
            }
            
            // Text Content
            VStack(spacing: 12) {
                Text("How it's calculated")
                    .font(AppFonts.title3(20))
                    .foregroundColor(.primary)
                
                VStack(spacing: 16) {
                    ExplanationRow(
                        icon: "chart.bar.xaxis",
                        title: "We analyze your usage",
                        description: "We look at your average daily time spent on each category (Reels, Stories, etc.) over the last 7 days."
                    )
                    
                    ExplanationRow(
                        icon: "flame.fill",
                        title: "We track your progress",
                        description: "We multiply your active streak days by your personal average daily usage."
                    )
                    
                    ExplanationRow(
                        icon: "sparkles",
                        title: "Real reclaimed time",
                        description: "This represents the actual time you've won back for yourself by keeping your filters active."
                    )
                }
            }
            
            // Dismiss Button
            Button(action: onDismiss) {
                Text("Got it")
                    .font(AppFonts.headline(16))
                    .foregroundColor(colorScheme == .dark ? .black : .white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(Color.primary)
                    .cornerRadius(14)
            }
        }
        .padding(28)
        .background(
            ZStack {
                VisualEffectView(effect: UIBlurEffect(style: colorScheme == .dark ? .systemMaterialDark : .systemMaterialLight))
                    .opacity(0.9)
            }
        )
        .clipShape(RoundedRectangle(cornerRadius: 24))
        .overlay(
            RoundedRectangle(cornerRadius: 24)
                .stroke(Color.primary.opacity(0.1), lineWidth: 0.5)
        )
        .padding(.horizontal, 24)
        .scaleEffect(appeared ? 1 : 0.9)
        .opacity(appeared ? 1 : 0)
        .onAppear {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.75)) {
                appeared = true
            }
        }
    }
}

private struct ExplanationRow: View {
    let icon: String
    let title: String
    let description: String
    
    var body: some View {
        HStack(alignment: .top, spacing: 14) {
            Image(systemName: icon)
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(.primary.opacity(0.7))
                .frame(width: 24, height: 24)
                .background(Color.primary.opacity(0.05))
                .clipShape(Circle())
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(AppFonts.subheadline(14).bold())
                    .foregroundColor(.primary)
                
                Text(description)
                    .font(AppFonts.footnote(12))
                    .foregroundColor(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }
}
