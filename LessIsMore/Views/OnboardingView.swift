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
    // Monochrome DA (always dark): black background, white ink
    static let background = Color.black
    static let primary = Color.white
    static let surface = Color(hex: "1C1C1E")
    static let surfaceSelected = Color.white.opacity(0.12)
    static let textPrimary = Color.white
    static let textSecondary = Color(hex: "8E8E93")
    static let border = Color(hex: "2C2C2E")
    static let borderSelected = Color.white
}

// MARK: - Main Onboarding View
struct OnboardingView: View {
    @ObservedObject var authManager: AuthenticationManager
    @StateObject private var subscriptionManager = SubscriptionManager()
    @State private var currentPage = 0
    @State private var animateContent = false
    
    // Total pages: 10 for premium users (no paywall), 11 for free users
    private var totalPages: Int {
        subscriptionManager.isPremium ? 10 : 11
    }
    
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
                    
                    // Page 8: Notification Permission
                    NotificationPermissionPage(animateContent: $animateContent, onContinue: { goToNextPage() })
                        .tag(8)
                    
                    // Page 9: Let's Go (final page for premium users)
                    LetsGoPage(authManager: authManager, animateContent: $animateContent, isPremium: subscriptionManager.isPremium, onComplete: {
                        MixpanelManager.shared.trackOnboardingCompleted()
                        authManager.completeOnboarding()
                    })
                        .tag(9)
                    
