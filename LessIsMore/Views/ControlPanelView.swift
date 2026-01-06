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
    @Environment(\.dismiss) var dismiss
    @Environment(\.colorScheme) var colorScheme

    @State private var filterStates: [FilterType: Bool] = [:]
    @State private var showSettings = false

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
        }
        .sheet(isPresented: $showSettings) {
            SettingsView(
                webViewManager: webViewManager,
                authManager: authManager,
                subscriptionManager: subscriptionManager
            )
        }
    }

    // MARK: - Usage Header

    private var usageHeader: some View {
        VStack(alignment: .leading, spacing: 20) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("TODAY USE")
                        .font(AppFonts.caption(10))
                        .foregroundColor(.secondary)
                        .tracking(1.5)

                    HStack(alignment: .lastTextBaseline, spacing: 12) {
                        Text(usageTracker.formattedTimeShort)
                            .font(.system(size: 42, weight: .bold, design: .rounded))
                            .foregroundColor(.primary)
                        
                        // Trend Badge
                        trendBadge
                    }
                }

                Spacer()

                // Bouton Settings
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

            // Graphique hebdomadaire
            // Graphique hebdomadaire combiné
            WeeklyUsageChart(data: usageTracker.weeklyUsage)
        }
        .padding(.bottom, 10)
    }

    private var trendBadge: some View {
        let diff = usageTracker.getComparisonToYesterday()
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
    }

    // MARK: - Basic Filters Section

    private var basicFiltersSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Content")
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
            }
            .padding(.leading, 4)

            VStack(spacing: 0) {
                FilterRow(
                    title: "Hide Reels",
                    isEnabled: binding(for: .reels),
                    isLocked: !subscriptionManager.isPremium,
                    onLockedTap: showPaywall
                )

                Divider()
                    .padding(.leading, 16)

                FilterRow(
                    title: "Hide Stories",
                    isEnabled: binding(for: .stories),
                    isLocked: !subscriptionManager.isPremium,
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
                Text("Algorithm")
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
                    title: "Following only",
                    isEnabled: binding(for: .following),
                    isLocked: !subscriptionManager.isPremium,
                    onLockedTap: showPaywall
                )

                Divider()
                    .padding(.leading, 16)

                FilterRow(
                    title: "Hide Explore Feed",
                    isEnabled: binding(for: .explore),
                    isLocked: !subscriptionManager.isPremium,
                    onLockedTap: showPaywall
                )

                Divider()
                    .padding(.leading, 16)

                FilterRow(
                    title: "Hide Suggestions",
                    isEnabled: binding(for: .suggestions),
                    isLocked: !subscriptionManager.isPremium,
                    onLockedTap: showPaywall
                )

                Divider()
                    .padding(.leading, 16)

                FilterRow(
                    title: "Hide Messages Tab",
                    isEnabled: binding(for: .messages),
                    isLocked: !subscriptionManager.isPremium,
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
                Text("Style")
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
                    title: "Hide Likes",
                    isEnabled: binding(for: .likes),
                    isLocked: !subscriptionManager.isPremium,
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
                filterStates[filterType] = newValue
                filterType.setEnabled(newValue)
                webViewManager.toggleFilter(filterType)
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
    var onLockedTap: (() -> Void)?

    var body: some View {
        HStack {
            Text(title)
                .font(AppFonts.body())
                .foregroundColor(isLocked ? .secondary : .primary)

            Spacer()

            if isLocked {
                Toggle("", isOn: .constant(false))
                    .toggleStyle(SwitchToggleStyle(tint: .blue))
                    .disabled(true)
                    .scaleEffect(0.9)
                    .overlay(
                        Color.clear
                            .contentShape(Rectangle())
                            .onTapGesture {
                                onLockedTap?()
                            }
                    )
            } else {
                Toggle("", isOn: $isEnabled)
                    .toggleStyle(SwitchToggleStyle(tint: .white))
                    .scaleEffect(0.9)
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

#Preview {
    ControlPanelView(
        webViewManager: WebViewManager(),
        authManager: AuthenticationManager(),
        subscriptionManager: SubscriptionManager()
    )
}

