//
//  OnboardingView.swift
//  LessIsMore
//
//  Created by Angel Geoffroy on 03/09/2025.
//

import SwiftUI
import SuperwallKit

// Couleurs Instagram
extension Color {
    static let instagramPurple = Color(red: 131/255, green: 58/255, blue: 180/255)
    static let instagramPink = Color(red: 193/255, green: 53/255, blue: 132/255)
    static let instagramOrange = Color(red: 253/255, green: 89/255, blue: 73/255)
    static let instagramYellow = Color(red: 252/255, green: 175/255, blue: 69/255)
}

struct OnboardingView: View {
    @ObservedObject var authManager: AuthenticationManager
    @State private var currentPage = 0
    @State private var animateContent = false
    @State private var showSkip = false

    private let totalPages = 4

    var body: some View {
        ZStack {
            // Fond animé
            AnimatedGradientBackground()
                .ignoresSafeArea()

            VStack(spacing: 0) {
                // Header avec skip
                HStack {
                    Spacer()
                    if showSkip && currentPage < totalPages - 1 {
                        Button(action: {
                            withAnimation(.easeInOut(duration: 0.4)) {
                                currentPage = totalPages - 1
                            }
                        }) {
                            Text("Skip")
                                .font(AppFonts.subheadline())
                                .foregroundColor(.secondary)
                        }
                        .transition(.opacity)
                    }
                }
                .padding(.horizontal, 24)
                .padding(.top, 16)
                .frame(height: 44)

                // Contenu principal
                TabView(selection: $currentPage) {
                    // Page 1: Le problème
                    ProblemPage(animateContent: $animateContent)
                        .tag(0)

                    // Page 2: La solution
                    SolutionPage(animateContent: $animateContent)
                        .tag(1)

                    // Page 3: Les bénéfices
                    BenefitsPage(animateContent: $animateContent)
                        .tag(2)

                    // Page 4: CTA Premium
                    PremiumCTAPage(authManager: authManager, animateContent: $animateContent)
                        .tag(3)
                }
                .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
                .animation(.easeInOut(duration: 0.3), value: currentPage)

                // Footer avec indicateurs et boutons
                VStack(spacing: 20) {
                    // Indicateurs de page améliorés
                    OnboardingPageIndicator(currentPage: currentPage, totalPages: totalPages)

                    // Bouton principal (sauf dernière page)
                    if currentPage < totalPages - 1 {
                        Button(action: {
                            withAnimation(.easeInOut(duration: 0.4)) {
                                currentPage += 1
                            }
                        }) {
                            HStack(spacing: 8) {
                                Text(currentPage == 0 ? "Discover" : "Continue")
                                    .font(AppFonts.headline())
                                Image(systemName: "arrow.right")
                                    .font(.system(size: 14, weight: .semibold))
                            }
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 56)
                            .background(
                                LinearGradient(
                                    colors: [.instagramPurple, .instagramPink, .instagramOrange],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .cornerRadius(16)
                            .shadow(color: Color.instagramPink.opacity(0.4), radius: 12, x: 0, y: 6)
                        }
                        .buttonStyle(ScaleButtonStyle())
                    }
                }
                .padding(.horizontal, 32)
                .padding(.bottom, 40)
            }
        }
        .onAppear {
            withAnimation(.easeOut(duration: 0.5).delay(0.3)) {
                animateContent = true
            }
            withAnimation(.easeOut(duration: 0.3).delay(1.5)) {
                showSkip = true
            }
        }
        .onChange(of: currentPage) {
            animateContent = false
            withAnimation(.easeOut(duration: 0.4).delay(0.1)) {
                animateContent = true
            }
        }
    }
}

// MARK: - Page 1: Le Problème
struct ProblemPage: View {
    @Binding var animateContent: Bool
    @State private var timeCounter: Int = 0
    @State private var isCounterAnimating = false

