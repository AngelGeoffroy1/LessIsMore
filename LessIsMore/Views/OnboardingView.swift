//
//  OnboardingView.swift
//  LessIsMore
//
//  Created by Angel Geoffroy on 03/09/2025.
//  Redesigned on 07/01/2026.
//

import SwiftUI
import SuperwallKit

// MARK: - Design System Colors
struct OnboardingColors {
    static let background = Color(hex: "111111")
    static let primary = Color(hex: "ffb3cf")
    static let surface = Color(hex: "1C1C1E")
    static let surfaceSelected = Color(hex: "ffb3cf").opacity(0.15)
    static let textPrimary = Color.white
    static let textSecondary = Color(hex: "8E8E93")
    static let border = Color(hex: "2C2C2E")
    static let borderSelected = Color(hex: "ffb3cf")
}

// MARK: - Main Onboarding View
struct OnboardingView: View {
    @ObservedObject var authManager: AuthenticationManager
    @State private var currentPage = 0
    @State private var animateContent = false
    
    private let totalPages = 10
    
    var body: some View {
        ZStack {
            // Dark background
            OnboardingColors.background
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Progress bar
                OnboardingProgressBar(currentPage: currentPage, totalPages: totalPages)
                    .padding(.top, 8)
                
                // Content
                TabView(selection: $currentPage) {
                    // Page 0: Welcome
                    WelcomePage(animateContent: $animateContent)
                        .tag(0)
                    
                    // Page 1: Name Input
                    NameInputPage(authManager: authManager, animateContent: $animateContent, onContinue: { goToNextPage() })
                        .tag(1)
                    
                    // Page 2: Problem Selection
                    ProblemPage(authManager: authManager, animateContent: $animateContent)
                        .tag(2)
                    
                    // Page 3: Goals Selection
                    GoalsPage(authManager: authManager, animateContent: $animateContent)
                        .tag(3)
                    
                    // Page 4: Screen Time Input
                    ScreenTimePage(authManager: authManager, animateContent: $animateContent)
                        .tag(4)
                    
                    // Page 5: Filter Recommendations
                    FiltersPage(authManager: authManager, animateContent: $animateContent)
                        .tag(5)
                    
                    // Page 6: Projection
                    ProjectionPage(authManager: authManager, animateContent: $animateContent)
                        .tag(6)
                    
                    // Page 7: Social Proof
                    SocialProofPage(animateContent: $animateContent)
                        .tag(7)
                    
                    // Page 8: Premium CTA
                    PremiumCTAPage(authManager: authManager, animateContent: $animateContent)
                        .tag(8)
                    
                    // Page 9: Let's Go
                    LetsGoPage(authManager: authManager, animateContent: $animateContent)
                        .tag(9)
                }
                .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
                .animation(.easeInOut(duration: 0.3), value: currentPage)
            }
            
            // Back button overlay (top left, below progress bar)
            if currentPage > 1 && currentPage < totalPages - 1 && currentPage != 8 {
                VStack {
                    HStack {
                        Button(action: {
                            withAnimation(.easeInOut(duration: 0.4)) {
                                currentPage -= 1
                            }
                        }) {
                            HStack(spacing: 4) {
                                Image(systemName: "chevron.left")
                                    .font(.system(size: 14, weight: .semibold))
                                Text("Retour")
                                    .font(AppFonts.subheadline())
                            }
                            .foregroundColor(OnboardingColors.textSecondary)
                        }
                        .padding(.leading, 20)
                        .padding(.top, 16)
                        Spacer()
                    }
                    Spacer()
                }
            }
            
            // Footer overlay (transparent, no background)
            VStack {
                Spacer()
                OnboardingFooter(
                    currentPage: $currentPage,
                    totalPages: totalPages,
                    authManager: authManager,
                    canContinue: canContinue
                )
            }
        }
        .onAppear {
            triggerAnimation()
        }
        .onChange(of: currentPage) {
            triggerAnimation()
        }
    }
    
    private func triggerAnimation() {
        // Dismiss keyboard when changing pages
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
        
        animateContent = false
        withAnimation(.easeOut(duration: 0.4).delay(0.1)) {
            animateContent = true
        }
    }
    
    private func goToNextPage() {
        withAnimation(.easeInOut(duration: 0.4)) {
            currentPage += 1
        }
    }
    
    private var canContinue: Bool {
        switch currentPage {
        case 1: return !authManager.userName.trimmingCharacters(in: .whitespaces).isEmpty
        case 2: return authManager.userProblem != nil
        case 3: return !authManager.userGoals.isEmpty
        default: return true
        }
    }
}

// MARK: - Progress Bar
struct OnboardingProgressBar: View {
    let currentPage: Int
    let totalPages: Int
    
    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                // Background
                Rectangle()
                    .fill(OnboardingColors.border)
                    .frame(height: 3)
                
                // Progress
                Rectangle()
                    .fill(OnboardingColors.primary)
                    .frame(width: geometry.size.width * CGFloat(currentPage + 1) / CGFloat(totalPages), height: 3)
                    .animation(.easeInOut(duration: 0.3), value: currentPage)
            }
        }
        .frame(height: 3)
        .padding(.horizontal, 20)
    }
}

