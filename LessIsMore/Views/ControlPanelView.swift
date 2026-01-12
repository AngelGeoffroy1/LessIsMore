//
//  ControlPanelView.swift
//  LessIsMore
//
//  Created by Angel Geoffroy on 05/01/2026.
//

import SwiftUI
import SuperwallKit

struct ControlPanelView: View {
    @ObservedObject var webViewManager: WebViewManager
    @ObservedObject var authManager: AuthenticationManager
    @ObservedObject var subscriptionManager: SubscriptionManager
    @StateObject private var usageTracker = UsageTracker.shared
    @StateObject private var streakTracker = StreakTracker.shared
    @Environment(\.dismiss) var dismiss
    @Environment(\.colorScheme) var colorScheme

    @State private var filterStates: [FilterType: Bool] = [:]
    @State private var showSettings = false
    @State private var showSharePreview = false
    @State private var chartMode: Int = 0 // 0 = weekly (days), 1 = monthly (weeks)
    @State private var showBreakStreakModal = false
    @State private var showTimeSavedExplanation = false
    @State private var pendingFilterToDisable: FilterType? = nil

    var body: some View {
        ZStack {
            // Force Glassmorphism - Extreme transparency
            VisualEffectView(effect: UIBlurEffect(style: colorScheme == .dark ? .systemUltraThinMaterialDark : .systemUltraThinMaterialLight))
                .opacity(0.4)
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Drag handle
                Capsule()
                    .fill(Color.gray.opacity(0.5))
                    .frame(width: 36, height: 5)
                    .padding(.top, 10)
                    .padding(.bottom, 20)

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 20) {
                        // Header avec graphique
                        usageHeader

                        // Section filtres basiques
                        basicFiltersSection

                        // Section Algorithm (Premium)
                        algorithmSection

                        // Section Style (Premium)
                        styleSection

                        Spacer()
                            .frame(height: 40)
                    }
                    .padding(.horizontal, 20)
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.clear)
        .onAppear {
            loadFilterStates()
            streakTracker.syncWithFilterStates()
        }
        .overlay {
            // Break Streak Confirmation Modal
            if showBreakStreakModal, let filterType = pendingFilterToDisable {
                ZStack {
                    Color.black.opacity(0.5)
                        .ignoresSafeArea()
                        .onTapGesture {
                            // Cancel on background tap
                            showBreakStreakModal = false
                            pendingFilterToDisable = nil
                        }
                    
                    BreakStreakModal(
                        filterType: filterType,
                        currentStreak: streakTracker.getCurrentStreakDays(for: filterType),
                        personalRecord: streakTracker.getLongestStreak(for: filterType),
                        onCancel: {
                            showBreakStreakModal = false
                            pendingFilterToDisable = nil
                        },
                        onConfirm: {
                            // Actually disable the filter
                            streakTracker.deactivateStreak(for: filterType)
                            filterStates[filterType] = false
                            filterType.setEnabled(false)
                            webViewManager.toggleFilter(filterType)
                            
                            showBreakStreakModal = false
                            pendingFilterToDisable = nil
                            
                            // Haptic feedback
                            let haptic = UINotificationFeedbackGenerator()
                            haptic.notificationOccurred(.warning)
                        }
                    )
                    .transition(.scale.combined(with: .opacity))
                }
                .animation(.spring(response: 0.3, dampingFraction: 0.8), value: showBreakStreakModal)
            }
            
            // Time Saved Explanation Modal
            if showTimeSavedExplanation {
                ZStack {
                    Color.black.opacity(0.4)
                        .ignoresSafeArea()
                        .onTapGesture {
                            showTimeSavedExplanation = false
                        }
                    
                    TimeSavedExplanationModal(onDismiss: {
                        showTimeSavedExplanation = false
                    })
                }
                .transition(.opacity)
            }
        }
        .animation(.easeInOut(duration: 0.3), value: showTimeSavedExplanation)
        .sheet(isPresented: $showSettings) {
            SettingsView(
                webViewManager: webViewManager,
                authManager: authManager,
                subscriptionManager: subscriptionManager
            )
        }
        .sheet(isPresented: $showSharePreview) {
            if chartMode == 0 {
                // Weekly mode - share daily data
                ShareStatsPreviewSheet(
                    weeklyData: usageTracker.weeklyUsage,
                    todayUsage: usageTracker.formattedTimeShort,
                    percentageChange: usageTracker.getComparisonToYesterday(),
                    isMonthlyMode: false
                )
            } else {
                // Monthly mode - share weekly data
                ShareStatsPreviewSheet(
                    monthlyData: usageTracker.monthlyUsage,
                    weekUsage: usageTracker.formattedCurrentWeekTime,
                    percentageChange: usageTracker.getComparisonToLastWeek(),
                    monthName: usageTracker.currentMonthName,
                    isMonthlyMode: true
                )
            }
        }
    }

    // MARK: - Usage Header

    private var usageHeader: some View {
        VStack(alignment: .leading, spacing: 20) {
            HStack(alignment: .top) {
                // Left side: Usage stats
                VStack(alignment: .leading, spacing: 4) {
                    Text(chartMode == 0 ? "controlPanel.todayUse".localized : "controlPanel.thisWeekUse".localized)
                        .font(AppFonts.caption(10))
                        .foregroundColor(.secondary)
                        .tracking(1.5)
                        .animation(.easeInOut(duration: 0.2), value: chartMode)

                    HStack(alignment: .lastTextBaseline, spacing: 12) {
                        Text(chartMode == 0 ? usageTracker.formattedTimeShort : usageTracker.formattedCurrentWeekTime)
                            .font(.system(size: 42, weight: .bold, design: .rounded))
                            .foregroundColor(.primary)
                            .animation(.easeInOut(duration: 0.2), value: chartMode)
                        
                        // Trend Badge
                        trendBadge
                    }
                }

                Spacer()
                
                // Right side: Settings only
                Button(action: {
                    showSettings = true
                }) {
                    Image(systemName: "gearshape.fill")
                        .font(.system(size: 20))
                        .foregroundColor(.primary.opacity(0.6))
                        .padding(10)
                        .background(.ultraThinMaterial)
                        .clipShape(Circle())
                }
            }

            // Graphique carousel (hebdomadaire ↔ mensuel)
            ChartCarouselView(
                weeklyData: usageTracker.weeklyUsage,
                monthlyData: usageTracker.monthlyUsage,
                monthName: usageTracker.currentMonthName,
                currentPage: $chartMode
            )
            
            // Streak Highlight - Left aligned with personal record on right
            if let best = streakTracker.bestActiveStreak {
                HStack {
                    // Left: Current streak
                    HStack(spacing: 6) {
                        GradientFlameView(size: 16)
                        
                        Text("\(best.days)")
                            .font(AppFonts.headline(15))
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [
                                        Color(red: 1.0, green: 0.60, blue: 0.0),
                                        Color(red: 0.98, green: 0.05, blue: 0.44),
                                        Color(red: 0.73, green: 0.20, blue: 0.82)
                                    ],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                        
                        Text(best.days == 1 ? "common.day".localized : "common.days".localized)
                            .font(AppFonts.body(13))
                            .foregroundColor(.secondary)
                        
                        Text("·")
                            .font(AppFonts.body(13))
                            .foregroundColor(.secondary.opacity(0.4))
                        
                        Text(String(format: "streak.noFilter".localized, best.filterType.displayName))
                            .font(AppFonts.body(13))
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    // Right: Estimated time saved (Clickable)
                    Button(action: {
                        let haptic = UIImpactFeedbackGenerator(style: .medium)
                        haptic.impactOccurred()
                        showTimeSavedExplanation = true
                    }) {
                        HStack(spacing: 4) {
                            Image(systemName: "clock.arrow.circlepath")
                                .font(.system(size: 11))
                                .foregroundColor(.green.opacity(0.8))
                            
                            Text("~\(estimatedTimeSaved(for: best.filterType, days: best.days))")
                                .font(AppFonts.caption(12))
                                .foregroundColor(.secondary)
                            
                            Image(systemName: "info.circle")
                                .font(.system(size: 10))
                                .foregroundColor(.secondary.opacity(0.5))
                        }
                    }
                    .buttonStyle(PlainButtonStyle())
                }
                .padding(.top, 4)
            }
        }
        .padding(.bottom, 4)
    }
    
    /// Estimates time saved based on average usage per content type
    private func estimatedTimeSaved(for filterType: FilterType, days: Int) -> String {
        // Get average minutes per day for this filter type from usageTracker
        let avgMinutes: Int
        if let category = UsageTracker.usageCategory(for: filterType) {
            avgMinutes = usageTracker.averageMinutesPerDay(for: category)
        } else {
            // Fallback for types not directly trackable by category
            switch filterType {
            case .suggestions: avgMinutes = 10
            case .likes: avgMinutes = 5
            default: avgMinutes = 15
            }
        }
        
        let totalMinutes = avgMinutes * days
        
        if totalMinutes >= 60 {
            let hours = totalMinutes / 60
            let mins = totalMinutes % 60
            if mins > 0 {
                return "\(hours)h\(mins)m saved"
            }
            return "\(hours)h saved"
        }
        return "\(totalMinutes)m saved"
    }

    private var trendBadge: some View {
        // Use different comparison based on mode
        let diff = chartMode == 0 ? usageTracker.getComparisonToYesterday() : usageTracker.getComparisonToLastWeek()
        let isZero = Int(diff) == 0
        let isLower = diff < 0
        
        let color: Color = isZero ? .secondary : (isLower ? .green : .red)
        let icon = isZero ? "minus" : (isLower ? "arrow.down" : "arrow.up")
        
        return HStack(spacing: 6) {
            // Icon in a circle with "transparent" (cutout) icon
            ZStack {
                Circle()
                    .fill(color)
                    .frame(width: 18, height: 18)
                
                Image(systemName: icon)
                    .font(.system(size: 9, weight: .black))
                    .foregroundColor(.white)
                    .blendMode(.destinationOut)
            }
            .compositingGroup()
            
            Text("\(abs(Int(diff)))%")
                .font(AppFonts.body(14))
                .foregroundColor(color)
        }
        .padding(.bottom, 6)
        .animation(.easeInOut(duration: 0.2), value: chartMode)
    }

    // MARK: - Basic Filters Section

    private var basicFiltersSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("controlPanel.content".localized)
                    .font(AppFonts.subheadline())
                    .foregroundColor(.secondary)

                if !subscriptionManager.isPremium {
                    Text("controlPanel.pro".localized)
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(.white)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(
                            LinearGradient(
                                colors: [
                                    Color(red: 0.98, green: 0.05, blue: 0.44), // Rose
                                    Color(red: 0.73, green: 0.20, blue: 0.82), // Violet
                                    Color(red: 1.0, green: 0.60, blue: 0.0)    // Orange
                                ],
                                startPoint: .topTrailing,
                                endPoint: .bottomLeading
                            )
                        )
                        .cornerRadius(6)
                }
                
                Spacer()
                
                // Share Stats Button
                Button(action: {
                    let haptic = UIImpactFeedbackGenerator(style: .light)
                    haptic.impactOccurred()
                    showSharePreview = true
                }) {
                    HStack(spacing: 5) {
                        Image(systemName: "square.and.arrow.up")
                            .font(.system(size: 10, weight: .semibold))
                        
                        Text("common.share".localized)
                            .font(AppFonts.caption(11))
                    }
                    .foregroundColor(.primary.opacity(0.6))
                    .padding(.vertical, 6)
                    .padding(.horizontal, 10)
                    .background(.ultraThinMaterial)
                    .clipShape(Capsule())
                }
            }
            .padding(.leading, 4)

            VStack(spacing: 0) {
                FilterRow(
                    title: "filter.hideReels".localized,
                    isEnabled: binding(for: .reels),
                    isLocked: !subscriptionManager.isPremium,
                    streakDays: streakTracker.getCurrentStreakDays(for: .reels),
                    avgTimePerDay: usageTracker.formattedAveragePerDay(for: .reels),
                    onLockedTap: showPaywall
                )

                Divider()
                    .padding(.leading, 16)

                FilterRow(
                    title: "filter.hideStories".localized,
                    isEnabled: binding(for: .stories),
                    isLocked: !subscriptionManager.isPremium,
                    streakDays: streakTracker.getCurrentStreakDays(for: .stories),
                    avgTimePerDay: usageTracker.formattedAveragePerDay(for: .stories),
                    onLockedTap: showPaywall
                )
            }
            .background(Color.primary.opacity(0.06))
            .cornerRadius(14)
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(Color.primary.opacity(0.05), lineWidth: 0.5)
            )
        }
    }

    // MARK: - Algorithm Section (Premium)

    private var algorithmSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("controlPanel.algorithm".localized)
                    .font(AppFonts.subheadline())
                    .foregroundColor(.secondary)

                if !subscriptionManager.isPremium {
                    Text("Pro")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(.white)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(
                            LinearGradient(
                                colors: [
                                    Color(red: 0.98, green: 0.05, blue: 0.44),
                                    Color(red: 0.73, green: 0.20, blue: 0.82),
                                    Color(red: 1.0, green: 0.60, blue: 0.0)
                                ],
                                startPoint: .topTrailing,
                                endPoint: .bottomLeading
                            )
                        )
                        .cornerRadius(6)
                }
            }
            .padding(.leading, 4)

            VStack(spacing: 0) {
                FilterRow(
                    title: "filter.followingOnly".localized,
                    isEnabled: binding(for: .following),
                    isLocked: !subscriptionManager.isPremium,
                    streakDays: streakTracker.getCurrentStreakDays(for: .following),
                    avgTimePerDay: usageTracker.formattedAveragePerDay(for: .feed),
                    onLockedTap: showPaywall
                )

                Divider()
                    .padding(.leading, 16)

                FilterRow(
                    title: "filter.hideExplore".localized,
                    isEnabled: binding(for: .explore),
                    isLocked: !subscriptionManager.isPremium,
                    streakDays: streakTracker.getCurrentStreakDays(for: .explore),
                    avgTimePerDay: usageTracker.formattedAveragePerDay(for: .explore),
                    onLockedTap: showPaywall
                )

                Divider()
                    .padding(.leading, 16)

                FilterRow(
                    title: "filter.hideSuggestions".localized,
                    isEnabled: binding(for: .suggestions),
                    isLocked: !subscriptionManager.isPremium,
                    streakDays: streakTracker.getCurrentStreakDays(for: .suggestions),
                    avgTimePerDay: "10m",
                    onLockedTap: showPaywall
                )

                Divider()
                    .padding(.leading, 16)

                FilterRow(
                    title: "filter.hideMessages".localized,
                    isEnabled: binding(for: .messages),
                    isLocked: !subscriptionManager.isPremium,
                    streakDays: streakTracker.getCurrentStreakDays(for: .messages),
                    avgTimePerDay: usageTracker.formattedAveragePerDay(for: .messages),
                    onLockedTap: showPaywall
                )
            }
            .background(Color.primary.opacity(0.06))
            .cornerRadius(14)
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(Color.primary.opacity(0.05), lineWidth: 0.5)
            )
        }
    }

    // MARK: - Style Section (Premium)

    private var styleSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("controlPanel.style".localized)
                    .font(AppFonts.subheadline())
                    .foregroundColor(.secondary)

                if !subscriptionManager.isPremium {
                    Text("Pro")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(.white)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(
                            LinearGradient(
                                colors: [
                                    Color(red: 0.98, green: 0.05, blue: 0.44),
                                    Color(red: 0.73, green: 0.20, blue: 0.82),
                                    Color(red: 1.0, green: 0.60, blue: 0.0)
                                ],
                                startPoint: .topTrailing,
                                endPoint: .bottomLeading
                            )
                        )
                        .cornerRadius(6)
                }
            }
            .padding(.leading, 4)

            VStack(spacing: 0) {
                FilterRow(
                    title: "filter.hideLikes".localized,
                    isEnabled: binding(for: .likes),
                    isLocked: !subscriptionManager.isPremium,
                    streakDays: streakTracker.getCurrentStreakDays(for: .likes),
                    avgTimePerDay: "5m",
                    onLockedTap: showPaywall
                )
            }
            .background(Color.primary.opacity(0.06))
            .cornerRadius(14)
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(Color.primary.opacity(0.05), lineWidth: 0.5)
            )
        }
    }

    // MARK: - Helper Methods

    private func binding(for filterType: FilterType) -> Binding<Bool> {
        Binding(
            get: { filterStates[filterType] ?? false },
            set: { newValue in
                if newValue {
                    // Turning ON - activate streak
                    filterStates[filterType] = true
                    filterType.setEnabled(true)
                    webViewManager.toggleFilter(filterType)
                    streakTracker.activateStreak(for: filterType)
                    
                    // Light haptic
                    let haptic = UIImpactFeedbackGenerator(style: .light)
                    haptic.impactOccurred()
                } else {
                    // Turning OFF - check if there's an active streak
                    let currentStreak = streakTracker.getCurrentStreakDays(for: filterType)
                    
                    if currentStreak > 0 {
                        // Show confirmation modal
                        pendingFilterToDisable = filterType
                        showBreakStreakModal = true
                    } else {
                        // No streak, just disable
                        filterStates[filterType] = false
                        filterType.setEnabled(false)
                        webViewManager.toggleFilter(filterType)
                    }
                }
            }
        )
    }

    private func loadFilterStates() {
        for filterType in FilterType.allCases {
            filterStates[filterType] = filterType.isEnabled
        }
    }

    private func showPaywall() {
        let impactFeedback = UIImpactFeedbackGenerator(style: .light)
        impactFeedback.impactOccurred()
        Superwall.shared.register(placement: "settings_premium")
    }
}

