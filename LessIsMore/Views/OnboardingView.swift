//
//  OnboardingView.swift
//  LessIsMore
//
//  Created by Angel Geoffroy on 03/09/2025.
//

import SwiftUI

struct OnboardingView: View {
    @ObservedObject var authManager: AuthenticationManager
    @State private var currentPage = 0
    
    var body: some View {
        TabView(selection: $currentPage) {
            // Page 1: Bienvenue
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
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)
                }
                
                VStack(spacing: 16) {
                    Text("Reprenez le contrôle")
                        .font(.title2)
                        .fontWeight(.semibold)
                        .multilineTextAlignment(.center)
                    
                    Text("Utilisez Instagram sans les distractions. Concentrez-vous sur ce qui compte vraiment.")
                        .font(.body)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 20)
                }
                
                Spacer()
                
                // Indicateur de page
                PageIndicator(currentPage: currentPage, totalPages: 3)
                
                // Bouton suivant
                Button(action: {
                    withAnimation(.easeInOut) {
                        currentPage = 1
                    }
                }) {
                    Text("Commencer")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(minHeight: 50)
                        .background(Color.blue)
                        .cornerRadius(12)
                }
                .padding(.horizontal, 40)
                .padding(.bottom, 40)
                .buttonStyle(PlainButtonStyle())
            }
            .tag(0)
            
            // Page 2: Fonctionnalités
            VStack(spacing: 30) {
                Spacer()
                
                Text("Filtres Intelligents")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .multilineTextAlignment(.center)
                
                VStack(spacing: 24) {
                    FeatureRow(icon: "film.circle.fill", 
                             title: "Bloquer les Reels", 
                             description: "Évitez les vidéos addictives")
                    
                    FeatureRow(icon: "safari.fill", 
                             title: "Masquer Explorer", 
                             description: "Pas de contenu aléatoire")
                    
                    FeatureRow(icon: "person.circle.fill", 
                             title: "Supprimer les Stories", 
                             description: "Focus sur vos abonnements")
                    
                    FeatureRow(icon: "message.circle.fill", 
                             title: "Masquer les Messages", 
                             description: "Évitez les distractions des DM")
                    
                    FeatureRow(icon: "person.2.circle.fill", 
                             title: "Mode Following", 
                             description: "Voir uniquement vos abonnements")
                }
                .padding(.horizontal, 20)
                
                Spacer()
                
                // Indicateur de page
                PageIndicator(currentPage: currentPage, totalPages: 3)
                
                // Boutons navigation
                HStack {
                    Button(action: {
                        withAnimation(.easeInOut) {
                            currentPage = 0
                        }
                    }) {
                        Text("Retour")
                            .foregroundColor(.blue)
                            .padding(.horizontal, 20)
                            .padding(.vertical, 12)
                    }
                    .buttonStyle(PlainButtonStyle())
                    
                    Spacer()
                    
                    Button(action: {
                        withAnimation(.easeInOut) {
                            currentPage = 2
                        }
                    }) {
                        Text("Suivant")
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(minWidth: 120, minHeight: 50)
                            .background(Color.blue)
                            .cornerRadius(12)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
                .padding(.horizontal, 40)
                .padding(.bottom, 40)
            }
            .tag(1)
            
            // Page 3: Comment ça marche
            VStack(spacing: 30) {
                Spacer()
                
                Text("Comment ça marche ?")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .multilineTextAlignment(.center)
                
                VStack(spacing: 24) {
                    StepRow(number: "1", 
                           title: "Configurez vos filtres", 
                           description: "Choisissez ce que vous voulez masquer")
                    
                    StepRow(number: "2", 
                           title: "Naviguez normalement", 
                           description: "Instagram fonctionne comme d'habitude")
                    
                    StepRow(number: "3", 
                           title: "Restez concentré", 
                           description: "Plus de distractions, plus de productivité")
                }
                .padding(.horizontal, 20)
                
                Spacer()
                
                // Indicateur de page
                PageIndicator(currentPage: currentPage, totalPages: 3)
                
                // Boutons navigation
                HStack {
                    Button(action: {
                        withAnimation(.easeInOut) {
                            currentPage = 1
                        }
                    }) {
                        Text("Retour")
                            .foregroundColor(.blue)
                            .padding(.horizontal, 20)
                            .padding(.vertical, 12)
                    }
                    .buttonStyle(PlainButtonStyle())
                    
                    Spacer()
                    
                    Button(action: {
                        // Marquer l'onboarding comme terminé
                        authManager.completeOnboarding()
                    }) {
                        Text("C'est parti !")
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(minWidth: 140, minHeight: 50)
                            .background(Color.green)
                            .cornerRadius(12)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
                .padding(.horizontal, 40)
                .padding(.bottom, 40)
            }
            .tag(2)
        }
        .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
        .background(
            LinearGradient(
                gradient: Gradient(colors: [Color.blue.opacity(0.1), Color.purple.opacity(0.1)]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
    }
}

struct FeatureRow: View {
    let icon: String
    let title: String
    let description: String
    
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 24))
                .foregroundColor(.blue)
                .frame(width: 30)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Text(description)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
        }
        .padding(.vertical, 8)
    }
}

struct StepRow: View {
    let number: String
    let title: String
    let description: String
    
    var body: some View {
        HStack(spacing: 16) {
            Text(number)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.white)
                .frame(width: 40, height: 40)
                .background(Color.blue)
                .clipShape(Circle())
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Text(description)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
        }
        .padding(.vertical, 8)
    }
}

struct PageIndicator: View {
    let currentPage: Int
    let totalPages: Int
    
    var body: some View {
        HStack(spacing: 8) {
            ForEach(0..<totalPages, id: \.self) { page in
                Circle()
                    .fill(page == currentPage ? Color.blue : Color.gray.opacity(0.3))
                    .frame(width: 8, height: 8)
            }
        }
    }
}

#Preview {
    OnboardingView(authManager: AuthenticationManager())
}