// MARK: - Footer
struct OnboardingFooter: View {
    @Binding var currentPage: Int
    let totalPages: Int
    @ObservedObject var authManager: AuthenticationManager
    let canContinue: Bool
    
    var body: some View {
        VStack(spacing: 16) {
            // Main CTA button (except for pages with custom buttons)
            if shouldShowMainButton {
                Button(action: {
                    handleMainButtonAction()
                }) {
                    Text(mainButtonText)
                        .font(AppFonts.headline())
                        .foregroundColor(OnboardingColors.background)
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                        .background(
                            RoundedRectangle(cornerRadius: 28)
                                .fill(canContinue ? OnboardingColors.primary : OnboardingColors.primary.opacity(0.5))
                        )
                }
                .disabled(!canContinue)
                .buttonStyle(OnboardingButtonStyle())
            }
        }
        .padding(.horizontal, 24)
        .padding(.bottom, 40)
    }
    
    private var shouldShowMainButton: Bool {
        // Pages 8 (premium) and 9 (let's go) have custom buttons
        return currentPage != 8 && currentPage != 9
    }
    
    private var mainButtonText: String {
        switch currentPage {
        case 0: return "Continue"
        case 7: return "Rejoindre la team"
        default: return "Continue"
        }
    }
    
    private func handleMainButtonAction() {
        withAnimation(.easeInOut(duration: 0.4)) {
            if currentPage < totalPages - 1 {
                currentPage += 1
            }
        }
    }
}

// MARK: - Button Style
struct OnboardingButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.96 : 1)
            .animation(.easeInOut(duration: 0.15), value: configuration.isPressed)
    }
}

// MARK: - Page 0: Welcome
struct WelcomePage: View {
    @Binding var animateContent: Bool
    
    var body: some View {
        VStack(spacing: 0) {
            Spacer()
            
            // Text content
            VStack(alignment: .leading, spacing: 8) {
                Text("Salut ! 👋 Je suis Lessy,")
                    .font(AppFonts.title2())
                    .foregroundColor(OnboardingColors.textPrimary)
                
                Text("ton compagnon pour reprendre")
                    .font(AppFonts.title2())
                    .foregroundColor(OnboardingColors.textPrimary)
                
                Text("le contrôle de ton temps")
                    .font(AppFonts.title2())
                    .foregroundColor(OnboardingColors.textPrimary)
                
                Text("sur Instagram !")
                    .font(AppFonts.title2())
                    .foregroundColor(OnboardingColors.textPrimary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 24)
            .opacity(animateContent ? 1 : 0)
            .offset(y: animateContent ? 0 : 20)
            .animation(.easeOut(duration: 0.5), value: animateContent)
            
            Spacer()
            
            // Mascot saying hi
            Image("mascott bonjour")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 220, height: 220)
                .opacity(animateContent ? 1 : 0)
                .scaleEffect(animateContent ? 1 : 0.8)
                .animation(.spring(response: 0.6, dampingFraction: 0.7).delay(0.2), value: animateContent)
            
            Spacer()
            Spacer()
        }
    }
}

// MARK: - Page 1: Name Input
struct NameInputPage: View {
    @ObservedObject var authManager: AuthenticationManager
    @Binding var animateContent: Bool
    var onContinue: () -> Void
    @FocusState private var isNameFocused: Bool
    
    var body: some View {
        VStack(spacing: 0) {
            Spacer()
                .frame(height: 30)
            
            // Question
            Text("Comment je peux t'appeler ? 😊")
                .font(AppFonts.title2())
                .foregroundColor(OnboardingColors.textPrimary)
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 24)
                .opacity(animateContent ? 1 : 0)
                .offset(y: animateContent ? 0 : 20)
            
            // Text field
            VStack(alignment: .trailing, spacing: 8) {
                TextField("", text: $authManager.userName)
                    .font(AppFonts.body())
                    .foregroundColor(OnboardingColors.textPrimary)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 14)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(OnboardingColors.surface)
                    )
                    .focused($isNameFocused)
                    .submitLabel(.continue)
                    .onSubmit {
                        if !authManager.userName.trimmingCharacters(in: .whitespaces).isEmpty {
                            onContinue()
                        }
                    }
                
                Text("\(authManager.userName.count) / 50")
                    .font(AppFonts.caption())
                    .foregroundColor(OnboardingColors.textSecondary)
            }
            .padding(.horizontal, 24)
            .padding(.top, 16)
            .opacity(animateContent ? 1 : 0)
            .animation(.easeOut(duration: 0.5).delay(0.1), value: animateContent)
            
            Spacer()
            
            // Mascot (question variant - centered and larger)
            Image("mascott question")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 180, height: 180)
                .frame(maxWidth: .infinity)
                .opacity(animateContent ? 1 : 0)
                .animation(.easeOut(duration: 0.5).delay(0.2), value: animateContent)
            
            Spacer()
        }
        .contentShape(Rectangle())
        .onTapGesture {
            isNameFocused = false
        }
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                isNameFocused = true
            }
        }
    }
}

// MARK: - Page 2: Problem Selection
struct ProblemPage: View {
    @ObservedObject var authManager: AuthenticationManager
    @Binding var animateContent: Bool
    
