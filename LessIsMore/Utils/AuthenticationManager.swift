//
//  AuthenticationManager.swift
//  LessIsMore
//
//  Created by Angel Geoffroy on 03/09/2025.
//

import Foundation
import Combine

// MARK: - Onboarding Data Models
enum UserProblem: String, CaseIterable, Codable {
    case tooMuchTime = "too_much_time"
    case mindlessScrolling = "mindless_scrolling"
    case comparison = "comparison"
    case poorSleep = "poor_sleep"
    
    var displayText: String {
        switch self {
        case .tooMuchTime: return "Je perds trop de temps"
        case .mindlessScrolling: return "Je scrolle sans m'en rendre compte"
        case .comparison: return "Je me compare aux autres"
        case .poorSleep: return "Je dors mal à cause du scrolling nocturne"
        }
    }
    
    var emoji: String {
        switch self {
        case .tooMuchTime: return "😫"
        case .mindlessScrolling: return "😓"
        case .comparison: return "😔"
        case .poorSleep: return "😴"
        }
    }
}

enum UserGoal: String, CaseIterable, Codable {
    case reduceScreenTime = "reduce_screen_time"
    case stopScrolling = "stop_scrolling"
    case blockReels = "block_reels"
    case removeAlgorithm = "remove_algorithm"
    case lessAnxiety = "less_anxiety"
    
    var displayText: String {
        switch self {
        case .reduceScreenTime: return "Réduire mon temps écran"
        case .stopScrolling: return "Arrêter le scroll infini"
        case .blockReels: return "Bloquer les Reels"
        case .removeAlgorithm: return "Supprimer l'algo du feed"
        case .lessAnxiety: return "Moins d'anxiété sociale"
        }
    }
    
    var emoji: String {
        switch self {
        case .reduceScreenTime: return "⏱️"
        case .stopScrolling: return "🎯"
        case .blockReels: return "🎬"
        case .removeAlgorithm: return "🧠"
        case .lessAnxiety: return "😌"
        }
    }
    
    // Returns recommended filters based on this goal
    var recommendedFilters: [String] {
        switch self {
        case .reduceScreenTime: return ["reels", "explore", "stories"]
        case .stopScrolling: return ["reels", "explore"]
        case .blockReels: return ["reels"]
        case .removeAlgorithm: return ["explore", "forYouFeed"]
        case .lessAnxiety: return ["likes", "stories"]
        }
    }
}

class AuthenticationManager: ObservableObject {
    private let persistence: PersistenceService

    @Published var isAuthenticated: Bool {
        didSet {
            persistence.isAuthenticated = isAuthenticated
        }
    }

    @Published var hasSeenOnboarding: Bool {
        didSet {
            persistence.hasSeenOnboarding = hasSeenOnboarding
        }
    }
    
    // MARK: - Onboarding Data
    @Published var userName: String {
        didSet {
            UserDefaults.standard.set(userName, forKey: "onboarding_userName")
        }
    }
    
    @Published var userProblem: UserProblem? {
        didSet {
            if let problem = userProblem {
                UserDefaults.standard.set(problem.rawValue, forKey: "onboarding_userProblem")
            }
        }
    }
    
    @Published var userGoals: Set<UserGoal> {
        didSet {
            let rawValues = userGoals.map { $0.rawValue }
            UserDefaults.standard.set(rawValues, forKey: "onboarding_userGoals")
        }
    }
    
    @Published var dailyScreenTimeMinutes: Int {
        didSet {
            UserDefaults.standard.set(dailyScreenTimeMinutes, forKey: "onboarding_dailyScreenTime")
        }
    }

    init(persistence: PersistenceService = .shared) {
        self.persistence = persistence
        self.isAuthenticated = persistence.isAuthenticated
        self.hasSeenOnboarding = persistence.hasSeenOnboarding
        
        // Load onboarding data
        self.userName = UserDefaults.standard.string(forKey: "onboarding_userName") ?? ""
        
        if let problemRaw = UserDefaults.standard.string(forKey: "onboarding_userProblem") {
            self.userProblem = UserProblem(rawValue: problemRaw)
        } else {
            self.userProblem = nil
        }
        
        if let goalsRaw = UserDefaults.standard.stringArray(forKey: "onboarding_userGoals") {
            self.userGoals = Set(goalsRaw.compactMap { UserGoal(rawValue: $0) })
        } else {
            self.userGoals = []
        }
        
        self.dailyScreenTimeMinutes = UserDefaults.standard.integer(forKey: "onboarding_dailyScreenTime")
        if self.dailyScreenTimeMinutes == 0 {
            self.dailyScreenTimeMinutes = 120 // Default 2h
        }
    }
    
    // MARK: - Computed Properties
    var estimatedTimeSavedMinutes: Int {
        // Calculate based on selected goals and filters
        var totalMinutes = 0
        for goal in userGoals {
            switch goal {
            case .reduceScreenTime: totalMinutes += 45
            case .stopScrolling: totalMinutes += 30
            case .blockReels: totalMinutes += 45
            case .removeAlgorithm: totalMinutes += 20
            case .lessAnxiety: totalMinutes += 15
            }
        }
        return min(totalMinutes, dailyScreenTimeMinutes)
    }
    
    var recommendedFiltersFromGoals: Set<String> {
        var filters = Set<String>()
        for goal in userGoals {
            filters.formUnion(goal.recommendedFilters)
        }
        return filters
    }

    func logout() {
        isAuthenticated = false
        hasSeenOnboarding = false
        persistence.hasSeenSwipeTutorial = false
    }

    func login() {
        isAuthenticated = true
    }

    func completeOnboarding() {
        hasSeenOnboarding = true
    }

    func resetOnboarding() {
        hasSeenOnboarding = false
        persistence.hasSeenSwipeTutorial = false
        userName = ""
        userProblem = nil
        userGoals = []
        dailyScreenTimeMinutes = 120
    }
}