    var body: some View {
        VStack(spacing: 24) {
            Spacer()

            // Icône animée
            ZStack {
                Circle()
                    .fill(Color.red.opacity(0.1))
                    .frame(width: 120, height: 120)
                    .scaleEffect(animateContent ? 1 : 0.5)

                Circle()
                    .fill(Color.red.opacity(0.2))
                    .frame(width: 80, height: 80)
                    .scaleEffect(animateContent ? 1 : 0.5)

                Image(systemName: "hourglass.tophalf.filled")
                    .font(.system(size: 40))
                    .foregroundColor(.red)
                    .rotationEffect(.degrees(animateContent ? 0 : -30))
            }
            .opacity(animateContent ? 1 : 0)
            .animation(.spring(response: 0.6, dampingFraction: 0.7).delay(0.1), value: animateContent)

            VStack(spacing: 12) {
                Text("Did you know...")
                    .font(AppFonts.subheadline())
                    .foregroundColor(.secondary)
                    .opacity(animateContent ? 1 : 0)
                    .offset(y: animateContent ? 0 : 20)

                // Compteur animé
                HStack(alignment: .firstTextBaseline, spacing: 4) {
                    Text("\(timeCounter)")
                        .font(AppFonts.title(50))
                        .foregroundColor(.red)
                        .contentTransition(.numericText())

                    Text("min/day")
                        .font(AppFonts.title3())
                        .foregroundColor(.secondary)
                }
                .opacity(animateContent ? 1 : 0)
                .offset(y: animateContent ? 0 : 20)

                Text("That's the average time wasted\non Instagram every day")
                    .font(AppFonts.body())
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .opacity(animateContent ? 1 : 0)
                    .offset(y: animateContent ? 0 : 20)
            }
            .animation(.easeOut(duration: 0.5).delay(0.2), value: animateContent)

            // Stats persuasives
            VStack(spacing: 10) {
                StatBadge(icon: "brain.head.profile", text: "Reduces anxiety by 40%", color: .orange)
                StatBadge(icon: "clock.arrow.circlepath", text: "Recover 2h per week", color: .green)
                StatBadge(icon: "bolt.fill", text: "2x Productivity", color: .blue)
            }
            .padding(.top, 8)
            .opacity(animateContent ? 1 : 0)
            .offset(y: animateContent ? 0 : 30)
            .animation(.easeOut(duration: 0.5).delay(0.4), value: animateContent)

            Spacer()
            Spacer()
        }
        .padding(.horizontal, 24)
        .onAppear {
            startCounterAnimation()
        }
    }

    private func startCounterAnimation() {
        guard !isCounterAnimating else { return }
        isCounterAnimating = true
        timeCounter = 0

        Timer.scheduledTimer(withTimeInterval: 0.02, repeats: true) { timer in
            if timeCounter < 53 {
                withAnimation(.easeOut(duration: 0.05)) {
                    timeCounter += 1
                }
            } else {
                timer.invalidate()
            }
        }
    }
}

// MARK: - Page 2: La Solution (Scrollable)
struct SolutionPage: View {
    @Binding var animateContent: Bool
    @State private var selectedFilters: Set<String> = []

    let filters = [
        ("film.fill", "Reels", "Addictive videos", Color.pink),
        ("safari.fill", "Explore", "Random content", Color.orange),
        ("circle.dashed", "Stories", "Distractions", Color.purple),
        ("heart.fill", "Likes", "Comparison", Color.red)
    ]

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 20) {
                VStack(spacing: 6) {
                    Text("Your Instagram,")
                        .font(AppFonts.title2())
                    Text("Your Rules")
                        .font(AppFonts.title())
                        .foregroundStyle(
                            LinearGradient(
                                colors: [.instagramPurple, .instagramPink],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                }
                .opacity(animateContent ? 1 : 0)
                .offset(y: animateContent ? 0 : 20)
                .animation(.easeOut(duration: 0.5), value: animateContent)
                .padding(.top, 20)

                Text("Tap to block")
                    .font(AppFonts.subheadline())
                    .foregroundColor(.secondary)
                    .opacity(animateContent ? 1 : 0)

                // Grille de filtres interactifs (2x2)
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                    ForEach(Array(filters.enumerated()), id: \.offset) { index, filter in
                        InteractiveFilterCard(
                            icon: filter.0,
                            title: filter.1,
                            subtitle: filter.2,
                            color: filter.3,
                            isSelected: selectedFilters.contains(filter.1),
                            delay: Double(index) * 0.1
                        ) {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                if selectedFilters.contains(filter.1) {
                                    selectedFilters.remove(filter.1)
                                } else {
                                    selectedFilters.insert(filter.1)
                                    let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
                                    impactFeedback.impactOccurred()
                                }
                            }
                        }
                        .opacity(animateContent ? 1 : 0)
                        .offset(y: animateContent ? 0 : 30)
                        .animation(.spring(response: 0.5, dampingFraction: 0.8).delay(Double(index) * 0.08), value: animateContent)
                    }
                }
                .padding(.horizontal, 8)

                // Compteur de filtres sélectionnés
                if !selectedFilters.isEmpty {
                    HStack(spacing: 8) {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                        Text("\(selectedFilters.count) blocked")
                            .font(AppFonts.subheadline())
                            .foregroundColor(.secondary)
                    }
                    .padding(.vertical, 10)
                    .padding(.horizontal, 16)
                    .background(Color.green.opacity(0.1))
                    .cornerRadius(20)
                    .transition(.scale.combined(with: .opacity))
                }

                // Espace pour le footer
                Spacer()
                    .frame(height: 60)
            }
            .padding(.horizontal, 24)
        }
    }
}