    var body: some View {
        VStack(spacing: 0) {
            Spacer()
                .frame(height: 60)
            
            // Question
            VStack(alignment: .leading, spacing: 4) {
                if !authManager.userName.isEmpty {
                    Text("\(authManager.userName),")
                        .font(AppFonts.title2())
                        .foregroundColor(OnboardingColors.primary)
                }
                Text("qu'est-ce qui t'embête")
                    .font(AppFonts.title2())
                    .foregroundColor(OnboardingColors.textPrimary)
                Text("le plus avec Instagram ? 🤔")
                    .font(AppFonts.title2())
                    .foregroundColor(OnboardingColors.textPrimary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 24)
            .opacity(animateContent ? 1 : 0)
            .offset(y: animateContent ? 0 : 20)
            
            // Options
            ScrollView(showsIndicators: false) {
                VStack(spacing: 12) {
                    ForEach(Array(UserProblem.allCases.enumerated()), id: \.element) { index, problem in
                        ProblemOptionCard(
                            problem: problem,
                            isSelected: authManager.userProblem == problem,
                            delay: Double(index) * 0.08
                        ) {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                authManager.userProblem = problem
                                let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
                                impactFeedback.impactOccurred()
                            }
                        }
                        .opacity(animateContent ? 1 : 0)
                        .offset(y: animateContent ? 0 : 20)
                        .animation(.easeOut(duration: 0.4).delay(Double(index) * 0.08 + 0.1), value: animateContent)
                    }
                }
                .padding(.horizontal, 24)
                .padding(.top, 24)
                .padding(.bottom, 120)
            }
            
            Spacer()
        }
    }
}

struct ProblemOptionCard: View {
    let problem: UserProblem
    let isSelected: Bool
    let delay: Double
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Text(problem.emoji)
                    .font(.system(size: 24))
                
                Text(problem.displayText)
                    .font(AppFonts.body())
                    .foregroundColor(OnboardingColors.textPrimary)
                
                Spacer()
                
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 22))
                        .foregroundColor(OnboardingColors.primary)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 16)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(isSelected ? OnboardingColors.surfaceSelected : OnboardingColors.surface)
                    .overlay(
                        RoundedRectangle(cornerRadius: 14)
                            .stroke(isSelected ? OnboardingColors.borderSelected : OnboardingColors.border, lineWidth: isSelected ? 2 : 1)
                    )
            )
        }
        .buttonStyle(OnboardingButtonStyle())
    }
}

// MARK: - Page 3: Goals Selection
struct GoalsPage: View {
    @ObservedObject var authManager: AuthenticationManager
    @Binding var animateContent: Bool
    
    var body: some View {
        VStack(spacing: 0) {
            Spacer()
                .frame(height: 60)
            
            // Question
            VStack(alignment: .leading, spacing: 4) {
                Text("Qu'est-ce que tu veux accomplir ? 🎯")
                    .font(AppFonts.title2())
                    .foregroundColor(OnboardingColors.textPrimary)
                Text("(sélectionne tout ce qui s'applique)")
                    .font(AppFonts.subheadline())
                    .foregroundColor(OnboardingColors.textSecondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 24)
            .opacity(animateContent ? 1 : 0)
            .offset(y: animateContent ? 0 : 20)
            
            // Options
            ScrollView(showsIndicators: false) {
                VStack(spacing: 12) {
                    ForEach(Array(UserGoal.allCases.enumerated()), id: \.element) { index, goal in
                        GoalOptionCard(
                            goal: goal,
                            isSelected: authManager.userGoals.contains(goal)
                        ) {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                if authManager.userGoals.contains(goal) {
                                    authManager.userGoals.remove(goal)
                                } else {
                                    authManager.userGoals.insert(goal)
                                    let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
                                    impactFeedback.impactOccurred()
                                }
                            }
                        }
                        .opacity(animateContent ? 1 : 0)
                        .offset(y: animateContent ? 0 : 20)
                        .animation(.easeOut(duration: 0.4).delay(Double(index) * 0.08 + 0.1), value: animateContent)
                    }
                }
                .padding(.horizontal, 24)
                .padding(.top, 24)
                .padding(.bottom, 120)
            }
            
            Spacer()
        }
    }
}

struct GoalOptionCard: View {
    let goal: UserGoal
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Text(goal.emoji)
                    .font(.system(size: 24))
                
                Text(goal.displayText)
                    .font(AppFonts.body())
                    .foregroundColor(OnboardingColors.textPrimary)
                
                Spacer()
                
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 22))
                        .foregroundColor(OnboardingColors.primary)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 16)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(isSelected ? OnboardingColors.surfaceSelected : OnboardingColors.surface)
                    .overlay(
                        RoundedRectangle(cornerRadius: 14)
                            .stroke(isSelected ? OnboardingColors.borderSelected : OnboardingColors.border, lineWidth: isSelected ? 2 : 1)
                    )
            )
        }
        .buttonStyle(OnboardingButtonStyle())
    }
}

// MARK: - Page 4: Screen Time Input
struct ScreenTimePage: View {
    @ObservedObject var authManager: AuthenticationManager
    @Binding var animateContent: Bool
    
