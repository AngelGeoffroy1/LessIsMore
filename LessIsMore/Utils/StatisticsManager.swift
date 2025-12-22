//
//  StatisticsManager.swift
//  LessIsMore
//
//  Created by Angel Geoffroy on 22/12/2025.
//

import Foundation
import SwiftUI

// MARK: - Statistiques de temps économisé par filtre

struct FilterStatistics: Identifiable {
    let id = UUID()
    let filterType: FilterType
    let dailyMinutesSaved: Int
    let activationDate: Date?
    let color: Color
    let isSimulated: Bool
    
    var totalMinutesSaved: Int {
        guard let activationDate = activationDate else { return 0 }
        let daysSinceActivation = Calendar.current.dateComponents([.day], from: activationDate, to: Date()).day ?? 0
        return max(0, daysSinceActivation * dailyMinutesSaved)
    }
    
    var totalHoursSaved: Double {
        return Double(totalMinutesSaved) / 60.0
    }
    
    var formattedTime: String {
        let hours = totalMinutesSaved / 60
        let minutes = totalMinutesSaved % 60
        if hours > 0 {
            return "\(hours)h \(minutes)min"
        }
        return "\(minutes)min"
    }
}

// MARK: - Manager des statistiques

class StatisticsManager: ObservableObject {
    
    static let shared = StatisticsManager()
    
    // Temps moyen économisé par jour pour chaque filtre (en minutes)
    private let dailySavings: [FilterType: Int] = [
        .reels: 15,      // Reels sont très addictifs
        .stories: 10,    // Stories consomment beaucoup de temps
        .explore: 8,     // Page Explore peut être chronophage
        .suggestions: 5, // Suggestions créent des distractions
        .likes: 3,       // Masquer les likes réduit la comparaison sociale
        .following: 5,   // Mode Following réduit les contenus algorithmiques
        .messages: 4     // Masquer les messages réduit les interruptions
    ]
    
    // Couleurs pour chaque filtre
    private let filterColors: [FilterType: Color] = [
        .reels: .pink,
        .stories: .purple,
        .explore: .orange,
        .suggestions: .blue,
        .likes: .red,
        .following: .green,
        .messages: .cyan
    ]
    
    @Published var statistics: [FilterStatistics] = []
    @Published var isSimulationMode: Bool = true
    
    private let persistence = PersistenceService.shared
    
    init() {
        loadStatistics()
    }
    
    // MARK: - Mode Simulation
    
    /// Statistiques simulées sur 7 jours avec tous les filtres actifs
    var simulatedStatistics: [FilterStatistics] {
        let sevenDaysAgo = Calendar.current.date(byAdding: .day, value: -7, to: Date()) ?? Date()
        
        return FilterType.allCases.map { filterType in
            FilterStatistics(
                filterType: filterType,
                dailyMinutesSaved: dailySavings[filterType] ?? 5,
                activationDate: sevenDaysAgo,
                color: filterColors[filterType] ?? .gray,
                isSimulated: true
            )
        }
    }
    
    /// Retourne les statistiques à afficher (réelles ou simulées)
    var displayStatistics: [FilterStatistics] {
        if isSimulationMode || statistics.isEmpty {
            return simulatedStatistics
        }
        return statistics
    }
    
    /// Vérifie si l'utilisateur a des données réelles
    var hasRealData: Bool {
        return !statistics.isEmpty
    }
    
    // MARK: - Public Methods
    
    /// Recharge les statistiques depuis la persistance
    func loadStatistics() {
        statistics = FilterType.allCases.compactMap { filterType in
            guard filterType.isEnabled else { return nil }
            
            let activationDate = getFilterActivationDate(for: filterType)
            
            return FilterStatistics(
                filterType: filterType,
                dailyMinutesSaved: dailySavings[filterType] ?? 5,
                activationDate: activationDate,
                color: filterColors[filterType] ?? .gray,
                isSimulated: false
            )
        }
        
        // Si pas de données réelles, rester en mode simulation
        if statistics.isEmpty {
            isSimulationMode = true
        }
    }
    
    /// Bascule entre mode simulation et mode réel
    func toggleSimulationMode() {
        // Ne permettre de désactiver la simulation que s'il y a des données réelles
        if isSimulationMode && !hasRealData {
            return
        }
        isSimulationMode.toggle()
    }
    
    /// Enregistre la date d'activation d'un filtre
    func recordFilterActivation(for filterType: FilterType) {
        let key = "filter_activation_\(filterType.rawValue)"
        if persistence.getString(forKey: key) == nil {
            let dateString = ISO8601DateFormatter().string(from: Date())
            persistence.setString(dateString, forKey: key)
        }
        loadStatistics()
    }
    
    /// Récupère la date d'activation d'un filtre
    func getFilterActivationDate(for filterType: FilterType) -> Date? {
        let key = "filter_activation_\(filterType.rawValue)"
        guard let dateString = persistence.getString(forKey: key) else {
            // Si pas de date enregistrée mais filtre actif, utiliser aujourd'hui
            if filterType.isEnabled {
                let now = Date()
                persistence.setString(ISO8601DateFormatter().string(from: now), forKey: key)
                return now
            }
            return nil
        }
        return ISO8601DateFormatter().date(from: dateString)
    }
    
    /// Réinitialise la date d'activation d'un filtre
    func resetFilterActivation(for filterType: FilterType) {
        let key = "filter_activation_\(filterType.rawValue)"
        persistence.remove(forKey: key)
        loadStatistics()
    }
    
    // MARK: - Computed Properties (basées sur displayStatistics)
    
    /// Temps total économisé en minutes
    var totalMinutesSaved: Int {
        displayStatistics.reduce(0) { $0 + $1.totalMinutesSaved }
    }
    
    /// Temps total économisé en heures
    var totalHoursSaved: Double {
        Double(totalMinutesSaved) / 60.0
    }
    
    /// Nombre de filtres actifs
    var activeFiltersCount: Int {
        displayStatistics.count
    }
    
    /// Temps économisé cette semaine (estimation basée sur les filtres actifs)
    var weeklyMinutesSaved: Int {
        let dailyTotal = displayStatistics.reduce(0) { $0 + $1.dailyMinutesSaved }
        return dailyTotal * 7
    }
    
    /// Temps économisé ce mois (estimation basée sur les filtres actifs)
    var monthlyMinutesSaved: Int {
        let dailyTotal = displayStatistics.reduce(0) { $0 + $1.dailyMinutesSaved }
        return dailyTotal * 30
    }
    
    /// Formatage du temps total
    var formattedTotalTime: String {
        let hours = totalMinutesSaved / 60
        let minutes = totalMinutesSaved % 60
        if hours > 0 {
            return "\(hours)h \(minutes)min"
        }
        return "\(minutes)min"
    }
    
    /// Retourne les statistiques triées par temps économisé
    var sortedStatistics: [FilterStatistics] {
        displayStatistics.sorted { $0.totalMinutesSaved > $1.totalMinutesSaved }
    }
}
