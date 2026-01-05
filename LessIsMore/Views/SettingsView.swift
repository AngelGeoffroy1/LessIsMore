import SwiftUI
import SuperwallKit

struct SettingsView: View {
    @ObservedObject var webViewManager: WebViewManager
    @ObservedObject var authManager: AuthenticationManager
    @ObservedObject var subscriptionManager: SubscriptionManager
    @Environment(\.dismiss) var dismiss
    @State private var showLogoutAlert = false
    @Environment(\.colorScheme) var colorScheme

    var body: some View {
        ZStack {
            // Translucent glassmorphism background
            VisualEffectView(effect: UIBlurEffect(style: colorScheme == .dark ? .systemUltraThinMaterialDark : .systemUltraThinMaterialLight))
                .opacity(0.4)
                .ignoresSafeArea()

            VStack(spacing: 0) {
                // Custom Header
                headerView

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 24) {
                        // Premium Card
                        if !subscriptionManager.isPremium {
                            premiumCard
                        }

                        // App Settings Section
                        VStack(alignment: .leading, spacing: 12) {
                            Text("APP SETTINGS")
                                .font(.system(size: 13, weight: .bold))
                                .foregroundColor(.secondary)
                                .padding(.leading, 16)

                            VStack(spacing: 0) {
                                SettingRow(icon: "arrow.clockwise", iconColor: .blue, title: "Reload Instagram") {
                                    webViewManager.loadInstagram()
                                    dismiss()
                                }
                                Divider().padding(.leading, 50)
                                SettingRow(icon: "arrow.counterclockwise", iconColor: .red, title: "Reset All Filters") {
                                    resetAllFilters()
                                }
                            }
                            .background(Color.primary.opacity(0.05))
                            .cornerRadius(16)
                        }

                        // Support & Info Section
                        VStack(alignment: .leading, spacing: 12) {
                            Text("SUPPORT")
                                .font(.system(size: 13, weight: .bold))
                                .foregroundColor(.primary.opacity(0.6))
                                .padding(.leading, 16)

                            VStack(spacing: 0) {
                                SettingRow(icon: "info.circle", iconColor: .orange, title: "Reset Onboarding") {
                                    authManager.resetOnboarding()
                                    dismiss()
                                }
                                Divider().padding(.leading, 50)
                                SettingRow(icon: "doc.text", iconColor: .gray, title: "About LessIsMore") {
                                    // Could open a detail view or website
                                }
                            }
                            .background(Color.primary.opacity(0.05))
                            .cornerRadius(16)
                        }

                        // Account Section
                        VStack(alignment: .leading, spacing: 12) {
                            Text("ACCOUNT")
                                .font(.system(size: 13, weight: .bold))
                                .foregroundColor(.primary.opacity(0.6))
                                .padding(.leading, 16)

                            VStack(spacing: 0) {
                                SettingRow(icon: "rectangle.portrait.and.arrow.right", iconColor: .red, title: "Log Out", showChevron: false) {
                                    showLogoutAlert = true
                                }
                            }
                            .background(Color.primary.opacity(0.05))
                            .cornerRadius(16)
                        }

                        // footer text
                        Text("Version 1.0.0")
                            .font(.system(size: 12))
                            .foregroundColor(.secondary.opacity(0.5))
                            .padding(.top, 10)
                    }
                    .padding(16)
                }
            }
        }
        .navigationBarHidden(true)
        .background(Color.clear)
        .alert("Log Out", isPresented: $showLogoutAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Log Out", role: .destructive) {
                authManager.logout()
                dismiss()
            }
        } message: {
            Text("Are you sure you want to log out? You will need to log back in to use the app.")
        }
    }

    // MARK: - Components

    private var headerView: some View {
        HStack {
            Button(action: { dismiss() }) {
                Image(systemName: "chevron.left")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.white)
                    .frame(width: 40, height: 40)
                    .background(Circle().fill(Color.white.opacity(0.1)))
            }

            Spacer()

            Text("Settings")
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(.white)

            Spacer()

            // Balance the header
            Spacer().frame(width: 40)
        }
        .padding(.horizontal, 16)
        .padding(.top, 20)
        .padding(.bottom, 10)
    }

    private var premiumCard: some View {
        Button(action: {
            Superwall.shared.register(placement: "settings_premium")
        }) {
            HStack(spacing: 16) {

                VStack(alignment: .leading, spacing: 4) {
                    Text("Upgrade to Pro")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.white)

                    Text("Unlock all features and detailed statistics.")
                        .font(.system(size: 13))
                        .foregroundColor(.white.opacity(0.8))
                        .multilineTextAlignment(.leading)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(.white.opacity(0.5))
            }
            .padding(20)
            .background(
                LinearGradient(
                    colors: [
                        Color(red: 0.98, green: 0.05, blue: 0.44), // Rose
                        Color(red: 0.73, green: 0.20, blue: 0.82), // Violet
                        Color(red: 1.0, green: 0.60, blue: 0.0)    // Orange
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .cornerRadius(24)
        }
    }

    private func resetAllFilters() {
        for filterType in FilterType.allCases {
            filterType.setEnabled(false)
        }
        webViewManager.applyAllSavedFilters()
        dismiss()
    }
}

struct SettingRow: View {
    let icon: String
    let iconColor: Color
    let title: String
    var subTitle: String? = nil
    var showChevron: Bool = true
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                // Icon
                ZStack {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(iconColor.opacity(0.15))
                        .frame(width: 34, height: 34)
                    
                    Image(systemName: icon)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(iconColor)
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.primary)
                    
                    if let sub = subTitle {
                        Text(sub)
                            .font(.system(size: 12))
                            .foregroundColor(.secondary)
                    }
                }

                Spacer()

                if showChevron {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(.secondary.opacity(0.5))
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .contentShape(Rectangle())
        }
    }
}

#Preview {
    SettingsView(
        webViewManager: WebViewManager(),
        authManager: AuthenticationManager(),
        subscriptionManager: SubscriptionManager()
    )
    .preferredColorScheme(.dark)
}