    private let timeOptions = [30, 60, 90, 120, 150, 180, 240, 300]
    
    var body: some View {
        VStack(spacing: 0) {
            Spacer()
                .frame(height: 60)
            
            // Question
            VStack(alignment: .leading, spacing: 4) {
                Text("Combien de temps passes-tu")
                    .font(AppFonts.title2())
                    .foregroundColor(OnboardingColors.textPrimary)
                Text("sur Instagram par jour ? 📱")
                    .font(AppFonts.title2())
                    .foregroundColor(OnboardingColors.textPrimary)
            }
            .fixedSize(horizontal: false, vertical: true)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 24)
            .opacity(animateContent ? 1 : 0)
            .offset(y: animateContent ? 0 : 20)
            
            Spacer()
            
            // Time display
            VStack(spacing: 8) {
                Text(formatTime(authManager.dailyScreenTimeMinutes))
                    .font(AppFonts.title(50))
                    .foregroundColor(timeColor)
                    .contentTransition(.numericText())
                    .animation(.easeInOut(duration: 0.2), value: authManager.dailyScreenTimeMinutes)
                
                Text("par jour")
                    .font(AppFonts.subheadline())
                    .foregroundColor(OnboardingColors.textSecondary)
            }
            .opacity(animateContent ? 1 : 0)
            .animation(.easeOut(duration: 0.5).delay(0.1), value: animateContent)
            
            // Slider
            VStack(spacing: 16) {
                Slider(
                    value: Binding(
                        get: { Double(authManager.dailyScreenTimeMinutes) },
                        set: { authManager.dailyScreenTimeMinutes = Int($0) }
                    ),
                    in: 30...300,
                    step: 30
                )
                .tint(OnboardingColors.primary)
                .padding(.horizontal, 24)
                
                HStack {
                    Text("30min")
                        .font(AppFonts.caption())
                        .foregroundColor(OnboardingColors.textSecondary)
                    Spacer()
                    Text("5h+")
                        .font(AppFonts.caption())
                        .foregroundColor(OnboardingColors.textSecondary)
                }
                .padding(.horizontal, 24)
            }
            .padding(.top, 32)
            .opacity(animateContent ? 1 : 0)
            .animation(.easeOut(duration: 0.5).delay(0.2), value: animateContent)
            
            Spacer()
            
            // Mascot with reaction (tired variant)
            VStack(spacing: 12) {
                Image("mascotte tired")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 160, height: 160)
                
                Text(reactionMessage)
                    .font(AppFonts.subheadline())
                    .foregroundColor(OnboardingColors.textSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
            }
            .opacity(animateContent ? 1 : 0)
            .animation(.easeOut(duration: 0.5).delay(0.3), value: animateContent)
            .padding(.bottom, 120)
            
            Spacer()
        }
    }
    
    private var timeColor: Color {
        switch authManager.dailyScreenTimeMinutes {
        case 0...60: return .green
        case 61...120: return .yellow
        case 121...180: return .orange
        default: return .red
        }
    }
    
    private var reactionMessage: String {
        switch authManager.dailyScreenTimeMinutes {
        case 0...60: return "Pas mal ! On peut encore améliorer 💪"
        case 61...120: return "C'est commun, on va régler ça ensemble !"
        case 121...180: return "T'inquiète, je suis là pour t'aider ! 🤗"
        default: return "Wow, mais pas de souci, on va transformer ça ! 🚀"
        }
    }
    
    private func formatTime(_ minutes: Int) -> String {
        let hours = minutes / 60
        let mins = minutes % 60
        if hours > 0 && mins > 0 {
            return "\(hours)h\(mins)"
        } else if hours > 0 {
            return "\(hours)h"
        } else {
            return "\(mins)min"
        }
    }
}

// MARK: - Page 5: Filter Recommendations
struct FiltersPage: View {
    @ObservedObject var authManager: AuthenticationManager
    @Binding var animateContent: Bool
    @State private var selectedFilters: Set<String> = []
    
    let filters: [(id: String, icon: String, title: String, timeSaved: Int, color: Color)] = [
        ("reels", "film.fill", "Reels", 45, .pink),
        ("explore", "safari.fill", "Explore", 20, .orange),
        ("stories", "circle.dashed", "Stories", 15, .purple),
        ("likes", "heart.fill", "Likes", 10, .red)
    ]
    
