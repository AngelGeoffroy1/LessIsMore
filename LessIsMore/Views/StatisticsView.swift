//
//  StatisticsView.swift
//  LessIsMore
//
//  Created by Angel Geoffroy on 22/12/2025.
//

import SwiftUI

struct StatisticsView: View {
    @StateObject private var statisticsManager = StatisticsManager.shared
    @Environment(\.presentationMode) var presentationMode
    @Environment(\.colorScheme) var colorScheme
    
    @State private var animateContent = false
    @State private var animatedMinutes: Int = 0
    
    var body: some View {
        NavigationView {
            ZStack {
                // Fond avec dégradé animé
                AnimatedStatisticsBackground()
                    .ignoresSafeArea()
                
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 24) {
                        // Badge mode simulation
                        SimulationModeBadge(
                            isSimulationMode: statisticsManager.isSimulationMode,
                            hasRealData: statisticsManager.hasRealData,
                            onToggle: {
                                withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                                    statisticsManager.toggleSimulationMode()
                                    animatedMinutes = 0
                                    startCounterAnimation()
                                }
                            }
                        )
                        .padding(.top, 12)
                        
                        // Header avec temps total
                        TotalTimeSavedCard(
                            totalMinutes: animatedMinutes,
                            isSimulation: statisticsManager.isSimulationMode,
                            animateContent: $animateContent
                        )
                        
                        // Graphique en barres
                        FilterBarChart(
                            statistics: statisticsManager.sortedStatistics,
                            animateContent: $animateContent
                        )
                        
                        // Répartition circulaire
                        TimeSavedPieChart(
                            statistics: statisticsManager.displayStatistics,
                            animateContent: $animateContent
                        )
                        
                        // Gains estimés
                        EstimatedGainsCard(
                            weeklyMinutes: statisticsManager.weeklyMinutesSaved,
                            monthlyMinutes: statisticsManager.monthlyMinutesSaved,
                            animateContent: $animateContent
                        )
                        
                        Spacer()
                            .frame(height: 40)
                    }
                    .padding(.horizontal, 20)
                }
            }
            .navigationTitle("Statistiques")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(
                trailing: Button("Fermer") {
                    presentationMode.wrappedValue.dismiss()
                }
            )
        }
        .navigationViewStyle(StackNavigationViewStyle())
        .onAppear {
            statisticsManager.loadStatistics()
            startCounterAnimation()
            withAnimation(.easeOut(duration: 0.6).delay(0.2)) {
                animateContent = true
            }
        }
    }
    
    private func startCounterAnimation() {
        let targetMinutes = statisticsManager.totalMinutesSaved
        guard targetMinutes > 0 else { return }
        
        let steps = min(50, targetMinutes)
        let stepValue = max(1, targetMinutes / steps)
        let stepDuration = 1.0 / Double(steps)
        
        Timer.scheduledTimer(withTimeInterval: stepDuration, repeats: true) { timer in
            if animatedMinutes < targetMinutes {
                animatedMinutes = min(animatedMinutes + stepValue, targetMinutes)
            } else {
                animatedMinutes = targetMinutes
                timer.invalidate()
            }
        }
    }
}

// MARK: - Badge mode simulation

struct SimulationModeBadge: View {
    let isSimulationMode: Bool
    let hasRealData: Bool
    let onToggle: () -> Void
    
    var body: some View {
        Button(action: onToggle) {
            HStack(spacing: 10) {
                Image(systemName: isSimulationMode ? "eye.fill" : "chart.line.uptrend.xyaxis")
                    .font(.system(size: 14, weight: .semibold))
                
                Text(isSimulationMode ? "Mode Prévisualisation (7 jours)" : "Vos données réelles")
                    .font(AppFonts.caption())
                    .fontWeight(.medium)
                
                if hasRealData {
                    Image(systemName: "arrow.left.arrow.right")
                        .font(.system(size: 10))
                        .foregroundColor(.secondary)
                }
            }
            .foregroundColor(isSimulationMode ? .orange : .green)
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(
                Capsule()
                    .fill(isSimulationMode ? Color.orange.opacity(0.15) : Color.green.opacity(0.15))
                    .overlay(
                        Capsule()
                            .stroke(isSimulationMode ? Color.orange.opacity(0.3) : Color.green.opacity(0.3), lineWidth: 1)
                    )
            )
        }
        .buttonStyle(ScaleButtonStyle())
        .disabled(!hasRealData && !isSimulationMode)
    }
}

// MARK: - Fond animé

struct AnimatedStatisticsBackground: View {
    @State private var animateGradient = false
    