// MARK: - Weekly Usage Chart Component

struct WeeklyUsageChart: View {
    let data: [UsageTracker.WeeklyUsageData]
    var todayUsage: String = ""
    var percentageChange: Double = 0

    private var maxUsage: Int {
        let maxVal = data.map { $0.totalSeconds }.max() ?? 3600
        return max(maxVal, 3600) // Minimum 1h pour l'échelle
    }

    private func formatSeconds(_ seconds: Int) -> String {
        let hours = seconds / 3600
        let minutes = (seconds % 3600) / 60
        if hours > 0 {
            return "\(hours)h"
        }
        return "\(minutes)m"
    }


    private var currentDayName: String {
        let calendar = Calendar.current
        let weekday = calendar.component(.weekday, from: Date())
        let dayNames = ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"]
        return dayNames[weekday - 1]
    }

    private let chartHeight: CGFloat = 110

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .bottom, spacing: 8) {
                ForEach(data) { item in
                    VStack(spacing: 8) {
                        // Stacked Bar
                        ZStack(alignment: .bottom) {
                            RoundedRectangle(cornerRadius: 4)
                                .fill(Color.primary.opacity(0.03))
                                .frame(maxWidth: .infinity)
                                .frame(height: chartHeight)

                            if item.totalSeconds == 0 {
                                // Simulation Bar when no data - Randomized for realism
                                let simulatedHeight: CGFloat = 8 + CGFloat(abs(item.day.hashValue % 15))
                                RoundedRectangle(cornerRadius: 4)
                                    .fill(Color.primary.opacity(0.08))
                                    .frame(maxWidth: .infinity)
                                    .frame(height: simulatedHeight) 
                            }

                            VStack(spacing: 0) {
                                ForEach(Array(UsageTracker.UsageCategory.allCases.reversed()), id: \.self) { category in
                                    let seconds = item.categorySeconds[category.rawValue] ?? 0
                                    if seconds > 0 && item.totalSeconds > 0 {
                                        Rectangle()
                                            .fill(category.color.opacity(item.day == currentDayName ? 1.0 : 0.4))
                                            .frame(height: CGFloat(seconds) / CGFloat(item.totalSeconds) * chartHeight)
                                    }
                                }
                            }
                            .clipShape(RoundedRectangle(cornerRadius: 4))
                        }

                        Text(item.day)
                            .font(.system(size: 9, weight: .bold))
                            .foregroundColor(item.day == currentDayName ? .primary : .secondary)
                    }
                }
            }
            .frame(height: chartHeight + 20)

            // Legend
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 15) {
                    ForEach(UsageTracker.UsageCategory.allCases, id: \.self) { category in
                        HStack(spacing: 4) {
                            Circle()
                                .fill(category.color)
                                .frame(width: 8, height: 8)
                            Text(category.rawValue)
                                .font(.system(size: 10, weight: .medium))
                                .foregroundColor(.secondary)
                        }
                    }
                }
                .padding(.horizontal, 4)
            }
        }
    }
}