    var body: some View {
        VStack(spacing: 0) {
            Spacer()
                .frame(height: 40)
            
            // Header with mascot
            HStack(alignment: .top, spacing: 12) {
                VStack(alignment: .leading, spacing: 4) {
                    if !authManager.userName.isEmpty {
                        Text("\(authManager.userName),")
                            .font(AppFonts.title2())
                            .foregroundColor(OnboardingColors.primary)
                    }
                    Text("voici mes recommandations")
                        .font(AppFonts.title2())
                        .foregroundColor(OnboardingColors.textPrimary)
                    Text("pour toi ! ✨")
                        .font(AppFonts.title2())
                        .foregroundColor(OnboardingColors.textPrimary)
                }
                
                Spacer()
                
                // Mascot thumbs up
                Image("mascott pouce")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 80, height: 80)
            }
            .padding(.horizontal, 24)
            .opacity(animateContent ? 1 : 0)
            .offset(y: animateContent ? 0 : 20)
            
            Text("Tape pour bloquer")
                .font(AppFonts.subheadline())
                .foregroundColor(OnboardingColors.textSecondary)
                .padding(.top, 8)
                .opacity(animateContent ? 1 : 0)
            
            // Filter grid
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                ForEach(Array(filters.enumerated()), id: \.element.id) { index, filter in
                    FilterCard(
                        icon: filter.icon,
                        title: filter.title,
                        timeSaved: filter.timeSaved,
                        color: filter.color,
                        isSelected: selectedFilters.contains(filter.id),
                        isRecommended: authManager.recommendedFiltersFromGoals.contains(filter.id)
                    ) {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                            if selectedFilters.contains(filter.id) {
                                selectedFilters.remove(filter.id)
                            } else {
                                selectedFilters.insert(filter.id)
                                let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
                                impactFeedback.impactOccurred()
                            }
                        }
                    }
                    .opacity(animateContent ? 1 : 0)
                    .offset(y: animateContent ? 0 : 30)
                    .animation(.spring(response: 0.5, dampingFraction: 0.8).delay(Double(index) * 0.08 + 0.1), value: animateContent)
                }
            }
            .padding(.horizontal, 24)
            .padding(.top, 24)
            
            Spacer()
            
            // Time saved counter
            if !selectedFilters.isEmpty {
                VStack(spacing: 8) {
                    HStack(spacing: 8) {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                        Text("\(selectedFilters.count) filtre(s) bloqué(s)")
                            .font(AppFonts.subheadline())
                            .foregroundColor(OnboardingColors.textSecondary)
                    }
                    
                    HStack(spacing: 4) {
                        Text("≈")
                            .foregroundColor(OnboardingColors.textSecondary)
                        Text("\(totalTimeSaved) min")
                            .font(AppFonts.headline())
                            .foregroundColor(.green)
                        Text("économisées/jour")
                            .foregroundColor(OnboardingColors.textSecondary)
                    }
                    .font(AppFonts.subheadline())
                }
                .transition(.scale.combined(with: .opacity))
            }
            
            // Extra space for Continue button
            Spacer()
                .frame(height: 100)
        }
        .onAppear {
            // Pre-select recommended filters
            selectedFilters = authManager.recommendedFiltersFromGoals
        }
    }
    
    private var totalTimeSaved: Int {
        filters.filter { selectedFilters.contains($0.id) }.reduce(0) { $0 + $1.timeSaved }
    }
}

struct FilterCard: View {
    let icon: String
    let title: String
    let timeSaved: Int
    let color: Color
    let isSelected: Bool
    let isRecommended: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                ZStack {
                    Circle()
                        .fill(isSelected ? color : color.opacity(0.15))
                        .frame(width: 50, height: 50)
                    
                    Image(systemName: isSelected ? "xmark" : icon)
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundColor(isSelected ? .white : color)
                }
                
                Text(title)
                    .font(AppFonts.headline())
                    .foregroundColor(isSelected ? color : OnboardingColors.textPrimary)
                
                Text("-\(timeSaved) min")
                    .font(AppFonts.caption())
                    .foregroundColor(OnboardingColors.textSecondary)
                
                if isRecommended && !isSelected {
                    Text("Recommandé")
                        .font(AppFonts.caption2())
                        .foregroundColor(OnboardingColors.primary)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(OnboardingColors.primary.opacity(0.2))
                        .cornerRadius(8)
                }
            }
            .padding(.vertical, 16)
            .frame(maxWidth: .infinity)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(isSelected ? color.opacity(0.1) : OnboardingColors.surface)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(isSelected ? color : OnboardingColors.border, lineWidth: isSelected ? 2 : 1)
                    )
            )
        }
        .buttonStyle(OnboardingButtonStyle())
    }
}

// MARK: - Page 6: Projection
struct ProjectionPage: View {
    @ObservedObject var authManager: AuthenticationManager
    @Binding var animateContent: Bool
    @State private var displayedHours: Int = 0
    
    private var projectedHours: Int {
        (authManager.estimatedTimeSavedMinutes * 30) / 60
    }
    
    let equivalences = [
        ("📚", "livres lus"),
        ("🏃", "séances de sport"),
        ("😴", "nuits de sommeil en plus")
    ]
    
