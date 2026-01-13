import SwiftUI
import SuperwallKit

struct SettingsView: View {
    @ObservedObject var webViewManager: WebViewManager
    @ObservedObject var authManager: AuthenticationManager
    @ObservedObject var subscriptionManager: SubscriptionManager
    @ObservedObject private var languageManager = LanguageManager.shared
    @Environment(\.dismiss) var dismiss
    @State private var showLogoutAlert = false
    @State private var showContactModal = false
    @State private var showAboutModal = false
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
                            Text("settings.appSettings".localized)
                                .font(.system(size: 13, weight: .bold))
                                .foregroundColor(.secondary)
                                .padding(.leading, 16)

                            VStack(spacing: 0) {
                                SettingRow(icon: "arrow.clockwise", iconColor: .blue, title: "settings.reloadInstagram".localized) {
                                    webViewManager.loadInstagram()
                                    dismiss()
                                }
                                Divider().padding(.leading, 50)
                                SettingRow(icon: "arrow.counterclockwise", iconColor: .red, title: "settings.resetFilters".localized) {
                                    resetAllFilters()
                                }
                            }
                            .background(Color.primary.opacity(0.05))
                            .cornerRadius(16)
                        }

                        // Language Section
                        VStack(alignment: .leading, spacing: 12) {
                            Text("settings.language".localized)
                                .font(.system(size: 13, weight: .bold))
                                .foregroundColor(.primary.opacity(0.6))
                                .padding(.leading, 16)

                            VStack(spacing: 0) {
                                LanguageSelectorRow(languageManager: languageManager)
                            }
                            .background(Color.primary.opacity(0.05))
                            .cornerRadius(16)
                        }

                        // Support & Info Section
                        VStack(alignment: .leading, spacing: 12) {
                            Text("settings.support".localized)
                                .font(.system(size: 13, weight: .bold))
                                .foregroundColor(.primary.opacity(0.6))
                                .padding(.leading, 16)

                            VStack(spacing: 0) {
                                SettingRow(icon: "info.circle", iconColor: .orange, title: "settings.resetOnboarding".localized) {
                                    authManager.resetOnboarding()
                                    dismiss()
                                }
                                Divider().padding(.leading, 50)
                                SettingRow(icon: "envelope", iconColor: .blue, title: "settings.contact".localized) {
                                    showContactModal = true
                                }
                                Divider().padding(.leading, 50)
                                SettingRow(icon: "doc.text", iconColor: .gray, title: "settings.aboutApp".localized) {
                                    showAboutModal = true
                                }
                            }
                            .background(Color.primary.opacity(0.05))
                            .cornerRadius(16)
                        }

                        // Account Section
                        VStack(alignment: .leading, spacing: 12) {
                            Text("settings.account".localized)
                                .font(.system(size: 13, weight: .bold))
                                .foregroundColor(.primary.opacity(0.6))
                                .padding(.leading, 16)

                            VStack(spacing: 0) {
                                SettingRow(icon: "rectangle.portrait.and.arrow.right", iconColor: .red, title: "settings.logOut".localized, showChevron: false) {
                                    showLogoutAlert = true
                                }
                            }
                            .background(Color.primary.opacity(0.05))
                            .cornerRadius(16)
                        }

                        // footer text
                        Text(String(format: "settings.version".localized, "1.0.0"))
                            .font(.system(size: 12))
                            .foregroundColor(.secondary.opacity(0.5))
                            .padding(.top, 10)
                    }
                    .padding(16)
                }
            }
        }
        .id(languageManager.currentLanguage) // Force refresh on language change
        .navigationBarHidden(true)
        .background(Color.clear)
        .alert("settings.logOut".localized, isPresented: $showLogoutAlert) {
            Button("common.cancel".localized, role: .cancel) { }
            Button("settings.logOut".localized, role: .destructive) {
                authManager.logout()
                dismiss()
            }
        } message: {
            Text("settings.logOutConfirm".localized)
        }
        .sheet(isPresented: $showContactModal) {
            ContactModal()
        }
        .sheet(isPresented: $showAboutModal) {
            AboutModal()
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

            Text("settings.title".localized)
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
            Superwall.shared.register(placement: "campaign_trigger")
        }) {
            HStack(spacing: 16) {

                VStack(alignment: .leading, spacing: 4) {
                    Text("settings.upgradeToPro".localized)
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.white)

                    Text("settings.upgradeDesc".localized)
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

// MARK: - Language Selector Row

struct LanguageSelectorRow: View {
    @ObservedObject var languageManager: LanguageManager
    
    var body: some View {
        HStack(spacing: 16) {
            // Icon
            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.blue.opacity(0.15))
                    .frame(width: 34, height: 34)
                
                Image(systemName: "globe")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.blue)
            }
            
            // Current language name
            Text(languageManager.availableLanguages.first { $0.code == languageManager.currentLanguage }?.name ?? "")
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.primary)
            
            Spacer()
            
            // Language Picker (dropdown menu)
            Menu {
                ForEach(languageManager.availableLanguages, id: \.code) { lang in
                    Button(action: {
                        languageManager.setLanguage(lang.code)
                    }) {
                        HStack {
                            Text(lang.name)
                            if lang.code == languageManager.currentLanguage {
                                Image(systemName: "checkmark")
                            }
                        }
                    }
                }
            } label: {
                Image(systemName: "chevron.up.chevron.down")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(.secondary.opacity(0.5))
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
    }
}