// MARK: - Page 3: Les Bénéfices (Scrollable)
struct BenefitsPage: View {
    @Binding var animateContent: Bool

    let testimonials = [
        ("I get back 1h30 per day!", "Marie, 24 years old"),
        ("No more endless scrolling at night", "Thomas, 31 years old")
    ]

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 16) {
                // Titre
                VStack(spacing: 4) {
                    Text("Join")
                        .font(AppFonts.title3())
                    HStack(spacing: 6) {
                        Text("10 000+")
                            .font(AppFonts.title())
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [.green, .blue],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                        Text("users")
                            .font(AppFonts.title3())
                    }
                }
                .opacity(animateContent ? 1 : 0)
                .offset(y: animateContent ? 0 : 20)
                .animation(.easeOut(duration: 0.5), value: animateContent)
                .padding(.top, 20)

                // Note moyenne
                HStack(spacing: 4) {
                    ForEach(0..<5, id: \.self) { index in
                        Image(systemName: "star.fill")
                            .foregroundColor(.yellow)
                            .font(.system(size: 18))
                            .opacity(animateContent ? 1 : 0)
                            .scaleEffect(animateContent ? 1 : 0.5)
                            .animation(.spring(response: 0.4, dampingFraction: 0.6).delay(Double(index) * 0.08), value: animateContent)
                    }
                    Text("4.9")
                        .font(AppFonts.headline())
                        .padding(.leading, 6)
                }
                .padding(.vertical, 4)

                // Témoignages (réduits à 2)
                VStack(spacing: 12) {
                    ForEach(Array(testimonials.enumerated()), id: \.offset) { index, testimonial in
                        CompactTestimonialCard(
                            quote: testimonial.0,
                            author: testimonial.1
                        )
                        .opacity(animateContent ? 1 : 0)
                        .offset(x: animateContent ? 0 : (index % 2 == 0 ? -50 : 50))
                        .animation(.spring(response: 0.6, dampingFraction: 0.8).delay(Double(index) * 0.12 + 0.2), value: animateContent)
                    }
                }

                // Badge de confiance
                HStack(spacing: 10) {
                    HStack(spacing: 4) {
                        Image(systemName: "lock.shield.fill")
                            .foregroundColor(.green)
                            .font(.system(size: 14))
                        Text("Privacy")
                            .font(AppFonts.caption())
                            .foregroundColor(.secondary)
                    }

                    Text("•")
                        .foregroundColor(.secondary)

                    HStack(spacing: 4) {
                        Image(systemName: "checkmark.seal.fill")
                            .foregroundColor(.blue)
                            .font(.system(size: 14))
                        Text("No ads")
                            .font(AppFonts.caption())
                            .foregroundColor(.secondary)
                    }
                }
                .padding(.top, 8)
                .opacity(animateContent ? 1 : 0)
                .animation(.easeOut(duration: 0.5).delay(0.5), value: animateContent)

                // Espace pour le footer
                Spacer()
                    .frame(height: 60)
            }
            .padding(.horizontal, 24)
        }
    }
}