    var body: some View {
        VStack(spacing: 0) {
            Spacer()
                .frame(height: 60)
            
            // Header
            VStack(alignment: .leading, spacing: 4) {
                if !authManager.userName.isEmpty {
                    Text("\(authManager.userName),")
                        .font(AppFonts.title2())
                        .foregroundColor(OnboardingColors.primary)
                }
                Text("dans 30 jours,")
                    .font(AppFonts.title2())
                    .foregroundColor(OnboardingColors.textPrimary)
                Text("tu auras récupéré... 🔮")
                    .font(AppFonts.title2())
                    .foregroundColor(OnboardingColors.textPrimary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 24)
            .opacity(animateContent ? 1 : 0)
            .offset(y: animateContent ? 0 : 20)
            
            Spacer()
            
            // Big number (centered)
            VStack(spacing: 8) {
                Text("\(displayedHours)h")
                    .font(AppFonts.title(72))
                    .foregroundColor(.green)
                    .contentTransition(.numericText())
                
                Text("de ta vie")
                    .font(AppFonts.title3())
                    .foregroundColor(OnboardingColors.textSecondary)
            }
            .opacity(animateContent ? 1 : 0)
            .scaleEffect(animateContent ? 1 : 0.8)
            .animation(.spring(response: 0.6, dampingFraction: 0.7).delay(0.2), value: animateContent)
            
            // Equivalences
            VStack(spacing: 12) {
                Text("💡 C'est l'équivalent de :")
                    .font(AppFonts.subheadline())
                    .foregroundColor(OnboardingColors.textSecondary)
                
                VStack(spacing: 8) {
                    EquivalenceCard(emoji: "📚", text: "\(max(projectedHours / 4, 1)) livres lus")
                    EquivalenceCard(emoji: "🏃", text: "\(max(projectedHours / 2, 1)) séances de sport")
                    EquivalenceCard(emoji: "😴", text: "\(max(projectedHours / 8, 1)) nuits de sommeil en plus")
                }
            }
            .padding(.top, 32)
            .padding(.horizontal, 24)
            .opacity(animateContent ? 1 : 0)
            .animation(.easeOut(duration: 0.5).delay(0.5), value: animateContent)
            
            Spacer()
            
            // Extra space for Continue button
            Spacer()
                .frame(height: 100)
        }
        .onAppear {
            startCounterAnimation()
        }
    }
    
    private func startCounterAnimation() {
        displayedHours = 0
        let target = projectedHours
        let duration = 1.5
        let steps = 30
        let interval = duration / Double(steps)
        
        for i in 0...steps {
            DispatchQueue.main.asyncAfter(deadline: .now() + interval * Double(i)) {
                withAnimation(.easeOut(duration: 0.1)) {
                    displayedHours = Int(Double(target) * Double(i) / Double(steps))
                }
            }
        }
    }
}

struct EquivalenceCard: View {
    let emoji: String
    let text: String
    
    var body: some View {
        HStack(spacing: 12) {
            Text(emoji)
                .font(.system(size: 24))
            Text(text)
                .font(AppFonts.body())
                .foregroundColor(OnboardingColors.textPrimary)
            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
    }
}

// MARK: - Page 7: Social Proof
struct SocialProofPage: View {
    @Binding var animateContent: Bool
    
    let testimonials = [
        ("Je récupère 1h30 par jour !", "Marie, 24 ans"),
        ("Plus de scroll nocturne", "Thomas, 31 ans")
    ]
    
    var body: some View {
        VStack(spacing: 0) {
            Spacer()
                .frame(height: 60)
            
            // Header
            Text("Tu n'es pas seul(e) ! 🤝")
                .font(AppFonts.title2())
                .foregroundColor(OnboardingColors.textPrimary)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 24)
                .opacity(animateContent ? 1 : 0)
                .offset(y: animateContent ? 0 : 20)
            
            Text("Rejoins")
                .font(AppFonts.title3())
                .foregroundColor(OnboardingColors.textSecondary)
                .padding(.top, 16)
                .opacity(animateContent ? 1 : 0)
            
            // User count
            HStack(alignment: .firstTextBaseline, spacing: 8) {
                Text("10 000+")
                    .font(AppFonts.title(40))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.green, .blue],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                Text("users")
                    .font(AppFonts.title3())
                    .foregroundColor(OnboardingColors.textSecondary)
            }
            .opacity(animateContent ? 1 : 0)
            .scaleEffect(animateContent ? 1 : 0.8)
            .animation(.spring(response: 0.5, dampingFraction: 0.7).delay(0.1), value: animateContent)
            
            // Rating
            HStack(spacing: 4) {
                ForEach(0..<5, id: \.self) { index in
                    Image(systemName: "star.fill")
                        .foregroundColor(.yellow)
                        .font(.system(size: 20))
                        .opacity(animateContent ? 1 : 0)
                        .scaleEffect(animateContent ? 1 : 0.5)
                        .animation(.spring(response: 0.4, dampingFraction: 0.6).delay(Double(index) * 0.08 + 0.2), value: animateContent)
                }
                Text("4.9")
                    .font(AppFonts.headline())
                    .foregroundColor(OnboardingColors.textPrimary)
                    .padding(.leading, 8)
            }
            .padding(.top, 8)
            
            // Testimonials
            VStack(spacing: 12) {
                ForEach(Array(testimonials.enumerated()), id: \.offset) { index, testimonial in
                    TestimonialCard(quote: testimonial.0, author: testimonial.1)
                        .opacity(animateContent ? 1 : 0)
                        .offset(x: animateContent ? 0 : (index % 2 == 0 ? -50 : 50))
                        .animation(.spring(response: 0.6, dampingFraction: 0.8).delay(Double(index) * 0.12 + 0.3), value: animateContent)
                }
            }
            .padding(.horizontal, 24)
            .padding(.top, 24)
            
            Spacer()
            
