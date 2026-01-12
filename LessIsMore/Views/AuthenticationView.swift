//
//  AuthenticationView.swift
//  LessIsMore
//
//  Created by Angel Geoffroy on 03/09/2025.
//

import SwiftUI
import AuthenticationServices

struct AuthenticationView: View {
    @ObservedObject var authManager: AuthenticationManager
    @State private var showError = false
    @State private var errorMessage = ""
    @State private var animateContent = false
    
    var body: some View {
        ZStack {
            // Dark background matching onboarding
            OnboardingColors.background
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                Spacer()
                
                // Mascot and welcome text
                VStack(spacing: 24) {
                    // Mascot bonjour
                    Image("mascott bonjour")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 200, height: 200)
                        .opacity(animateContent ? 1 : 0)
                        .scaleEffect(animateContent ? 1 : 0.8)
                        .animation(.spring(response: 0.6, dampingFraction: 0.7), value: animateContent)
                    
                    // Title and subtitle
                    VStack(spacing: 12) {
                        Text("Bienvenue sur")
                            .font(AppFonts.title2())
                            .foregroundColor(OnboardingColors.textSecondary)
                        
                        Text("LessIsMore")
                            .font(AppFonts.title(36))
                            .foregroundColor(OnboardingColors.textPrimary)
                        
                        Text("Choisis ta méthode de connexion")
                            .font(AppFonts.subheadline())
                            .foregroundColor(OnboardingColors.textSecondary)
                            .multilineTextAlignment(.center)
                    }
                    .opacity(animateContent ? 1 : 0)
                    .offset(y: animateContent ? 0 : 20)
                    .animation(.easeOut(duration: 0.5).delay(0.2), value: animateContent)
                }
                
                Spacer()
                
                // Login options
                VStack(spacing: 16) {
                    // Sign in with Apple
                    SignInWithAppleButton(
                        onRequest: { request in
                            request.requestedScopes = [.fullName, .email]
                        },
                        onCompletion: { result in
                            handleSignInWithApple(result: result)
                        }
                    )
                    .signInWithAppleButtonStyle(.white)
                    .frame(height: 56)
                    .cornerRadius(28)
                    .padding(.horizontal, 24)
                }
                .opacity(animateContent ? 1 : 0)
                .offset(y: animateContent ? 0 : 30)
                .animation(.easeOut(duration: 0.5).delay(0.3), value: animateContent)
                
                // Legal text
                VStack(spacing: 8) {
                    Text("En continuant, tu acceptes nos")
                        .font(AppFonts.caption())
                        .foregroundColor(OnboardingColors.textSecondary)
                    
                    HStack(spacing: 4) {
                        Button("Conditions d'utilisation") {
                            // Open terms of service
                        }
                        .font(AppFonts.caption())
                        .foregroundColor(OnboardingColors.primary)
                        
                        Text("et")
                            .font(AppFonts.caption())
                            .foregroundColor(OnboardingColors.textSecondary)
                        
                        Button("Politique de confidentialité") {
                            // Open privacy policy
                        }
                        .font(AppFonts.caption())
                        .foregroundColor(OnboardingColors.primary)
                    }
                }
                .padding(.top, 24)
                .padding(.bottom, 40)
                .opacity(animateContent ? 1 : 0)
                .animation(.easeOut(duration: 0.5).delay(0.4), value: animateContent)
            }
        }
        .onAppear {
            withAnimation {
                animateContent = true
            }
        }
        .alert("Erreur de connexion", isPresented: $showError) {
            Button("OK") { }
        } message: {
            Text(errorMessage)
        }
    }
    
    private func handleSignInWithApple(result: Result<ASAuthorization, Error>) {
        switch result {
        case .success(let authorization):
            if let appleIDCredential = authorization.credential as? ASAuthorizationAppleIDCredential {
                print("Connexion Apple réussie: \(appleIDCredential.user)")
                authManager.login()
            }
        case .failure(let error):
            print("Erreur Sign in with Apple: \(error.localizedDescription)")
            errorMessage = "Erreur lors de la connexion avec Apple. Réessaie."
            showError = true
        }
    }
}

#Preview {
    AuthenticationView(authManager: AuthenticationManager())
}