// MARK: - Contact Modal

struct ContactModal: View {
    @Environment(\.dismiss) var dismiss
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        ZStack {
            // Translucent background
            VisualEffectView(effect: UIBlurEffect(style: colorScheme == .dark ? .systemUltraThinMaterialDark : .systemUltraThinMaterialLight))
                .ignoresSafeArea()
            
            VStack(spacing: 24) {
                // Drag indicator
                RoundedRectangle(cornerRadius: 3)
                    .fill(Color.secondary.opacity(0.4))
                    .frame(width: 40, height: 5)
                    .padding(.top, 12)
                
                Spacer()
                
                // Icon
                ZStack {
                    Circle()
                        .fill(Color.blue.opacity(0.15))
                        .frame(width: 80, height: 80)
                    
                    Image(systemName: "envelope.fill")
                        .font(.system(size: 36))
                        .foregroundColor(.blue)
                }
                
                // Title
                Text("settings.contactTitle".localized)
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(.primary)
                    .fixedSize(horizontal: false, vertical: true)
                
                // Description
                Text("settings.contactDescription".localized)
                    .font(.system(size: 16))
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.horizontal, 40)
                
                // Email card with copy button
                HStack(spacing: 12) {
                    Text("angelgeoffroy@outlook.fr")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.primary)
                    
                    Button(action: {
                        UIPasteboard.general.string = "angelgeoffroy@outlook.fr"
                    }) {
                        Image(systemName: "doc.on.doc")
                            .font(.system(size: 16))
                            .foregroundColor(.blue)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 16)
                .background(Color.primary.opacity(0.05))
                .cornerRadius(16)
                
                Spacer()
            }
        }
        .presentationDetents([.medium])
    }
}

// MARK: - About Modal

struct AboutModal: View {
    @Environment(\.dismiss) var dismiss
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        ZStack {
            // Translucent background
            VisualEffectView(effect: UIBlurEffect(style: colorScheme == .dark ? .systemUltraThinMaterialDark : .systemUltraThinMaterialLight))
                .ignoresSafeArea()
            
            VStack(spacing: 24) {
                // Drag indicator
                RoundedRectangle(cornerRadius: 3)
                    .fill(Color.secondary.opacity(0.4))
                    .frame(width: 40, height: 5)
                    .padding(.top, 12)
                
                Spacer()
                
                // Mascot
                Image("mascott bonjour")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 120, height: 120)
                
                // App Name
                Text("LessIsMore")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundColor(.primary)
                    .fixedSize(horizontal: false, vertical: true)
                
                // Version
                Text(String(format: "settings.version".localized, "1.0.0"))
                    .font(.system(size: 14))
                    .foregroundColor(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
                
                // Description
                Text("settings.aboutDescription".localized)
                    .font(.system(size: 16))
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.horizontal, 40)
                
                Spacer()
                
                // Footer
                Text("settings.madeWith".localized)
                    .font(.system(size: 14))
                    .foregroundColor(.secondary.opacity(0.7))
                    .padding(.bottom, 30)
            }
        }
        .presentationDetents([.medium])
    }
}