            // Trust badges
            HStack(spacing: 16) {
                TrustBadge(icon: "lock.shield.fill", text: "Privacy", color: .green)
                TrustBadge(icon: "checkmark.seal.fill", text: "No ads", color: .blue)
            }
            .opacity(animateContent ? 1 : 0)
            .animation(.easeOut(duration: 0.5).delay(0.5), value: animateContent)
            
            Spacer()
            Spacer()
        }
    }
}

struct TestimonialCard: View {
    let quote: String
    let author: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 2) {
                ForEach(0..<5, id: \.self) { _ in
                    Image(systemName: "star.fill")
                        .font(.system(size: 12))
                        .foregroundColor(.yellow)
                }
            }
            
            Text("\"\(quote)\"")
                .font(AppFonts.body())
                .foregroundColor(OnboardingColors.textPrimary)
                .italic()
            
            Text("— \(author)")
                .font(AppFonts.caption())
                .foregroundColor(OnboardingColors.textSecondary)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(OnboardingColors.surface)
        )
    }
}

struct TrustBadge: View {
    let icon: String
    let text: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 14))
                .foregroundColor(color)
            Text(text)
                .font(AppFonts.caption())
                .foregroundColor(OnboardingColors.textSecondary)
        }
    }
}

// MARK: - Page 8: Premium CTA
struct PremiumCTAPage: View {
    @ObservedObject var authManager: AuthenticationManager
    @Binding var animateContent: Bool
    @State private var isPulsing = false
    
    var body: some View {
        ZStack(alignment: .topTrailing) {
            VStack(spacing: 0) {
                Spacer()
                    .frame(height: 40)
                
                // Premium badge
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
                
                // Title
                VStack(spacing: 4) {
                    if !authManager.userName.isEmpty {
                        Text("\(authManager.userName),")
                            .font(AppFonts.title2())
                            .foregroundColor(OnboardingColors.primary)
                    }
                    Text("débloque tout")
                        .font(AppFonts.title())
                        .foregroundColor(OnboardingColors.textPrimary)
                    Text("le potentiel ! ✨")
                        .font(AppFonts.title())
                        .foregroundColor(OnboardingColors.textPrimary)
                }
                .multilineTextAlignment(.center)
                .padding(.top, 16)
                .opacity(animateContent ? 1 : 0)
                .offset(y: animateContent ? 0 : 20)
                .animation(.easeOut(duration: 0.5).delay(0.1), value: animateContent)
                
                // Features
                VStack(spacing: 14) {
                    PremiumFeatureRow(icon: "checkmark.circle.fill", text: "Tous les filtres illimités", color: .green)
                    PremiumFeatureRow(icon: "bolt.circle.fill", text: "Activation instantanée", color: .orange)
                    PremiumFeatureRow(icon: "arrow.triangle.2.circlepath.circle.fill", text: "Sync multi-appareils", color: .blue)
                    PremiumFeatureRow(icon: "heart.circle.fill", text: "Support prioritaire", color: .pink)
                }
                .padding(.vertical, 20)
                .padding(.horizontal, 20)
                .background(
                    RoundedRectangle(cornerRadius: 20)
                        .fill(OnboardingColors.surface)
                )
                .padding(.horizontal, 24)
                .padding(.top, 24)
                .opacity(animateContent ? 1 : 0)
                .offset(y: animateContent ? 0 : 30)
                .animation(.easeOut(duration: 0.5).delay(0.2), value: animateContent)
                
                Spacer()
                
                // Mascot with crown
                LessyMascotContainer(size: 120, showGlow: true, glowColor: .yellow)
                    .opacity(animateContent ? 1 : 0)
                    .animation(.easeOut(duration: 0.5).delay(0.3), value: animateContent)
                
                Spacer()
                
                // CTA Button
                VStack(spacing: 12) {
                    Button(action: {
                        Superwall.shared.register(placement: "campaign_trigger") {
                            authManager.completeOnboarding()
                        }
                    }) {
                        HStack(spacing: 8) {
                            Image(systemName: "crown.fill")
                            Text("Essai gratuit 3 jours")
                                .font(AppFonts.headline())
                        }
                        .foregroundColor(OnboardingColors.background)
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                        .background(
                            RoundedRectangle(cornerRadius: 28)
                                .fill(OnboardingColors.primary)
                        )
                        .scaleEffect(isPulsing ? 1.02 : 1)
                    }
                    .buttonStyle(OnboardingButtonStyle())
                    
                    Text("Annulable à tout moment")
                        .font(AppFonts.caption())
                        .foregroundColor(OnboardingColors.textSecondary)
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 40)
                .opacity(animateContent ? 1 : 0)
                .animation(.easeOut(duration: 0.5).delay(0.4), value: animateContent)
            }
            
            // Close button
            Button(action: {
                authManager.completeOnboarding()
            }) {
                Image(systemName: "xmark")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(OnboardingColors.textSecondary)
                    .frame(width: 32, height: 32)
                    .background(OnboardingColors.surface)
                    .clipShape(Circle())
            }
            .padding(.trailing, 20)
            .padding(.top, 16)
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
                isPulsing = true
            }
        }
    }
}

struct PremiumFeatureRow: View {
    let icon: String
    let text: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 22))
                .foregroundColor(color)
            
            Text(text)
                .font(AppFonts.body())
                .foregroundColor(OnboardingColors.textPrimary)
            
            Spacer()
        }
    }
}