// MARK: - Page 4: CTA Premium
struct PremiumCTAPage: View {
    @ObservedObject var authManager: AuthenticationManager
    @Binding var animateContent: Bool
    @State private var isPulsing = false

    var body: some View {
        ZStack(alignment: .topTrailing) {
            ScrollView(showsIndicators: false) {
                VStack(spacing: 20) {
                    Spacer()
                        .frame(height: 20)

                    // Badge Premium
                HStack(spacing: 8) {
                    Image(systemName: "crown.fill")
                        .foregroundColor(.yellow)
                    Text("PREMIUM")
                        .font(AppFonts.caption())
                        .fontWeight(.bold)
                        .foregroundColor(.yellow)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(Color.yellow.opacity(0.2))
                .cornerRadius(20)
                .opacity(animateContent ? 1 : 0)
                .scaleEffect(animateContent ? 1 : 0.8)
                .animation(.spring(response: 0.5, dampingFraction: 0.7), value: animateContent)

                // Titre
                VStack(spacing: 4) {
                    Text("Unlock the")
                        .font(AppFonts.title())
                    Text("Full Potential")
                        .font(AppFonts.title())
                        .foregroundStyle(
                            LinearGradient(
                                colors: [.instagramOrange, .instagramPink],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                }
                .multilineTextAlignment(.center)
                .opacity(animateContent ? 1 : 0)
                .offset(y: animateContent ? 0 : 20)
                .animation(.easeOut(duration: 0.5).delay(0.1), value: animateContent)

                // Features Premium
                VStack(spacing: 14) {
                    PremiumFeatureRow(icon: "checkmark.circle.fill", text: "All filters unlimited", color: .green)
                    PremiumFeatureRow(icon: "bolt.circle.fill", text: "Instant activation", color: .orange)
                    PremiumFeatureRow(icon: "arrow.triangle.2.circlepath.circle.fill", text: "Multi-device sync", color: .blue)
                    PremiumFeatureRow(icon: "heart.circle.fill", text: "Priority support", color: .pink)
                }
                .padding(.vertical, 18)
                .padding(.horizontal, 20)
                .background(
                    RoundedRectangle(cornerRadius: 20)
                        .fill(Color(.systemBackground))
                        .shadow(color: Color.black.opacity(0.1), radius: 20, x: 0, y: 10)
                )
                .opacity(animateContent ? 1 : 0)
                .offset(y: animateContent ? 0 : 30)
                .animation(.easeOut(duration: 0.5).delay(0.2), value: animateContent)

                Spacer()
                    .frame(height: 20)

                // Bouton CTA Premium
                VStack(spacing: 10) {
                    Button(action: {
                        // Ouvrir le paywall Superwall
                        Superwall.shared.register(placement: "campaign_trigger") {
                            // Terminer l'onboarding après le paywall
                            authManager.completeOnboarding()
                        }
                    }) {
                        HStack(spacing: 8) {
                            Image(systemName: "crown.fill")
                            Text("3-day free trial")
                                .font(AppFonts.headline())
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                        .background(
                            LinearGradient(
                                colors: [.instagramPurple, .instagramPink, .instagramOrange],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .cornerRadius(16)
                        .shadow(color: Color.instagramPink.opacity(0.4), radius: 12, x: 0, y: 6)
                        .scaleEffect(isPulsing ? 1.02 : 1)
                    }
                    .buttonStyle(ScaleButtonStyle())
                    .opacity(animateContent ? 1 : 0)
                    .animation(.easeOut(duration: 0.5).delay(0.4), value: animateContent)

                    // Mention légale
                    Text("Cancel anytime. No commitment.")
                        .font(AppFonts.caption2())
                        .foregroundColor(.secondary.opacity(0.7))
                        .opacity(animateContent ? 1 : 0)
                        .padding(.top, 4)
                }

                Spacer()
                    .frame(height: 60)
            }
            .padding(.horizontal, 24)
        }

            // Bouton croix pour quitter l'onboarding
            Button(action: {
                authManager.completeOnboarding()
            }) {
                Image(systemName: "xmark")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.secondary)
                    .frame(width: 32, height: 32)
                    .background(Color(.systemGray5))
                    .clipShape(Circle())
            }
            .padding(.trailing, 16)
            .padding(.top, 8)
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
                isPulsing = true
            }
        }
    }
}

// MARK: - Composants réutilisables

struct AnimatedGradientBackground: View {
    @State private var animateGradient = false

    var body: some View {
        LinearGradient(
            colors: [
                Color.instagramPurple.opacity(0.06),
                Color.instagramPink.opacity(0.06),
                Color.instagramOrange.opacity(0.04)
            ],
            startPoint: animateGradient ? .topLeading : .bottomLeading,
            endPoint: animateGradient ? .bottomTrailing : .topTrailing
        )
        .onAppear {
            withAnimation(.easeInOut(duration: 5).repeatForever(autoreverses: true)) {
                animateGradient = true
            }
        }
    }
}

struct OnboardingPageIndicator: View {
    let currentPage: Int
    let totalPages: Int

    var body: some View {
        HStack(spacing: 8) {
            ForEach(0..<totalPages, id: \.self) { page in
                Capsule()
                    .fill(
                        page == currentPage ?
                        AnyShapeStyle(LinearGradient(colors: [.instagramPurple, .instagramPink], startPoint: .leading, endPoint: .trailing)) :
                        AnyShapeStyle(Color.gray.opacity(0.3))
                    )
                    .frame(width: page == currentPage ? 24 : 8, height: 8)
                    .animation(.spring(response: 0.3, dampingFraction: 0.7), value: currentPage)
            }
        }
    }
}

struct StatBadge: View {
    let icon: String
    let text: String
    let color: Color

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .font(.system(size: 16))
                .foregroundColor(color)
                .frame(width: 28)

            Text(text)
                .font(AppFonts.subheadline())
                .foregroundColor(.primary)

            Spacer()
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(color.opacity(0.1))
        .cornerRadius(12)
    }
}

struct InteractiveFilterCard: View {
    let icon: String
    let title: String
    let subtitle: String
    let color: Color
    let isSelected: Bool
    let delay: Double
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 6) {
                ZStack {
                    Circle()
                        .fill(isSelected ? color : color.opacity(0.1))
                        .frame(width: 44, height: 44)

                    Image(systemName: isSelected ? "xmark" : icon)
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(isSelected ? .white : color)
                }

                Text(title)
                    .font(AppFonts.headline())
                    .foregroundColor(isSelected ? color : .primary)

                Text(subtitle)
                    .font(AppFonts.caption2())
                    .foregroundColor(.secondary)
                    .lineLimit(1)
            }
            .padding(.vertical, 12)
            .padding(.horizontal, 6)
            .frame(maxWidth: .infinity)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(isSelected ? color.opacity(0.1) : Color(.systemGray6).opacity(0.5))
                    .overlay(
                        RoundedRectangle(cornerRadius: 14)
                            .stroke(isSelected ? color : Color.clear, lineWidth: 2)
                    )
            )
        }
        .buttonStyle(ScaleButtonStyle())
    }
}

struct CompactTestimonialCard: View {
    let quote: String
    let author: String

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 2) {
                ForEach(0..<5, id: \.self) { _ in
                    Image(systemName: "star.fill")
                        .font(.system(size: 10))
                        .foregroundColor(.yellow)
                }
            }

            Text("\"\(quote)\"")
                .font(AppFonts.subheadline())
                .foregroundColor(.primary)
                .italic()

            Text("— \(author)")
                .font(AppFonts.caption())
                .foregroundColor(.secondary)
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.systemGray6).opacity(0.5))
        .cornerRadius(14)
    }
}

struct PremiumFeatureRow: View {
    let icon: String
    let text: String
    let color: Color

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .font(.system(size: 20))
                .foregroundColor(color)

            Text(text)
                .font(AppFonts.body())
                .foregroundColor(.primary)

            Spacer()
        }
    }
}

struct ScaleButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.96 : 1)
            .animation(.easeInOut(duration: 0.15), value: configuration.isPressed)
    }
}

#Preview {
    OnboardingView(authManager: AuthenticationManager())
}
