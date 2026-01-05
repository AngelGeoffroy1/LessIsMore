//
//  SettingsView.swift
//  LessIsMore
//
//  Created by Angel Geoffroy on 03/09/2025.
//

import SwiftUI
import SuperwallKit

struct SettingsView: View {
    @ObservedObject var webViewManager: WebViewManager
    @ObservedObject var authManager: AuthenticationManager
    @ObservedObject var subscriptionManager: SubscriptionManager
    @Environment(\.presentationMode) var presentationMode
    @State private var showLogoutAlert = false
    @State private var scrollOffset: CGFloat = 0

    private var headerOpacity: Double {
        let threshold: CGFloat = 100
        return max(0, min(1, 1 - (scrollOffset / threshold)))
    }

    private var headerOffset: CGFloat {
        return min(0, -scrollOffset * 0.5)
    }

    var body: some View {
        NavigationView {
            ZStack(alignment: .top) {
                // Fond translucide
                Color.clear
                    .background(.ultraThinMaterial)
                    .ignoresSafeArea()

                GeometryReader { geometry in
                    ScrollView {
                        VStack(spacing: 0) {
                            // En-tête animé
                            VStack(spacing: 16) {
                                Image(systemName: "shield.checkerboard")
                                    .font(.system(size: 50))
                                    .foregroundColor(.blue)

                                Text("LessIsMore")
                                    .font(AppFonts.title())

                                Text("Control your Instagram experience")
                                    .font(AppFonts.subheadline())
                                    .foregroundColor(.secondary)
                                    .multilineTextAlignment(.center)
                            }
                            .padding(.top, 30)
                            .padding(.horizontal)
                            .opacity(headerOpacity)
                            .offset(y: headerOffset)

                            // Contenu
                            LazyVStack(spacing: 16) {
                                // Section des actions
                                VStack(spacing: 12) {
                                    Button(action: {
                                        webViewManager.loadInstagram()
                                    }) {
                                        HStack {
                                            Image(systemName: "arrow.clockwise")
                                            Text("Reload Instagram")
                                            Spacer()
                                        }
                                        .padding()
                                        .background(Color.blue.opacity(0.1))
                                        .foregroundColor(.blue)
                                        .cornerRadius(10)
                                    }

                                    Button(action: {
                                        resetAllFilters()
                                    }) {
                                        HStack {
                                            Image(systemName: "arrow.counterclockwise")
                                            Text("Reset Filters")
                                            Spacer()
                                        }
                                        .padding()
                                        .background(Color.red.opacity(0.1))
                                        .foregroundColor(.red)
                                        .cornerRadius(10)
                                    }

                                    Button(action: {
                                        resetOnboarding()
                                    }) {
                                        HStack {
                                            Image(systemName: "info.circle")
                                            Text("Reset Onboarding")
                                            Spacer()
                                        }
                                        .padding()
                                        .background(Color.orange.opacity(0.1))
                                        .foregroundColor(.orange)
                                        .cornerRadius(10)
                                    }
                                    .buttonStyle(PlainButtonStyle())

                                    Button(action: {
                                        showLogoutAlert = true
                                    }) {
                                        HStack {
                                            Image(systemName: "rectangle.portrait.and.arrow.right")
                                            Text("Log Out")
                                            Spacer()
                                        }
                                        .padding()
                                        .background(Color.red.opacity(0.1))
                                        .foregroundColor(.red)
                                        .cornerRadius(10)
                                    }
                                    .buttonStyle(PlainButtonStyle())
                                }
                                .padding(.vertical, 16)
                                .padding(.horizontal, 16)
                                .background(Color(.systemGray6).opacity(0.5))
                                .cornerRadius(12)

                                // Section à propos
                                VStack(alignment: .leading, spacing: 8) {
                                    Text("About")
                                        .font(AppFonts.headline())

                                    Text("LessIsMore helps you use Instagram more mindfully by hiding sources of distraction.")
                                        .font(AppFonts.caption())
                                        .foregroundColor(.secondary)

                                    Text("• Reels: Hides access to short videos")
                                        .font(AppFonts.caption2())
                                        .foregroundColor(.secondary)

                                    Text("• Explore: Hides the discovery page")
                                        .font(AppFonts.caption2())
                                        .foregroundColor(.secondary)

                                    Text("• Stories: Hides stories at the top of the feed")
                                        .font(AppFonts.caption2())
                                        .foregroundColor(.secondary)

                                    Text("• Likes: Hides like counters on posts")
                                        .font(AppFonts.caption2())
                                        .foregroundColor(.secondary)

                                    Text("• Following: Forces Following-only mode")
                                        .font(AppFonts.caption2())
                                        .foregroundColor(.secondary)

                                    Text("• Suggestions: Hides account suggestions")
                                        .font(AppFonts.caption2())
                                        .foregroundColor(.secondary)

                                    Text("• Messages: Hides the Messages tab in navigation")
                                        .font(AppFonts.caption2())
                                        .foregroundColor(.secondary)
                                }
                                .padding(.vertical, 16)
                                .padding(.horizontal, 16)
                                .background(Color(.systemGray6).opacity(0.5))
                                .cornerRadius(12)
                                .padding(.bottom, 40)
                            }
                            .padding(.horizontal)
                            .padding(.top, 30)
                        }
                        .background(
                            GeometryReader { scrollGeometry in
                                Color.clear.preference(
                                    key: ViewOffsetKey.self,
                                    value: scrollGeometry.frame(in: .named("scroll")).minY
                                )
                            }
                        )
                    }
                    .coordinateSpace(name: "scroll")
                    .onPreferenceChange(ViewOffsetKey.self) { value in
                        scrollOffset = -value
                    }
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(
                trailing: Button("Close") {
                    presentationMode.wrappedValue.dismiss()
                }
            )
        }
        .navigationViewStyle(StackNavigationViewStyle())
        .alert("Log Out", isPresented: $showLogoutAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Log Out", role: .destructive) {
                logout()
            }
        } message: {
            Text("Are you sure you want to log out? You will need to log back in to use the app.")
        }
    }

    private func resetAllFilters() {
        for filterType in FilterType.allCases {
            filterType.setEnabled(false)
        }
        webViewManager.applyAllSavedFilters()
    }

    private func resetOnboarding() {
        authManager.resetOnboarding()
        presentationMode.wrappedValue.dismiss()
    }

    private func logout() {
        authManager.logout()
        presentationMode.wrappedValue.dismiss()
    }
}

struct ViewOffsetKey: PreferenceKey {
    typealias Value = CGFloat
    static var defaultValue = CGFloat.zero
    static func reduce(value: inout Value, nextValue: () -> Value) {
        value += nextValue()
    }
}

#Preview {
    SettingsView(webViewManager: WebViewManager(), authManager: AuthenticationManager(), subscriptionManager: SubscriptionManager())
}