// MARK: - Page 9: Let's Go
struct LetsGoPage: View {
    @ObservedObject var authManager: AuthenticationManager
    @Binding var animateContent: Bool
    @State private var showConfetti = false
    
    var body: some View {
        ZStack {
            VStack(spacing: 0) {
                Spacer()
                
                // Header
                VStack(spacing: 8) {
                    Text("Tu es prêt(e),")
                        .font(AppFonts.title())
                        .foregroundColor(OnboardingColors.textPrimary)
                    
                    if !authManager.userName.isEmpty {
                        Text("\(authManager.userName) ! 🚀")
                            .font(AppFonts.title())
                            .foregroundColor(OnboardingColors.primary)
                    }
                }
                .opacity(animateContent ? 1 : 0)
                .offset(y: animateContent ? 0 : 20)
                .animation(.easeOut(duration: 0.5), value: animateContent)
                
                // Goal recap
                VStack(spacing: 8) {
                    Text("Ton objectif :")
                        .font(AppFonts.subheadline())
                        .foregroundColor(OnboardingColors.textSecondary)
                    
                    HStack(spacing: 8) {
                        Text("Récupérer")
                            .foregroundColor(OnboardingColors.textSecondary)
                        Text("\(authManager.estimatedTimeSavedMinutes) min/jour")
                            .foregroundColor(.green)
                            .fontWeight(.bold)
                    }
                    .font(AppFonts.title3())
                }
                .padding(.vertical, 16)
                .padding(.horizontal, 24)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(OnboardingColors.surface)
                )
                .padding(.top, 24)
                .opacity(animateContent ? 1 : 0)
                .animation(.easeOut(duration: 0.5).delay(0.1), value: animateContent)
                
                Spacer()
                
                // Mascot saluting
                Image("mascott salut")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 180, height: 180)
                    .opacity(animateContent ? 1 : 0)
                    .scaleEffect(animateContent ? 1 : 0.8)
                    .animation(.spring(response: 0.6, dampingFraction: 0.7).delay(0.2), value: animateContent)
                
                // Message
                Text("\"Je serai toujours là pour t'encourager !\"")
                    .font(AppFonts.subheadline())
                    .foregroundColor(OnboardingColors.textSecondary)
                    .italic()
                    .padding(.top, 16)
                    .opacity(animateContent ? 1 : 0)
                    .animation(.easeOut(duration: 0.5).delay(0.3), value: animateContent)
                
                Spacer()
                
                // Start button
                Button(action: {
                    authManager.completeOnboarding()
                }) {
                    HStack(spacing: 8) {
                        Text("Commencer !")
                            .font(AppFonts.headline())
                        Image(systemName: "arrow.right")
                            .font(.system(size: 14, weight: .semibold))
                    }
                    .foregroundColor(OnboardingColors.background)
                    .frame(maxWidth: .infinity)
                    .frame(height: 56)
                    .background(
                        RoundedRectangle(cornerRadius: 28)
                            .fill(OnboardingColors.primary)
                    )
                }
                .buttonStyle(OnboardingButtonStyle())
                .padding(.horizontal, 24)
                .padding(.bottom, 40)
                .opacity(animateContent ? 1 : 0)
                .animation(.easeOut(duration: 0.5).delay(0.4), value: animateContent)
            }
            
            // Confetti overlay
            if showConfetti {
                ConfettiView()
                    .ignoresSafeArea()
                    .allowsHitTesting(false)
            }
        }
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                showConfetti = true
            }
        }
    }
}

// MARK: - Confetti View
struct ConfettiView: View {
    @State private var particles: [ConfettiParticle] = []
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                ForEach(particles) { particle in
                    Circle()
                        .fill(particle.color)
                        .frame(width: particle.size, height: particle.size)
                        .position(particle.position)
                        .opacity(particle.opacity)
                }
            }
            .onAppear {
                createParticles(in: geometry.size)
            }
        }
    }
    
    private func createParticles(in size: CGSize) {
        let colors: [Color] = [.pink, .purple, .blue, .green, .yellow, .orange, OnboardingColors.primary]
        
        for i in 0..<50 {
            let particle = ConfettiParticle(
                id: i,
                color: colors.randomElement()!,
                size: CGFloat.random(in: 4...10),
                position: CGPoint(x: CGFloat.random(in: 0...size.width), y: -20),
                opacity: 1
            )
            particles.append(particle)
            
            // Animate falling
            DispatchQueue.main.asyncAfter(deadline: .now() + Double(i) * 0.02) {
                withAnimation(.easeIn(duration: Double.random(in: 2...4))) {
                    if let index = particles.firstIndex(where: { $0.id == i }) {
                        particles[index].position.y = size.height + 50
                        particles[index].position.x += CGFloat.random(in: -100...100)
                        particles[index].opacity = 0
                    }
                }
            }
        }
    }
}

struct ConfettiParticle: Identifiable {
    let id: Int
    let color: Color
    let size: CGFloat
    var position: CGPoint
    var opacity: Double
}

// MARK: - Preview
#Preview {
    OnboardingView(authManager: AuthenticationManager())
}