// MARK: - Filter Row Component

struct FilterRow: View {
    let title: String
    @Binding var isEnabled: Bool
    var isLocked: Bool = false
    var streakDays: Int = 0
    var avgTimePerDay: String? = nil  // Estimated time saved per day
    var onLockedTap: (() -> Void)?

    var body: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 6) {
                    Text(title)
                        .font(AppFonts.body())
                        .foregroundColor(isLocked ? .secondary : .primary)
                        .lineLimit(1)
                        .allowsTightening(true)
                        .truncationMode(.tail)
                    
                    // Streak Badge (show only if enabled)
                    if !isLocked && isEnabled && streakDays > 0 {
                        StreakBadge(days: streakDays, compact: true)
                            .fixedSize()
                    }
                }
                
                // Estimated savings
                if let avgTime = avgTimePerDay {
                    HStack(spacing: 4) {
                        Image(systemName: "clock")
                            .font(.system(size: 9))
                        
                        Text("~\(avgTime)/day saved" + (isEnabled ? "" : " if activated"))
                            .font(AppFonts.caption(10))
                            .lineLimit(1)
                            .allowsTightening(true)
                    }
                    .foregroundColor(.secondary.opacity(0.6))
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .layoutPriority(1)

            if isLocked {
                Toggle("", isOn: .constant(false))
                    .labelsHidden()
                    .toggleStyle(SwitchToggleStyle(tint: .blue))
                    .disabled(true)
                    .scaleEffect(0.9)
                    .fixedSize()
                    .overlay(
                        Color.clear
                            .contentShape(Rectangle())
                            .onTapGesture {
                                onLockedTap?()
                            }
                    )
            } else {
                Toggle("", isOn: $isEnabled)
                    .labelsHidden()
                    .toggleStyle(SwitchToggleStyle(tint: .white))
                    .scaleEffect(0.9)
                    .fixedSize()
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .contentShape(Rectangle())
        .onTapGesture {
            if isLocked {
                onLockedTap?()
            }
        }
    }
}

