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
    
    var body: some View {
        VStack(spacing: 30) {
            Spacer()
            
            // Logo et titre
            VStack(spacing: 20) {
                Image("OnboardingImages")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 200, height: 200)
                    .clipShape(RoundedRectangle(cornerRadius: 20))
                    .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 5)

                Text("LessIsMore")
                    .font(AppFonts.title())
                    .foregroundColor(.primary)

                Text("Choose your login method")
                    .font(AppFonts.title2(22))
                    .multilineTextAlignment(.center)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            // Options de connexion
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
                .signInWithAppleButtonStyle(.black)
                .frame(height: 50)
                .cornerRadius(12)
                .padding(.horizontal, 40)
                
                // Ou continuer avec Instagram
                Button(action: {
                    authManager.login()
                }) {
                    HStack {
                        Image(systemName: "camera.fill")
                        Text("Continue with Instagram")
                    }
                    .font(AppFonts.headline())
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
                    .background(
                        LinearGradient(
                            gradient: Gradient(colors: [Color.purple, Color.pink]),
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .cornerRadius(12)
                }
                .padding(.horizontal, 40)
            }
            
            // Texte informatif
            VStack(spacing: 8) {
                Text("By continuing, you agree to our")
                    .font(AppFonts.caption())
                    .foregroundColor(.secondary)

                HStack(spacing: 4) {
                    Button("Terms of Service") {
                        // Ouvrir les conditions d'utilisation
                    }
                    .font(AppFonts.caption())
                    .foregroundColor(.blue)

                    Text("and")
                        .font(AppFonts.caption())
                        .foregroundColor(.secondary)

                    Button("Privacy Policy") {
                        // Ouvrir la politique de confidentialité
                    }
                    .font(AppFonts.caption())
                    .foregroundColor(.blue)
                }
            }
            .padding(.top, 20)
            
            Spacer()
        }
        .padding()
        .background(
            LinearGradient(
                gradient: Gradient(colors: [Color.blue.opacity(0.1), Color.purple.opacity(0.1)]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .alert("Login Error", isPresented: $showError) {
            Button("OK") { }
        } message: {
            Text(errorMessage)
        }
    }
    
    private func handleSignInWithApple(result: Result<ASAuthorization, Error>) {
        switch result {
        case .success(let authorization):
            if let appleIDCredential = authorization.credential as? ASAuthorizationAppleIDCredential {
                // Traitement réussi de Sign in with Apple
                print("Connexion Apple réussie: \(appleIDCredential.user)")
                authManager.login()
            }
        case .failure(let error):
            print("Erreur Sign in with Apple: \(error.localizedDescription)")
            errorMessage = "Error signing in with Apple. Please try again."
            showError = true
        }
    }
}

#Preview {
    AuthenticationView(authManager: AuthenticationManager())
}