    var body: some View {
        LinearGradient(
            colors: [
                Color.green.opacity(0.08),
                Color.blue.opacity(0.06),
                Color.purple.opacity(0.04)
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

// MARK: - Carte temps total économisé

struct TotalTimeSavedCard: View {
    let totalMinutes: Int
    var isSimulation: Bool = false
    @Binding var animateContent: Bool
    
    private var hours: Int { totalMinutes / 60 }
    private var minutes: Int { totalMinutes % 60 }
    
    var body: some View {
        VStack(spacing: 16) {
            // Icône
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [.green, .blue],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 80, height: 80)
                    .shadow(color: .green.opacity(0.4), radius: 15, x: 0, y: 8)
                
                Image(systemName: "clock.badge.checkmark.fill")
                    .font(.system(size: 35))
                    .foregroundColor(.white)
            }
            .scaleEffect(animateContent ? 1 : 0.5)
            .opacity(animateContent ? 1 : 0)
            
            VStack(spacing: 8) {
                Text("Temps économisé")
                    .font(AppFonts.subheadline())
                    .foregroundColor(.secondary)
                
                // Compteur animé
                HStack(alignment: .firstTextBaseline, spacing: 4) {
                    if hours > 0 {
                        Text("\(hours)")
                            .font(AppFonts.title(50))
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [.green, .blue],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .contentTransition(.numericText())
                        
                        Text("h")
                            .font(AppFonts.title3())
                            .foregroundColor(.secondary)
                    }
                    
                    Text("\(minutes)")
                        .font(AppFonts.title(hours > 0 ? 30 : 50))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [.green, .blue],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .contentTransition(.numericText())
                    
                    Text("min")
                        .font(AppFonts.title3())
                        .foregroundColor(.secondary)
                }
                
                if totalMinutes > 0 {
                    Text(isSimulation ? "estimation sur 7 jours avec tous les filtres" : "depuis l'activation des filtres")
                        .font(AppFonts.caption())
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding(.vertical, 24)
        .padding(.horizontal, 20)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color(.systemBackground))
                .shadow(color: Color.black.opacity(0.08), radius: 20, x: 0, y: 10)
        )
        .opacity(animateContent ? 1 : 0)
        .offset(y: animateContent ? 0 : 30)
        .animation(.spring(response: 0.6, dampingFraction: 0.8), value: animateContent)
    }
}

// MARK: - Graphique en barres

struct FilterBarChart: View {
    let statistics: [FilterStatistics]
    @Binding var animateContent: Bool
    
    private var maxMinutes: Int {
        statistics.map { $0.totalMinutesSaved }.max() ?? 1
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Par filtre")
                .font(AppFonts.headline())
                .padding(.horizontal, 4)
            
            VStack(spacing: 12) {
                ForEach(Array(statistics.enumerated()), id: \.element.id) { index, stat in
                    FilterBarRow(
                        stat: stat,
                        maxMinutes: maxMinutes,
                        animateContent: animateContent,
                        delay: Double(index) * 0.1
                    )
                }
            }
        }
        .padding(.vertical, 20)
        .padding(.horizontal, 16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemGray6).opacity(0.5))
        )
        .opacity(animateContent ? 1 : 0)
        .offset(y: animateContent ? 0 : 30)
        .animation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.1), value: animateContent)
    }
}

struct FilterBarRow: View {
    let stat: FilterStatistics
    let maxMinutes: Int
    let animateContent: Bool
    let delay: Double
    
    @State private var barWidth: CGFloat = 0
    
    private var targetWidth: CGFloat {
        guard maxMinutes > 0 else { return 0 }
        return CGFloat(stat.totalMinutesSaved) / CGFloat(maxMinutes)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(stat.filterType.displayName)
                    .font(AppFonts.subheadline())
                    .foregroundColor(.primary)
                
                Spacer()
                
                Text(stat.formattedTime)
                    .font(AppFonts.caption())
                    .foregroundColor(.secondary)
            }
            
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    // Fond
                    RoundedRectangle(cornerRadius: 6)
                        .fill(Color(.systemGray5))
                        .frame(height: 12)
                    
                    // Barre colorée
                    RoundedRectangle(cornerRadius: 6)
                        .fill(
                            LinearGradient(
                                colors: [stat.color, stat.color.opacity(0.7)],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: geometry.size.width * barWidth, height: 12)
                }
            }
            .frame(height: 12)
        }
        .onAppear {
            withAnimation(.spring(response: 0.8, dampingFraction: 0.7).delay(delay + 0.3)) {
                barWidth = targetWidth
            }
        }
    }
}

// MARK: - Graphique circulaire

struct TimeSavedPieChart: View {
    let statistics: [FilterStatistics]
    @Binding var animateContent: Bool
    