// MARK: - Chart Carousel View (Swipeable)

struct ChartCarouselView: View {
    let weeklyData: [UsageTracker.WeeklyUsageData]
    let monthlyData: [UsageTracker.MonthlyWeekData]
    let monthName: String
    @Binding var currentPage: Int
    
    @State private var dragOffset: CGFloat = 0
    
    private let chartHeight: CGFloat = 110
    
    var body: some View {
        VStack(spacing: 12) {
            // Chart title + Page indicator
            HStack {
                Text(currentPage == 0 ? "controlPanel.thisWeek".localized : monthName)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(.secondary)
                
                Spacer()
                
                // Page indicator
                HStack(spacing: 6) {
                    Circle()
                        .fill(currentPage == 0 ? Color.primary : Color.primary.opacity(0.3))
                        .frame(width: 6, height: 6)
                    Circle()
                        .fill(currentPage == 1 ? Color.primary : Color.primary.opacity(0.3))
                        .frame(width: 6, height: 6)
                }
            }
            
            // Swipeable chart container
            GeometryReader { geometry in
                HStack(spacing: 0) {
                    // Page 0: Weekly Chart
                    WeeklyUsageChart(data: weeklyData)
                        .frame(width: geometry.size.width)
                    
                    // Page 1: Monthly Chart
                    MonthlyUsageChart(data: monthlyData)
                        .frame(width: geometry.size.width)
                }
                .offset(x: -CGFloat(currentPage) * geometry.size.width + dragOffset)
                .gesture(
                    DragGesture()
                        .onChanged { value in
                            dragOffset = value.translation.width
                        }
                        .onEnded { value in
                            let threshold = geometry.size.width * 0.25
                            let predictedEndOffset = value.predictedEndTranslation.width
                            
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                                if predictedEndOffset < -threshold && currentPage == 0 {
                                    // Swipe left -> go to monthly
                                    currentPage = 1
                                    let haptic = UIImpactFeedbackGenerator(style: .light)
                                    haptic.impactOccurred()
                                } else if predictedEndOffset > threshold && currentPage == 1 {
                                    // Swipe right -> go to weekly
                                    currentPage = 0
                                    let haptic = UIImpactFeedbackGenerator(style: .light)
                                    haptic.impactOccurred()
                                }
                                dragOffset = 0
                            }
                        }
                )
            }
            .frame(height: chartHeight + 50)
            .clipped()
        }
    }
}

