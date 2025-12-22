//
//  SettingsView.swift
//  LessIsMore
//
//  Created by Angel Geoffroy on 03/09/2025.
//

import SwiftUI

struct SettingsView: View {
    @ObservedObject var webViewManager: WebViewManager
    @ObservedObject var authManager: AuthenticationManager
    @ObservedObject var subscriptionManager: SubscriptionManager
    @Environment(\.presentationMode) var presentationMode
    @State private var showLogoutAlert = false

    @State private var filterStates: [FilterType: Bool] = [:]
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

                                Text("Contrôlez votre expérience Instagram")
                                    .font(AppFonts.subheadline())
                                    .foregroundColor(.secondary)
                                    .multilineTextAlignment(.center)
                            }
                            .padding(.top, 30)
                            .padding(.horizontal)
                            .opacity(headerOpacity)
                            .offset(y: headerOffset)
                            
                            // Contenu des filtres
                            LazyVStack(spacing: 16) {
                                // Section des filtres
                                VStack(alignment: .leading, spacing: 12) {
                                    HStack {
                                        Text("Filtres de Contenu")
                                            .font(AppFonts.headline())

                                        if !subscriptionManager.isPremium {
                                            Image(systemName: "crown.fill")
                                                .foregroundColor(.orange)
                                                .font(.caption)
                                        }
                                    }
                                    .padding(.horizontal, 4)

                                    if !subscriptionManager.isPremium {
                                        HStack {
                                            Image(systemName: "lock.fill")
                                                .foregroundColor(.orange)
                                            Text("Devenez Premium pour débloquer tous les filtres")
                                                .font(AppFonts.caption())
                                                .foregroundColor(.secondary)
                                            Spacer()
                                            Button(action: {
                                                subscriptionManager.showPaywall()
                                            }) {
                                                Text("Premium")
                                                    .font(AppFonts.caption())
                                                    .foregroundColor(.white)
                                                    .padding(.horizontal, 12)
                                                    .padding(.vertical, 6)
                                                    .background(Color.orange)
                                                    .cornerRadius(8)
                                            }
                                        }
                                        .padding(.horizontal, 4)
                                        .padding(.vertical, 8)
                                        .background(Color.orange.opacity(0.1))
                                        .cornerRadius(8)
                                    }

                                    ForEach(FilterType.allCases, id: \.rawValue) { filterType in
                                        FilterToggleRow(
                                            filterType: filterType,
                                            isEnabled: Binding(
                                                get: { filterStates[filterType] ?? false },
                                                set: { newValue in
                                                    filterStates[filterType] = newValue
                                                    filterType.setEnabled(newValue)
                                                    webViewManager.toggleFilter(filterType)
                                                }
                                            ),
                                            isDisabled: !subscriptionManager.isPremium
                                        )
                                    }
                                }
                                .padding(.vertical, 16)
                                .padding(.horizontal, 16)
                                .background(Color(.systemGray6).opacity(0.5))
                                .cornerRadius(12)
                                
                                // Section des actions
                                VStack(spacing: 12) {
                                    Button(action: {
                                        webViewManager.loadInstagram()
                                    }) {
                                        HStack {
                                            Image(systemName: "arrow.clockwise")
                                            Text("Recharger Instagram")
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
                                            Text("Réinitialiser les filtres")
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
                                            Text("Reset le onboarding")
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
                                            Text("Se déconnecter")
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
                                    Text("À propos")
                                        .font(AppFonts.headline())

                                    Text("LessIsMore vous aide à utiliser Instagram de manière plus focalisée en masquant les sources de distraction.")
                                        .font(AppFonts.caption())
                                        .foregroundColor(.secondary)

                                    Text("• Reels : Masque l'accès aux vidéos courtes")
                                        .font(AppFonts.caption2())
                                        .foregroundColor(.secondary)

                                    Text("• Explorer : Masque la page de découverte")
                                        .font(AppFonts.caption2())
                                        .foregroundColor(.secondary)

                                    Text("• Stories : Masque les stories en haut du feed")
                                        .font(AppFonts.caption2())
                                        .foregroundColor(.secondary)

                                    Text("• Likes : Masque les compteurs de likes sur les posts")
                                        .font(AppFonts.caption2())
                                        .foregroundColor(.secondary)

                                    Text("• Following : Force le mode Following uniquement")
                                        .font(AppFonts.caption2())
                                        .foregroundColor(.secondary)

                                    Text("• Suggestions : Masque les suggestions de comptes")
                                        .font(AppFonts.caption2())
                                        .foregroundColor(.secondary)

                                    Text("• Messages : Masque l'onglet Messages dans la navigation")
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
            .navigationTitle("Paramètres")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(
                trailing: Button("Fermer") {
                    presentationMode.wrappedValue.dismiss()
                }
            )
            .onAppear {
                loadFilterStates()
            }
        }
        .navigationViewStyle(StackNavigationViewStyle())
        .alert("Se déconnecter", isPresented: $showLogoutAlert) {
            Button("Annuler", role: .cancel) { }
            Button("Déconnexion", role: .destructive) {
                logout()
            }
        } message: {
            Text("Êtes-vous sûr de vouloir vous déconnecter ? Vous devrez vous reconnecter pour utiliser l'application.")
        }
    }
    
    private func loadFilterStates() {
        for filterType in FilterType.allCases {
            filterStates[filterType] = filterType.isEnabled
        }
    }
    
    private func resetAllFilters() {
        for filterType in FilterType.allCases {
            filterStates[filterType] = false
            filterType.setEnabled(false)
        }
        // Appliquer tous les filtres en une fois
        webViewManager.applyAllSavedFilters()
    }
    
    private func resetOnboarding() {
        // Réinitialiser l'onboarding via l'AuthenticationManager
        authManager.resetOnboarding()
        
        // Fermer la vue des paramètres
        presentationMode.wrappedValue.dismiss()
    }
    
    private func logout() {
        // Déconnexion via l'AuthenticationManager
        authManager.logout()
        
        // Fermer la vue des paramètres
        presentationMode.wrappedValue.dismiss()
    }
}

struct FilterToggleRow: View {
    let filterType: FilterType
    @Binding var isEnabled: Bool
    var isDisabled: Bool = false

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 4) {
                    Text(filterType.displayName)
                        .font(AppFonts.body())

                    if isDisabled {
                        Image(systemName: "lock.fill")
                            .font(.caption2)
                            .foregroundColor(.orange)
                    }
                }

                Text(filterDescription)
                    .font(AppFonts.caption())
                    .foregroundColor(.secondary)
            }

            Spacer()

            Toggle("", isOn: $isEnabled)
                .toggleStyle(SwitchToggleStyle(tint: .blue))
                .disabled(isDisabled)
        }
        .padding(.vertical, 4)
        .opacity(isDisabled ? 0.5 : 1.0)
    }
    
    private var filterDescription: String {
        switch filterType {
        case .reels:
            return "Masque l'accès aux Reels dans la navigation"
        case .explore:
            return "Masque la page Explorer et ses suggestions"
        case .stories:
            return "Masque les stories en haut du feed principal"
        case .suggestions:
            return "Masque les suggestions de comptes à suivre"
        case .likes:
            return "Masque les compteurs de likes sur les posts"
        case .following:
            return "Force le mode Following et masque le bouton 'For you'"
        case .messages:
            return "Masque l'onglet Messages dans la navigation"
        }
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