    private var totalMinutes: Int {
        statistics.reduce(0) { $0 + $1.totalMinutesSaved }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Répartition")
                .font(AppFonts.headline())
                .padding(.horizontal, 4)
            
            HStack(spacing: 20) {
                // Graphique circulaire
                ZStack {
                    ForEach(Array(statistics.enumerated()), id: \.element.id) { index, stat in
                        PieSlice(
                            startAngle: startAngle(for: index),
                            endAngle: endAngle(for: index),
                            color: stat.color
                        )
                    }
                    
                    Circle()
                        .fill(Color(.systemBackground))
                        .frame(width: 60, height: 60)
                    
                    Image(systemName: "timer")
                        .font(.system(size: 24))
                        .foregroundColor(.secondary)
                }
                .frame(width: 120, height: 120)
                
                // Légende
                VStack(alignment: .leading, spacing: 8) {
                    ForEach(statistics.prefix(5)) { stat in
                        HStack(spacing: 8) {
                            Circle()
                                .fill(stat.color)
                                .frame(width: 10, height: 10)
                            
                            Text(stat.filterType.displayName)
                                .font(AppFonts.caption())
                                .foregroundColor(.primary)
                                .lineLimit(1)
                            
                            Spacer()
                            
                            if totalMinutes > 0 {
                                Text("\(Int(Double(stat.totalMinutesSaved) / Double(totalMinutes) * 100))%")
                                    .font(AppFonts.caption())
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                }
            }
            .padding(.vertical, 8)
        }
        .padding(.vertical, 20)
        .padding(.horizontal, 16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemGray6).opacity(0.5))
        )
        .opacity(animateContent ? 1 : 0)
        .offset(y: animateContent ? 0 : 30)
        .animation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.2), value: animateContent)
    }
    
    private func startAngle(for index: Int) -> Angle {
        guard totalMinutes > 0 else { return .degrees(0) }
        let precedingMinutes = statistics.prefix(index).reduce(0) { $0 + $1.totalMinutesSaved }
        return .degrees(Double(precedingMinutes) / Double(totalMinutes) * 360 - 90)
    }
    
    private func endAngle(for index: Int) -> Angle {
        guard totalMinutes > 0 else { return .degrees(0) }
        let includingMinutes = statistics.prefix(index + 1).reduce(0) { $0 + $1.totalMinutesSaved }
        return .degrees(Double(includingMinutes) / Double(totalMinutes) * 360 - 90)
    }
}

struct PieSlice: View {
    let startAngle: Angle
    let endAngle: Angle
    let color: Color
    
    var body: some View {
        GeometryReader { geometry in
            Path { path in
                let center = CGPoint(x: geometry.size.width / 2, y: geometry.size.height / 2)
                let radius = min(geometry.size.width, geometry.size.height) / 2
                
                path.move(to: center)
                path.addArc(
                    center: center,
                    radius: radius,
                    startAngle: startAngle,
                    endAngle: endAngle,
                    clockwise: false
                )
                path.closeSubpath()
            }
            .fill(color)
        }
    }
}

// MARK: - Gains estimés

struct EstimatedGainsCard: View {
    let weeklyMinutes: Int
    let monthlyMinutes: Int
    @Binding var animateContent: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Gains potentiels")
                    .font(AppFonts.headline())
                
                Spacer()
                
                Image(systemName: "sparkles")
                    .foregroundColor(.yellow)
            }
            
            HStack(spacing: 16) {
                GainBadge(
                    icon: "calendar.badge.clock",
                    label: "Cette semaine",
                    value: formatMinutes(weeklyMinutes),
                    color: .blue
                )
                
                GainBadge(
                    icon: "calendar",
                    label: "Ce mois",
                    value: formatMinutes(monthlyMinutes),
                    color: .purple
                )
            }
            
            Text("Estimation basée sur vos filtres actifs")
                .font(AppFonts.caption2())
                .foregroundColor(.secondary)
        }
        .padding(.vertical, 20)
        .padding(.horizontal, 16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemGray6).opacity(0.5))
        )
        .opacity(animateContent ? 1 : 0)
        .offset(y: animateContent ? 0 : 30)
        .animation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.3), value: animateContent)
    }
    
    private func formatMinutes(_ minutes: Int) -> String {
        let hours = minutes / 60
        let mins = minutes % 60
        if hours > 0 {
            return "\(hours)h \(mins)m"
        }
        return "\(mins)m"
    }
}

struct GainBadge: View {
    let icon: String
    let label: String
    let value: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 24))
                .foregroundColor(color)
            
            Text(value)
                .font(AppFonts.title3())
                .foregroundColor(.primary)
            
            Text(label)
                .font(AppFonts.caption2())
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .background(color.opacity(0.1))
        .cornerRadius(12)
    }
}

// MARK: - Vue vide

struct EmptyStatisticsView: View {
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "chart.bar.xaxis")
                .font(.system(size: 50))
                .foregroundColor(.secondary)
            
            Text("Aucun filtre actif")
                .font(AppFonts.headline())
                .foregroundColor(.primary)
            
            Text("Activez des filtres dans les paramètres pour commencer à économiser du temps")
                .font(AppFonts.subheadline())
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(32)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemGray6).opacity(0.5))
        )
    }
}

#Preview {
    StatisticsView()
}