// MARK: - Monthly Usage Chart Component

struct MonthlyUsageChart: View {
    let data: [UsageTracker.MonthlyWeekData]
    
    private var maxUsage: Int {
        let maxVal = data.map { $0.totalSeconds }.max() ?? 3600
        return max(maxVal, 3600) // Minimum 1h pour l'échelle
    }
    
    private func formatSeconds(_ seconds: Int) -> String {
        let hours = seconds / 3600
        let minutes = (seconds % 3600) / 60
        if hours > 0 {
            return "\(hours)h"
        }
        return "\(minutes)m"
    }
    
    private func getCurrentWeekOfMonth() -> Int {
        let calendar = Calendar.current
        return calendar.component(.weekOfMonth, from: Date())
    }
    
    private let chartHeight: CGFloat = 110
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .bottom, spacing: 8) {
                ForEach(data) { item in
                    let isCurrentWeek = item.weekNumber == getCurrentWeekOfMonth()
                    
                    VStack(spacing: 8) {
                        // Stacked Bar
                        ZStack(alignment: .bottom) {
                            RoundedRectangle(cornerRadius: 4)
                                .fill(Color.primary.opacity(0.03))
                                .frame(maxWidth: .infinity)
                                .frame(height: chartHeight)
                            
                            if item.totalSeconds == 0 {
                                // Simulation Bar when no data - Randomized for realism
                                let simulatedHeight: CGFloat = 8 + CGFloat(abs(item.weekLabel.hashValue % 15))
                                RoundedRectangle(cornerRadius: 4)
                                    .fill(Color.primary.opacity(0.08))
                                    .frame(maxWidth: .infinity)
                                    .frame(height: simulatedHeight)
                            }
                            
                            VStack(spacing: 0) {
                                ForEach(Array(UsageTracker.UsageCategory.allCases.reversed()), id: \.self) { category in
                                    let seconds = item.categorySeconds[category.rawValue] ?? 0
                                    if seconds > 0 && item.totalSeconds > 0 {
                                        Rectangle()
                                            .fill(category.color.opacity(isCurrentWeek ? 1.0 : 0.4))
                                            .frame(height: CGFloat(seconds) / CGFloat(item.totalSeconds) * chartHeight)
                                    }
                                }
                            }
                            .clipShape(RoundedRectangle(cornerRadius: 4))
                        }
                        
                        // Week label - "Wk 1", "Wk 2", etc.
                        Text("Wk \(item.weekNumber)")
                            .font(.system(size: 9, weight: .bold))
                            .foregroundColor(isCurrentWeek ? .primary : .secondary)
                    }
                }
            }
            .frame(height: chartHeight + 20)
            
            // Legend
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 15) {
                    ForEach(UsageTracker.UsageCategory.allCases, id: \.self) { category in
                        HStack(spacing: 4) {
                            Circle()
                                .fill(category.color)
                                .frame(width: 8, height: 8)
                            Text(category.rawValue)
                                .font(.system(size: 10, weight: .medium))
                                .foregroundColor(.secondary)
                        }
                    }
                }
                .padding(.horizontal, 4)
            }
        }
    }
}

#Preview {
    ControlPanelView(
        webViewManager: WebViewManager(),
        authManager: AuthenticationManager(),
        subscriptionManager: SubscriptionManager()
    )
}

