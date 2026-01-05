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
    @ObservedObject var subscriptionManager: SubscriptionManager
    @StateObject private var usageTracker = UsageTracker.shared
    @Environment(\.dismiss) var dismiss
    @Environment(\.colorScheme) var colorScheme

    @State private var filterStates: [FilterType: Bool] = [:]
    @State private var showSettings = false

    var body: some View {
        VStack(spacing: 0) {
            // Drag handle
            Capsule()
                .fill(Color.gray.opacity(0.5))
                .frame(width: 36, height: 5)
                .padding(.top, 10)
                .padding(.bottom, 20)

            ScrollView(showsIndicators: false) {
                VStack(spacing: 20) {
                    // Header avec temps d'utilisation
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
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.clear)
        .onAppear {
            loadFilterStates()
        }
    }

    // MARK: - Usage Header

    private var usageHeader: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 8) {
                Text("TODAY")
                    .font(AppFonts.caption())
                    .foregroundColor(.secondary)
                    .tracking(1)

                Text(usageTracker.formattedTimeShort)
                    .font(.system(size: 48, weight: .bold, design: .rounded))
                    .foregroundColor(.primary)

                // Badge Instagram
                HStack(spacing: 8) {
                    // Icône Instagram avec gradient
                    ZStack {
                        RoundedRectangle(cornerRadius: 6)
                            .fill(
                                LinearGradient(
                                    colors: [.instagramPurple, .instagramPink, .instagramOrange, .instagramYellow],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 26, height: 26)

                        Image(systemName: "camera")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(.white)
                    }

                    Text(usageTracker.formattedTimeShort)
                        .font(AppFonts.subheadline())
                        .foregroundColor(.primary)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(.regularMaterial)
                .cornerRadius(20)
            }

            Spacer()

            // Bouton Settings
            Button(action: {
                showSettings = true
            }) {
                Image(systemName: "gearshape")
                    .font(.system(size: 22))
                    .foregroundColor(.secondary)
            }
            .sheet(isPresented: $showSettings) {
                SettingsView(
                    webViewManager: webViewManager,
                    authManager: AuthenticationManager(),
                    subscriptionManager: subscriptionManager
                )
            }
        }
        .padding(.bottom, 10)
    }

    // MARK: - Basic Filters Section

    private var basicFiltersSection: some View {
        VStack(spacing: 0) {
            FilterRow(
                title: "Hide Reels",
                isEnabled: binding(for: .reels),
                isLocked: false
            )

            Divider()
                .padding(.leading, 16)

            FilterRow(
                title: "Hide Stories",
                isEnabled: binding(for: .stories),
                isLocked: false
            )
        }
        .background(.regularMaterial)
        .cornerRadius(14)
    }

    // MARK: - Algorithm Section (Premium)

    private var algorithmSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Algorithm")
                    .font(AppFonts.subheadline())
                    .foregroundColor(.secondary)

                if !subscriptionManager.isPremium {
                    Text("Super")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(.orange)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(Color.orange.opacity(0.2))
                        .cornerRadius(6)
                }
            }
            .padding(.leading, 4)

            VStack(spacing: 0) {
                FilterRow(
                    title: "Hide \"For You\" Feed",
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
            .background(.regularMaterial)
            .cornerRadius(14)
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
                    Text("Super")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(.orange)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(Color.orange.opacity(0.2))
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
            .background(.regularMaterial)
            .cornerRadius(14)
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
        subscriptionManager: SubscriptionManager()
    )
}