                    // Page 10: Superwall Paywall (only for non-premium users)
                    if !subscriptionManager.isPremium {
                        SuperwallPaywallPage(authManager: authManager, animateContent: $animateContent)
                            .tag(10)
                    }
                }
                .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
                .animation(.easeInOut(duration: 0.3), value: currentPage)
            }
            
            // Back button overlay (top left, below progress bar)
            if currentPage > 1 && currentPage < totalPages - 1 {
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
                                Text("onboarding.back".localized)
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
            trackCurrentPage()
        }
        .onChange(of: currentPage) {
            triggerAnimation()
            trackCurrentPage()
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
    
    private func trackCurrentPage() {
        let pageNames = [
            "welcome",
            "name",
            "problem",
            "goals",
            "screen_time",
            "filters",
            "projection",
            "social_proof",
            "notifications",
            "lets_go",
            "paywall"
        ]
        
        guard currentPage < pageNames.count else { return }
        MixpanelManager.shared.trackOnboardingPage(currentPage, pageName: pageNames[currentPage])
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
    @StateObject private var subscriptionManager = SubscriptionManager()
    
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
        // Page 8 (notifications) has custom button
        // Page 9 for premium users has custom button (no paywall follows)
        // Page 10 (Superwall paywall) has no footer button
        if currentPage == 8 { return false }
        if currentPage == 9 && subscriptionManager.isPremium { return false }
        if currentPage == 10 { return false }
        return true
    }
    
    private var mainButtonText: String {
        switch currentPage {
        case 0: return "common.continue".localized
        case 7: return "onboarding.social.joinTeam".localized
        case 9: return "onboarding.final.start".localized
        default: return "common.continue".localized
        }
    }
    
    private func handleMainButtonAction() {
        withAnimation(.easeInOut(duration: 0.4)) {
            // If on page 9 (LetsGo) and user is already premium, skip paywall and complete onboarding
            if currentPage == 9 && subscriptionManager.isPremium {
                MixpanelManager.shared.trackOnboardingCompleted()
                authManager.completeOnboarding()
            } else if currentPage < totalPages - 1 {
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
            VStack(alignment: .leading, spacing: 0) {
                Text("onboarding.welcome.greeting".localized)
                    .font(.system(size: 52, weight: .bold))
                    .foregroundColor(OnboardingColors.textPrimary)

                Text("onboarding.welcome.line1".localized)
                    .font(.system(size: 52, weight: .bold))
                    .foregroundColor(OnboardingColors.textSecondary)

                VStack(alignment: .leading, spacing: 2) {
                    Text("onboarding.welcome.line2".localized)
                    Text("onboarding.welcome.line3".localized)
                }
                .font(.system(size: 19, weight: .medium))
                .foregroundColor(OnboardingColors.textSecondary)
                .padding(.top, 20)
            }
            .minimumScaleFactor(0.7)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 24)
            .opacity(animateContent ? 1 : 0)
            .offset(y: animateContent ? 0 : 20)
            .animation(.easeOut(duration: 0.5), value: animateContent)
            
            Spacer()            
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
            Text("onboarding.name.question".localized)
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
                
                Text(String(format: "onboarding.name.charCount".localized, authManager.userName.count))
                    .font(AppFonts.caption())
                    .foregroundColor(OnboardingColors.textSecondary)
            }
            .padding(.horizontal, 24)
            .padding(.top, 16)
            .opacity(animateContent ? 1 : 0)
            .animation(.easeOut(duration: 0.5).delay(0.1), value: animateContent)
            
            Spacer()            
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
                Text("onboarding.problem.questionPart1".localized)
                    .font(AppFonts.title2())
                    .foregroundColor(OnboardingColors.textPrimary)
                Text("onboarding.problem.questionPart2".localized)
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
                Text("onboarding.goals.question".localized)
                    .font(AppFonts.title2())
                    .foregroundColor(OnboardingColors.textPrimary)
                Text("onboarding.goals.selectAll".localized)
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
                Text("onboarding.screenTime.question1".localized)
                    .font(AppFonts.title2())
                    .foregroundColor(OnboardingColors.textPrimary)
                Text("onboarding.screenTime.question2".localized)
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
                
                Text("onboarding.screenTime.perDay".localized)
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
            
            // Reaction message
            VStack(spacing: 12) {
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
        case 0...60: return .white.opacity(0.45)
        case 61...120: return .white.opacity(0.65)
        case 121...180: return .white.opacity(0.85)
        default: return .white
        }
    }
    
    private var reactionMessage: String {
        switch authManager.dailyScreenTimeMinutes {
        case 0...60: return "onboarding.screenTime.reaction1".localized
        case 61...120: return "onboarding.screenTime.reaction2".localized
        case 121...180: return "onboarding.screenTime.reaction3".localized
        default: return "onboarding.screenTime.reaction4".localized
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
        ("reels", "film.fill", "Reels", 45, .white),
        ("explore", "safari.fill", "Explore", 20, .white),
        ("stories", "circle.dashed", "Stories", 15, .white),
        ("likes", "heart.fill", "Likes", 10, .white)
    ]
    
    var body: some View {
        VStack(spacing: 0) {
            Spacer()
                .frame(height: 40)
            
            // Header
            HStack(alignment: .top, spacing: 12) {
                VStack(alignment: .leading, spacing: 4) {
                    if !authManager.userName.isEmpty {
                        Text("\(authManager.userName),")
                            .font(AppFonts.title2())
                            .foregroundColor(OnboardingColors.primary)
                    }
                    Text("onboarding.filters.myRecommendations".localized)
                        .font(AppFonts.title2())
                        .foregroundColor(OnboardingColors.textPrimary)
                    Text("onboarding.filters.forYou".localized)
                        .font(AppFonts.title2())
                        .foregroundColor(OnboardingColors.textPrimary)
                }            }
            .padding(.horizontal, 24)
            .opacity(animateContent ? 1 : 0)
            .offset(y: animateContent ? 0 : 20)
            
            Text("onboarding.filters.tapToBlock".localized)
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
                            .foregroundColor(.white)
                        Text(String(format: "filter.filtersBlocked".localized, selectedFilters.count))
                            .font(AppFonts.subheadline())
                            .foregroundColor(OnboardingColors.textSecondary)
                    }
                    
                    HStack(spacing: 4) {
                        Text("≈")
                            .foregroundColor(OnboardingColors.textSecondary)
                        Text("\(totalTimeSaved) min")
                            .font(AppFonts.headline())
                            .foregroundColor(.white)
                        Text(String(format: "filter.minSavedPerDay".localized, totalTimeSaved))
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
                        .foregroundColor(isSelected ? OnboardingColors.background : color)
                }
                
                Text(title)
                    .font(AppFonts.headline())
                    .foregroundColor(isSelected ? color : OnboardingColors.textPrimary)
                
                Text("-\(timeSaved) min")
                    .font(AppFonts.caption())
                    .foregroundColor(OnboardingColors.textSecondary)
                
                if isRecommended && !isSelected {
                    Text("onboarding.filters.recommended".localized)
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
                Text("onboarding.projection.in30Days".localized)
                    .font(AppFonts.title2())
                    .foregroundColor(OnboardingColors.textPrimary)
                Text("onboarding.projection.youWillRecover".localized)
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
                    .foregroundColor(.white)
                    .contentTransition(.numericText())
                
                Text("onboarding.projection.ofYourLife".localized)
                    .font(AppFonts.title3())
                    .foregroundColor(OnboardingColors.textSecondary)
            }
            .opacity(animateContent ? 1 : 0)
            .scaleEffect(animateContent ? 1 : 0.8)
            .animation(.spring(response: 0.6, dampingFraction: 0.7).delay(0.2), value: animateContent)
            
            // Equivalences
            VStack(spacing: 12) {
                Text("onboarding.projection.equivalent".localized)
                    .font(AppFonts.subheadline())
                    .foregroundColor(OnboardingColors.textSecondary)
                
                VStack(spacing: 8) {
                    EquivalenceCard(emoji: "📚", text: String(format: "onboarding.projection.booksRead".localized, max(projectedHours / 4, 1)))
                    EquivalenceCard(emoji: "🏃", text: String(format: "onboarding.projection.workoutSessions".localized, max(projectedHours / 2, 1)))
                    EquivalenceCard(emoji: "😴", text: String(format: "onboarding.projection.extraNights".localized, max(projectedHours / 8, 1)))
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
        ("onboarding.social.testimonial1".localized, "onboarding.social.author1".localized),
        ("onboarding.social.testimonial2".localized, "onboarding.social.author2".localized)
    ]
    
    var body: some View {
        VStack(spacing: 0) {
            Spacer()
                .frame(height: 60)
            
            // Header
            Text("onboarding.social.notAlone".localized)
                .font(AppFonts.title2())
                .foregroundColor(OnboardingColors.textPrimary)
                .frame(maxWidth: .infinity, alignment: .center)
                .padding(.horizontal, 24)
                .opacity(animateContent ? 1 : 0)
                .offset(y: animateContent ? 0 : 20)
            
            Text("onboarding.social.join".localized)
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
                            colors: [.white, .white.opacity(0.6)],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                Text("onboarding.social.users".localized)
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
                        .foregroundColor(.white)
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
                TrustBadge(icon: "lock.shield.fill", text: "onboarding.social.privacy".localized, color: .white)
                TrustBadge(icon: "checkmark.seal.fill", text: "onboarding.social.noAds".localized, color: .white)
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
                        .foregroundColor(.white)
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
    var onContinue: () -> Void
    @State private var isPulsing = false
    
    var body: some View {
        ZStack(alignment: .topTrailing) {
            VStack(spacing: 0) {
                Spacer()
                    .frame(height: 40)
                
                // Premium badge
                HStack(spacing: 8) {
                    Image(systemName: "crown.fill")
                        .foregroundColor(.white)
                    Text("onboarding.premium.badge".localized)
                        .font(AppFonts.caption())
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(Color.white.opacity(0.12))
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
                    Text("onboarding.premium.unlockAll".localized)
                        .font(AppFonts.title())
                        .foregroundColor(OnboardingColors.textPrimary)
                    Text("onboarding.premium.potential".localized)
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
                    PremiumFeatureRow(icon: "checkmark.circle.fill", text: "onboarding.premium.allFilters".localized, color: .white)
                    PremiumFeatureRow(icon: "bolt.circle.fill", text: "onboarding.premium.instantActivation".localized, color: .white)
                    PremiumFeatureRow(icon: "arrow.triangle.2.circlepath.circle.fill", text: "onboarding.premium.multiDevice".localized, color: .white)
                    PremiumFeatureRow(icon: "heart.circle.fill", text: "onboarding.premium.prioritySupport".localized, color: .white)
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
                Spacer()
                
                // CTA Button
                VStack(spacing: 12) {
                    Button(action: {
                        // Navigate to the paywall page instead of showing modal
                        onContinue()
                    }) {
                        HStack(spacing: 8) {
                            Image(systemName: "crown.fill")
                            Text("onboarding.premium.freeTrial".localized)
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
                    
                    Text("onboarding.premium.cancelAnytime".localized)
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

// MARK: - Page 8: Notification Permission
struct NotificationPermissionPage: View {
    @Binding var animateContent: Bool
    var onContinue: () -> Void
    @StateObject private var notificationManager = NotificationManager.shared
    @State private var bellRotation: Double = 0
    @State private var isRequestingPermission = false
    
    var body: some View {
        VStack(spacing: 0) {
            Spacer()
                .frame(height: 60)
            
            // Title - multiline, no subtitle
            VStack(alignment: .leading, spacing: 4) {
                Text("onboarding.notifications.title".localized)
                    .font(AppFonts.title2())
                    .foregroundColor(OnboardingColors.textPrimary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 24)
            .opacity(animateContent ? 1 : 0)
            .offset(y: animateContent ? 0 : 20)
            
            Spacer()
            
            // Bell icon - simple and big
            Image(systemName: "bell.badge.fill")
                .font(.system(size: 100))
                .foregroundStyle(OnboardingColors.primary, .white)
                .rotationEffect(.degrees(bellRotation))
                .opacity(animateContent ? 1 : 0)
                .scaleEffect(animateContent ? 1 : 0.8)
                .animation(.spring(response: 0.6, dampingFraction: 0.7).delay(0.1), value: animateContent)
                .onAppear {
                    // Bell ringing animation
                    withAnimation(.easeInOut(duration: 0.1).repeatCount(6, autoreverses: true).delay(0.5)) {
                        bellRotation = 15
                    }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.1) {
                        withAnimation(.easeInOut(duration: 0.1)) {
                            bellRotation = 0
                        }
                    }
                }
            
            Spacer()
                .frame(height: 32)
            
            // Benefits list - vertical, no background
            VStack(spacing: 16) {
                NotificationBenefitRow(
                    icon: "moon.fill",
                    title: "onboarding.notifications.benefit1.title".localized,
                    description: "onboarding.notifications.benefit1.desc".localized,
                    color: .white
                )
                .opacity(animateContent ? 1 : 0)
                .offset(y: animateContent ? 0 : 20)
                .animation(.easeOut(duration: 0.4).delay(0.2), value: animateContent)
                
                NotificationBenefitRow(
                    icon: "sun.max.fill",
                    title: "onboarding.notifications.benefit2.title".localized,
                    description: "onboarding.notifications.benefit2.desc".localized,
                    color: .white
                )
                .opacity(animateContent ? 1 : 0)
                .offset(y: animateContent ? 0 : 20)
                .animation(.easeOut(duration: 0.4).delay(0.3), value: animateContent)
                
                NotificationBenefitRow(
                    icon: "bed.double.fill",
                    title: "onboarding.notifications.benefit3.title".localized,
                    description: "onboarding.notifications.benefit3.desc".localized,
                    color: .white
                )
                .opacity(animateContent ? 1 : 0)
                .offset(y: animateContent ? 0 : 20)
                .animation(.easeOut(duration: 0.4).delay(0.4), value: animateContent)
            }
            .padding(.horizontal, 24)
            
            Spacer()
            
            // Buttons
            VStack(spacing: 12) {
                // Enable notifications button
                Button(action: {
                    requestNotificationPermission()
                }) {
                    HStack(spacing: 8) {
                        if isRequestingPermission {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: OnboardingColors.background))
                        } else {
                            Image(systemName: "bell.fill")
                            Text("onboarding.notifications.enable".localized)
                                .font(AppFonts.headline())
                        }
                    }
                    .foregroundColor(OnboardingColors.background)
                    .frame(maxWidth: .infinity)
                    .frame(height: 56)
                    .background(
                        RoundedRectangle(cornerRadius: 28)
                            .fill(OnboardingColors.primary)
                    )
                }
                .disabled(isRequestingPermission)
                .buttonStyle(OnboardingButtonStyle())
                
                // Skip button
                Button(action: {
                    onContinue()
                }) {
                    Text("onboarding.notifications.skip".localized)
                        .font(AppFonts.subheadline())
                        .foregroundColor(OnboardingColors.textSecondary)
                }
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 40)
            .opacity(animateContent ? 1 : 0)
            .animation(.easeOut(duration: 0.5).delay(0.5), value: animateContent)
        }
    }
    
    private func requestNotificationPermission() {
        isRequestingPermission = true
        
        notificationManager.requestAuthorization { granted in
            isRequestingPermission = false
            
            // Track the result
            MixpanelManager.shared.trackNotificationPermission(granted: granted)
            
            // Continue to next page regardless of result
            onContinue()
        }
    }
}

struct NotificationBenefitRow: View {
    let icon: String
    let title: String
    let description: String
    let color: Color
    
    var body: some View {
        HStack(alignment: .top, spacing: 14) {
            ZStack {
                Circle()
                    .fill(color.opacity(0.15))
                    .frame(width: 44, height: 44)
                
                Image(systemName: icon)
                    .font(.system(size: 20))
                    .foregroundColor(color)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(AppFonts.headline())
                    .foregroundColor(OnboardingColors.textPrimary)
                
                Text(description)
                    .font(AppFonts.caption())
                    .foregroundColor(OnboardingColors.textSecondary)
                    .lineLimit(2)
            }
            
            Spacer()
        }
    }
}

// MARK: - Page 9: Let's Go
struct LetsGoPage: View {
    @ObservedObject var authManager: AuthenticationManager
    @Binding var animateContent: Bool
    var isPremium: Bool = false
    var onComplete: (() -> Void)? = nil
    @State private var showConfetti = false
    
    var body: some View {
        ZStack {
            VStack(spacing: 0) {
                Spacer()
                
                // Header
                VStack(spacing: 8) {
                    Text("onboarding.final.ready".localized)
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
                    Text("onboarding.final.yourGoal".localized)
                        .font(AppFonts.subheadline())
                        .foregroundColor(OnboardingColors.textSecondary)
                    
                    HStack(spacing: 8) {
                        Text("onboarding.final.recover".localized)
                            .foregroundColor(OnboardingColors.textSecondary)
                        Text(String(format: "onboarding.final.minPerDay".localized, authManager.estimatedTimeSavedMinutes))
                            .foregroundColor(.white)
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
                // Premium users see a completion button here (since no paywall follows)
                if isPremium {
                    Spacer()
                        .frame(height: 20)
                    
                    Button(action: {
                        onComplete?()
                    }) {
                        Text("onboarding.final.start".localized)
                            .font(AppFonts.headline())
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
                    .opacity(animateContent ? 1 : 0)
                    .animation(.easeOut(duration: 0.5).delay(0.4), value: animateContent)
                }
                
                Spacer()
                    .frame(height: isPremium ? 40 : 100)
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
        let colors: [Color] = [.white, .white.opacity(0.8), .white.opacity(0.6), Color(hex: "8E8E93"), .white.opacity(0.4)]
        
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

// MARK: - Page 10: Superwall Paywall
struct SuperwallPaywallPage: View {
    @ObservedObject var authManager: AuthenticationManager
    @Binding var animateContent: Bool
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        ZStack {
            // Background matching onboarding style
            OnboardingColors.background
                .ignoresSafeArea()
            
            // PaywallView from Superwall with dismissal handling
            PaywallView(
                placement: "campaign_trigger",
                onRequestDismiss: { info, result in
                    // Track onboarding completion when user closes paywall
                    MixpanelManager.shared.trackOnboardingCompleted()
                    
                    // Complete onboarding
                    authManager.completeOnboarding()
                }
            )
            .opacity(animateContent ? 1 : 0)
        }
        .onAppear {
            // Track paywall view
            MixpanelManager.shared.trackPaywallViewed(placement: "onboarding")
        }
    }
}


// MARK: - Preview
#Preview {
    OnboardingView(authManager: AuthenticationManager())
}
