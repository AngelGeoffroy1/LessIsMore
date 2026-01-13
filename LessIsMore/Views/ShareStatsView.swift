//
//  ShareStatsView.swift
//  LessIsMore
//
//  Created by Angel Geoffroy on 06/01/2026.
//

import SwiftUI

// MARK: - Preview Sheet (shown before sharing)

struct ShareStatsPreviewSheet: View {
    // Weekly mode properties
    let weeklyData: [UsageTracker.WeeklyUsageData]?
    let todayUsage: String?
    
    // Monthly mode properties
    let monthlyData: [UsageTracker.MonthlyWeekData]?
    let weekUsage: String?
    let monthName: String?
    
    // Common properties
    let percentageChange: Double
    let isMonthlyMode: Bool
    
    @Environment(\.dismiss) var dismiss
    @Environment(\.colorScheme) var colorScheme
    @State private var shareImage: UIImage?
    @State private var showShareSheet = false
    @State private var showSaveConfirmation = false
    
    // Initializer for weekly mode
    init(weeklyData: [UsageTracker.WeeklyUsageData], todayUsage: String, percentageChange: Double, isMonthlyMode: Bool = false) {
        self.weeklyData = weeklyData
        self.todayUsage = todayUsage
        self.percentageChange = percentageChange
        self.isMonthlyMode = isMonthlyMode
        self.monthlyData = nil
        self.weekUsage = nil
        self.monthName = nil
    }
    
    // Initializer for monthly mode
    init(monthlyData: [UsageTracker.MonthlyWeekData], weekUsage: String, percentageChange: Double, monthName: String, isMonthlyMode: Bool = true) {
        self.monthlyData = monthlyData
        self.weekUsage = weekUsage
        self.percentageChange = percentageChange
        self.monthName = monthName
        self.isMonthlyMode = isMonthlyMode
        self.weeklyData = nil
        self.todayUsage = nil
    }
    
    var body: some View {
        ZStack {
            // Background - Same as ControlPanel
            VisualEffectView(effect: UIBlurEffect(style: colorScheme == .dark ? .systemUltraThinMaterialDark : .systemUltraThinMaterialLight))
                .opacity(0.4)
                .ignoresSafeArea()
            
            VStack(spacing: 24) {
                // Header
                HStack {
                    Button(action: { dismiss() }) {
                        Text("common.cancel".localized)
                            .font(AppFonts.body(16))
                            .foregroundColor(.primary.opacity(0.7))
                    }
                    
                    Spacer()
                    
                    Text("shareStats.preview".localized)
                        .font(AppFonts.headline(17))
                        .foregroundColor(.primary)
                    
                    Spacer()
                    
                    Button(action: shareStats) {
                        Text("common.share".localized)
                            .font(AppFonts.headline(16))
                            .foregroundColor(.blue)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 20)
                
                Spacer()
                
                // Preview Card
                if isMonthlyMode, let monthlyData = monthlyData, let weekUsage = weekUsage, let monthName = monthName {
                    ShareStatsCardMonthly(
                        monthlyData: monthlyData,
                        weekUsage: weekUsage,
                        percentageChange: percentageChange,
                        monthName: monthName
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 24))
                    .shadow(color: .black.opacity(0.3), radius: 20, x: 0, y: 10)
                    .padding(.horizontal, 30)
                } else if let weeklyData = weeklyData, let todayUsage = todayUsage {
                    ShareStatsCard(
                        weeklyData: weeklyData,
                        todayUsage: todayUsage,
                        percentageChange: percentageChange
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 24))
                    .shadow(color: .black.opacity(0.3), radius: 20, x: 0, y: 10)
                    .padding(.horizontal, 30)
                }
                
                Spacer()
                
                // Action Buttons Row
                HStack(spacing: 12) {
                    // Share to Story Button
                    Button(action: shareStats) {
                        HStack(spacing: 8) {
                            Image(systemName: "square.and.arrow.up")
                                .font(.system(size: 16, weight: .semibold))
                            
                            Text("shareStats.shareToStory".localized)
                                .font(AppFonts.headline(16))
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(
                            LinearGradient(
                                colors: [
                                    Color(red: 0.98, green: 0.05, blue: 0.44),
                                    Color(red: 0.73, green: 0.20, blue: 0.82)
                                ],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                    }
                    
                    // Save to Photos Button
                    Button(action: saveToPhotos) {
                        Image(systemName: showSaveConfirmation ? "checkmark" : "arrow.down.to.line")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(showSaveConfirmation ? .green : .white)
                            .frame(width: 56, height: 56)
                            .background(
                                showSaveConfirmation 
                                    ? Color.green.opacity(0.2)
                                    : Color.white.opacity(0.15)
                            )
                            .clipShape(RoundedRectangle(cornerRadius: 14))
                            .overlay(
                                RoundedRectangle(cornerRadius: 14)
                                    .stroke(showSaveConfirmation ? Color.green.opacity(0.5) : Color.white.opacity(0.2), lineWidth: 1)
                            )
                    }
                    .animation(.easeInOut(duration: 0.2), value: showSaveConfirmation)
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 30)
            }
        }
        .sheet(isPresented: $showShareSheet) {
            if let image = shareImage {
                ShareSheet(items: [image])
            }
        }
    }
    
    @MainActor
    private func shareStats() {
        let haptic = UIImpactFeedbackGenerator(style: .medium)
        haptic.impactOccurred()
        
        // Create the share card at full resolution
        if isMonthlyMode, let monthlyData = monthlyData, let weekUsage = weekUsage, let monthName = monthName {
            let shareCard = ShareStatsCardMonthly(
                monthlyData: monthlyData,
                weekUsage: weekUsage,
                percentageChange: percentageChange,
                monthName: monthName
            )
            shareImage = shareCard.snapshot()
        } else if let weeklyData = weeklyData, let todayUsage = todayUsage {
            let shareCard = ShareStatsCard(
                weeklyData: weeklyData,
                todayUsage: todayUsage,
                percentageChange: percentageChange
            )
            shareImage = shareCard.snapshot()
        }
        
        showShareSheet = true
    }
    
    @MainActor
    private func saveToPhotos() {
        let haptic = UIImpactFeedbackGenerator(style: .medium)
        haptic.impactOccurred()
        
        var image: UIImage?
        
        // Create the share card at full resolution
        if isMonthlyMode, let monthlyData = monthlyData, let weekUsage = weekUsage, let monthName = monthName {
            let shareCard = ShareStatsCardMonthly(
                monthlyData: monthlyData,
                weekUsage: weekUsage,
                percentageChange: percentageChange,
                monthName: monthName
            )
            image = shareCard.snapshot()
        } else if let weeklyData = weeklyData, let todayUsage = todayUsage {
            let shareCard = ShareStatsCard(
                weeklyData: weeklyData,
                todayUsage: todayUsage,
                percentageChange: percentageChange
            )
            image = shareCard.snapshot()
        }
        
        if let image = image {
            // Save to photo library
            UIImageWriteToSavedPhotosAlbum(image, nil, nil, nil)
        }
        
        // Show confirmation
        withAnimation {
            showSaveConfirmation = true
        }
        
        // Reset after 2 seconds
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            withAnimation {
                showSaveConfirmation = false
            }
        }
    }
}

// MARK: - Share Stats Card (the actual shareable image)

struct ShareStatsCard: View {
    let weeklyData: [UsageTracker.WeeklyUsageData]
    let todayUsage: String
    let percentageChange: Double
    
    private var totalWeekSeconds: Int {
        weeklyData.reduce(0) { $0 + $1.totalSeconds }
    }
    
    private var formattedWeekTotal: String {
        let hours = totalWeekSeconds / 3600
        let minutes = (totalWeekSeconds % 3600) / 60
        if hours > 0 {
            return "\(hours)h \(minutes)m"
        }
        return "\(minutes)m"
    }
    
    private var bestDay: String? {
        guard let minDay = weeklyData.filter({ $0.totalSeconds > 0 }).min(by: { $0.totalSeconds < $1.totalSeconds }) else {
            return nil
        }
        return minDay.day
    }
    
    // Categories that have actual usage data
    private var activeCategories: [UsageTracker.UsageCategory] {
        var usedCategories = Set<String>()
        for day in weeklyData {
            for (categoryKey, seconds) in day.categorySeconds {
                if seconds > 0 {
                    usedCategories.insert(categoryKey)
                }
            }
        }
        return UsageTracker.UsageCategory.allCases.filter { usedCategories.contains($0.rawValue) }
    }
    
    // Impact comparison - what could have been done with this time
    private var impactComparison: (icon: String, text: String)? {
        let totalMinutes = totalWeekSeconds / 60
        guard totalMinutes > 0 else { return nil }
        
        // Define comparisons: (minMinutes, icon, singular, plural, divisor)
        let comparisons: [(min: Int, icon: String, singular: String, plural: String, divisor: Int)] = [
            (30, "📚", "book chapter read", "book chapters read", 30),                    // 30 min per chapter
            (120, "🎬", "movie watched", "movies watched", 120),                          // 2h per movie
            (45, "🏃", "workout session", "workout sessions", 45),                        // 45 min per workout
            (20, "🧘", "meditation", "meditations", 20),                                   // 20 min per meditation
            (180, "📖", "book read entirely", "books read entirely", 180),                // 3h per book
            (45, "🎧", "podcast episode", "podcast episodes", 45),                        // 45 min per episode
            (60, "👨‍🍳", "new recipe cooked", "new recipes cooked", 60),                    // 1h per recipe
            (30, "🎸", "music lesson", "music lessons", 30),                              // 30 min per lesson
            (15, "🚶", "km walked", "km walked", 15),                                      // 15 min per km
            (60, "💪", "workout hour", "workout hours", 60),                              // 1h per session
        ]
        
        // Filter valid comparisons and pick one based on time
        let validComparisons = comparisons.filter { totalMinutes >= $0.min }
        guard !validComparisons.isEmpty else { return nil }
        
        // Pick a random comparison for variety (seeded by total to be consistent)
        let index = totalMinutes % validComparisons.count
        let comparison = validComparisons[index]
        
        let count = totalMinutes / comparison.divisor
        guard count > 0 else { return nil }
        
        let text = count == 1 ? comparison.singular : comparison.plural
        return (comparison.icon, "≈ \(count) \(text)")
    }
    
    // Mascot image based on weekly usage
    private var mascotImage: Image {
        let totalHours = totalWeekSeconds / 3600
        
        if totalHours < 3 {
            // Great usage - thumbs up
            return Image("mascott pouce")
        } else if totalHours < 7 {
            // Medium usage - wave
            return Image("mascott bonjour")
        } else {
            // High usage - tired
            return Image("mascotte tired")
        }
    }
    
    private let chartHeight: CGFloat = 100
    
    var body: some View {
        ZStack {
            // Glassmorphism background - like ControlPanel
            LinearGradient(
                colors: [
                    Color(red: 0.12, green: 0.12, blue: 0.15),
                    Color(red: 0.08, green: 0.08, blue: 0.10)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            
            // Glass overlay
            Color.white.opacity(0.05)
            
            // Ambient glow effects
            Circle()
                .fill(
                    RadialGradient(
                        colors: [Color.purple.opacity(0.15), Color.clear],
                        center: .center,
                        startRadius: 0,
                        endRadius: 120
                    )
                )
                .frame(width: 240, height: 240)
                .offset(x: -60, y: -120)
                .blur(radius: 30)
            
            Circle()
                .fill(
                    RadialGradient(
                        colors: [Color.pink.opacity(0.1), Color.clear],
                        center: .center,
                        startRadius: 0,
                        endRadius: 140
                    )
                )
                .frame(width: 280, height: 280)
                .offset(x: 80, y: 160)
                .blur(radius: 40)
            
            // Content with fixed positioning
            VStack(spacing: 0) {
                // Title Section
                VStack(spacing: 4) {
                    Text("shareStats.myInstagram".localized)
                        .font(AppFonts.caption(10))
                        .foregroundColor(.white.opacity(0.5))
                        .tracking(2)
                    
                    Text("shareStats.thisWeek".localized)
                        .font(AppFonts.title3(18))
                        .foregroundColor(.white.opacity(0.9))
                }
                .padding(.top, 24)
                .padding(.bottom, 16)
                
                // Main Stats with Mascot
                ZStack {
                    // Centered time
                    VStack(spacing: 6) {
                        Text(formattedWeekTotal)
                            .font(AppFonts.title(36))
                            .foregroundColor(.white)
                        
                        // Trend pill
                        if percentageChange != 0 {
                            HStack(spacing: 4) {
                                Image(systemName: percentageChange < 0 ? "arrow.down" : "arrow.up")
                                    .font(.system(size: 9, weight: .bold))
                                
                                Text(String(format: "shareStats.vsYesterday".localized, abs(Int(percentageChange))))
                                    .font(AppFonts.caption(11))
                            }
                            .foregroundColor(percentageChange < 0 ? .green : .red)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 5)
                            .background(
                                Capsule()
                                    .fill((percentageChange < 0 ? Color.green : Color.red).opacity(0.15))
                            )
                        }
                    }
                    
                    // Mascot on the left
                    HStack {
                        mascotImage
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 60, height: 60)
                            .padding(.leading, 20)
                        Spacer()
                    }
                }
                .padding(.bottom, 16)
                
                // Chart - 100% Stacked Bar (like ControlPanelView)
                VStack(spacing: 8) {
                    chartView
                    
                    // Day labels
                    HStack(spacing: 0) {
                        ForEach(weeklyData) { item in
                            Text(item.day)
                                .font(AppFonts.caption2(9))
                                .foregroundColor(.white.opacity(0.4))
                                .frame(maxWidth: .infinity)
                        }
                    }
                }
                .padding(.horizontal, 16)
                
                // Legend - Only show active categories
                HStack(spacing: 10) {
                    ForEach(activeCategories, id: \.self) { category in
                        HStack(spacing: 3) {
                            Circle()
                                .fill(category.color)
                                .frame(width: 5, height: 5)
                            Text(category.rawValue)
                                .font(AppFonts.caption2(8))
                                .foregroundColor(.white.opacity(0.5))
                        }
                    }
                }
                .padding(.top, 10)
                
                Spacer(minLength: 8)
                
                // Impact Comparison - Option C (without card)
                if let impact = impactComparison {
                    VStack(spacing: 8) {
                        // Header
                        Text("shareStats.withThisTime".localized)
                            .font(AppFonts.caption2(9))
                            .foregroundColor(.white.opacity(0.4))
                            .tracking(1.5)
                        
                        // Main content
                        VStack(spacing: 4) {
                            Text(impact.icon)
                                .font(.system(size: 28))
                            
                            Text(impact.text)
                                .font(AppFonts.subheadline(12))
                                .foregroundColor(.white.opacity(0.9))
                                .multilineTextAlignment(.center)
                        }
                        
                        // Call to action
                        Text("shareStats.takeBackControl".localized)
                            .font(AppFonts.caption2(9))
                            .foregroundColor(.white.opacity(0.4))
                            .italic()
                    }
                    .padding(.vertical, 10)
                }
                
                Spacer(minLength: 8)
                
                // Branding - LessIsMore badge with Instagram gradient
                Text("LessIsMore")
                    .font(AppFonts.headline(12))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [
                                Color(red: 1.0, green: 0.55, blue: 0.0),
                                Color(red: 0.98, green: 0.22, blue: 0.42),
                                Color(red: 0.83, green: 0.18, blue: 0.62),
                                Color(red: 0.55, green: 0.23, blue: 0.85)
                            ],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .padding(.horizontal, 14)
                    .padding(.vertical, 6)
                    .background(
                        Capsule()
                            .fill(Color.white.opacity(0.08))
                    )
                    .padding(.bottom, 40)
            }
        }
        .frame(width: 270, height: 480) // 9:16 ratio to match Instagram story
        .clipped()
    }
    
    // MARK: - Chart View (100% Stacked like ControlPanel)
    
    private var chartView: some View {
        HStack(alignment: .bottom, spacing: 6) {
            ForEach(weeklyData) { item in
                ZStack(alignment: .bottom) {
                    // Background bar
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.white.opacity(0.05))
                        .frame(height: chartHeight)
                    
                    if item.totalSeconds > 0 {
                        // 100% Stacked category bars (fills full height proportionally)
                        VStack(spacing: 0) {
                            ForEach(Array(UsageTracker.UsageCategory.allCases.reversed()), id: \.self) { category in
                                let seconds = item.categorySeconds[category.rawValue] ?? 0
                                if seconds > 0 {
                                    Rectangle()
                                        .fill(category.color)
                                        .frame(height: CGFloat(seconds) / CGFloat(item.totalSeconds) * chartHeight)
                                }
                            }
                        }
                        .clipShape(RoundedRectangle(cornerRadius: 4))
                    } else {
                        // Placeholder for days with no data
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color.white.opacity(0.08))
                            .frame(height: 8)
                    }
                }
                .frame(maxWidth: .infinity)
            }
        }
        .frame(height: chartHeight)
    }
}

// MARK: - Share Stats Card Monthly (for weekly view of month)

struct ShareStatsCardMonthly: View {
    let monthlyData: [UsageTracker.MonthlyWeekData]
    let weekUsage: String
    let percentageChange: Double
    let monthName: String
    
    private var totalMonthSeconds: Int {
        monthlyData.reduce(0) { $0 + $1.totalSeconds }
    }
    
    private var formattedMonthTotal: String {
        let hours = totalMonthSeconds / 3600
        let minutes = (totalMonthSeconds % 3600) / 60
        if hours > 0 {
            return "\(hours)h \(minutes)m"
        }
        return "\(minutes)m"
    }
    
    private var currentWeekOfMonth: Int {
        let calendar = Calendar.current
        return calendar.component(.weekOfMonth, from: Date())
    }
    
    private var bestWeek: String? {
        guard let minWeek = monthlyData.filter({ $0.totalSeconds > 0 }).min(by: { $0.totalSeconds < $1.totalSeconds }) else {
            return nil
        }
        return minWeek.weekLabel
    }
    
    // Categories that have actual usage data
    private var activeCategories: [UsageTracker.UsageCategory] {
        var usedCategories = Set<String>()
        for week in monthlyData {
            for (categoryKey, seconds) in week.categorySeconds {
                if seconds > 0 {
                    usedCategories.insert(categoryKey)
                }
            }
        }
        return UsageTracker.UsageCategory.allCases.filter { usedCategories.contains($0.rawValue) }
    }
    
    // Impact comparison - what could have been done with this time
    private var impactComparison: (icon: String, text: String)? {
        let totalMinutes = totalMonthSeconds / 60
        guard totalMinutes > 0 else { return nil }
        
        // Define comparisons: (minMinutes, icon, singular, plural, divisor)
        let comparisons: [(min: Int, icon: String, singular: String, plural: String, divisor: Int)] = [
            (30, "📚", "book chapter read", "book chapters read", 30),
            (120, "🎬", "movie watched", "movies watched", 120),
            (45, "🏃", "workout session", "workout sessions", 45),
            (20, "🧘", "meditation", "meditations", 20),
            (180, "📖", "book read entirely", "books read entirely", 180),
            (45, "🎧", "podcast episode", "podcast episodes", 45),
            (60, "👨‍🍳", "new recipe cooked", "new recipes cooked", 60),
            (30, "🎸", "music lesson", "music lessons", 30),
            (15, "🚶", "km walked", "km walked", 15),
            (60, "💪", "workout hour", "workout hours", 60),
        ]
        
        // Filter valid comparisons and pick one based on time
        let validComparisons = comparisons.filter { totalMinutes >= $0.min }
        guard !validComparisons.isEmpty else { return nil }
        
        // Pick a random comparison for variety (seeded by total to be consistent)
        let index = totalMinutes % validComparisons.count
        let comparison = validComparisons[index]
        
        let count = totalMinutes / comparison.divisor
        guard count > 0 else { return nil }
        
        let text = count == 1 ? comparison.singular : comparison.plural
        return (comparison.icon, "≈ \(count) \(text)")
    }
    
    private let chartHeight: CGFloat = 100
    
    var body: some View {
        ZStack {
            // Glassmorphism background - like ControlPanel
            LinearGradient(
                colors: [
                    Color(red: 0.12, green: 0.12, blue: 0.15),
                    Color(red: 0.08, green: 0.08, blue: 0.10)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            
            // Glass overlay
            Color.white.opacity(0.05)
            
            // Ambient glow effects
            Circle()
                .fill(
                    RadialGradient(
                        colors: [Color.purple.opacity(0.15), Color.clear],
                        center: .center,
                        startRadius: 0,
                        endRadius: 120
                    )
                )
                .frame(width: 240, height: 240)
                .offset(x: -60, y: -120)
                .blur(radius: 30)
            
            Circle()
                .fill(
                    RadialGradient(
                        colors: [Color.pink.opacity(0.1), Color.clear],
                        center: .center,
                        startRadius: 0,
                        endRadius: 140
                    )
                )
                .frame(width: 280, height: 280)
                .offset(x: 80, y: 160)
                .blur(radius: 40)
            
            // Content with fixed positioning
            VStack(spacing: 0) {
                // Title Section
                VStack(spacing: 4) {
                    Text("shareStats.myInstagram".localized)
                        .font(AppFonts.caption(10))
                        .foregroundColor(.white.opacity(0.5))
                        .tracking(2)
                    
                    Text(monthName.lowercased())
                        .font(AppFonts.title3(18))
                        .foregroundColor(.white.opacity(0.9))
                }
                .padding(.top, 24)
                .padding(.bottom, 16)
                
                // Main Stats
                VStack(spacing: 6) {
                    Text(formattedMonthTotal)
                        .font(AppFonts.title(36))
                        .foregroundColor(.white)
                    
                    // Trend pill
                    if percentageChange != 0 {
                        HStack(spacing: 4) {
                            Image(systemName: percentageChange < 0 ? "arrow.down" : "arrow.up")
                                .font(.system(size: 9, weight: .bold))
                            Text(String(format: "shareStats.vsLastWeek".localized, abs(Int(percentageChange))))
                                .font(AppFonts.caption(11))
                        }
                        .foregroundColor(percentageChange < 0 ? .green : .red)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(
                            Capsule()
                                .fill((percentageChange < 0 ? Color.green : Color.red).opacity(0.15))
                        )
                    }
                }
                .padding(.bottom, 16)
                
                // Chart - 100% Stacked Bar (for weeks)
                VStack(spacing: 8) {
                    chartView
                    
                    // Week labels
                    HStack(spacing: 0) {
                        ForEach(monthlyData) { item in
                            Text("Wk \(item.weekNumber)")
                                .font(AppFonts.caption2(9))
                                .foregroundColor(.white.opacity(0.4))
                                .frame(maxWidth: .infinity)
                        }
                    }
                }
                .padding(.horizontal, 16)
                
                // Legend - Only show active categories
                HStack(spacing: 10) {
                    ForEach(activeCategories, id: \.self) { category in
                        HStack(spacing: 3) {
                            Circle()
                                .fill(category.color)
                                .frame(width: 5, height: 5)
                            Text(category.rawValue)
                                .font(AppFonts.caption2(8))
                                .foregroundColor(.white.opacity(0.5))
                        }
                    }
                }
                .padding(.top, 10)
                
                Spacer(minLength: 8)
                
                // Impact Comparison
                if let impact = impactComparison {
                    VStack(spacing: 8) {
                        // Header
                        Text("shareStats.withThisTime".localized)
                            .font(AppFonts.caption2(9))
                            .foregroundColor(.white.opacity(0.4))
                            .tracking(1.5)
                        
                        // Main content
                        VStack(spacing: 4) {
                            Text(impact.icon)
                                .font(.system(size: 28))
                            
                            Text(impact.text)
                                .font(AppFonts.subheadline(12))
                                .foregroundColor(.white.opacity(0.9))
                                .multilineTextAlignment(.center)
                        }
                        
                        // Call to action
                        Text("shareStats.takeBackControl".localized)
                            .font(AppFonts.caption2(9))
                            .foregroundColor(.white.opacity(0.4))
                            .italic()
                    }
                    .padding(.vertical, 10)
                }
                
                Spacer(minLength: 8)
                
                // Branding - LessIsMore badge with Instagram gradient
                Text("LessIsMore")
                    .font(AppFonts.headline(12))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [
                                Color(red: 1.0, green: 0.55, blue: 0.0),
                                Color(red: 0.98, green: 0.22, blue: 0.42),
                                Color(red: 0.83, green: 0.18, blue: 0.62),
                                Color(red: 0.55, green: 0.23, blue: 0.85)
                            ],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .padding(.horizontal, 14)
                    .padding(.vertical, 6)
                    .background(
                        Capsule()
                            .fill(Color.white.opacity(0.08))
                    )
                    .padding(.bottom, 40)
            }
        }
        .frame(width: 270, height: 480) // 9:16 ratio to match Instagram story
        .clipped()
    }
    
    // MARK: - Chart View (100% Stacked for weeks)
    
    private var chartView: some View {
        HStack(alignment: .bottom, spacing: 6) {
            ForEach(monthlyData) { item in
                let isCurrentWeek = item.weekNumber == currentWeekOfMonth
                
                ZStack(alignment: .bottom) {
                    // Background bar
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.white.opacity(0.05))
                        .frame(height: chartHeight)
                    
                    if item.totalSeconds > 0 {
                        // 100% Stacked category bars (fills full height proportionally)
                        VStack(spacing: 0) {
                            ForEach(Array(UsageTracker.UsageCategory.allCases.reversed()), id: \.self) { category in
                                let seconds = item.categorySeconds[category.rawValue] ?? 0
                                if seconds > 0 {
                                    Rectangle()
                                        .fill(category.color.opacity(isCurrentWeek ? 1.0 : 0.6))
                                        .frame(height: CGFloat(seconds) / CGFloat(item.totalSeconds) * chartHeight)
                                }
                            }
                        }
                        .clipShape(RoundedRectangle(cornerRadius: 4))
                    } else {
                        // Placeholder for weeks with no data
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color.white.opacity(0.08))
                            .frame(height: 8)
                    }
                }
                .frame(maxWidth: .infinity)
            }
        }
        .frame(height: chartHeight)
    }
}

// MARK: - View Extension for Snapshot

extension View {
    @MainActor
    func snapshot() -> UIImage {
        let controller = UIHostingController(rootView: self.environment(\.colorScheme, .dark))
        let view = controller.view
        
        // Preview size matches ShareStatsCard frame (9:16 ratio)
        let previewSize = CGSize(width: 270, height: 480)
        // Target size for Instagram story
        let targetSize = CGSize(width: 1080, height: 1920)
        let scale = targetSize.width / previewSize.width
        
        view?.bounds = CGRect(origin: .zero, size: previewSize)
        view?.backgroundColor = .clear
        
        let renderer = UIGraphicsImageRenderer(size: targetSize)
        
        return renderer.image { context in
            context.cgContext.scaleBy(x: scale, y: scale)
            view?.drawHierarchy(in: CGRect(origin: .zero, size: previewSize), afterScreenUpdates: true)
        }
    }
}

// MARK: - Share Sheet (UIKit wrapper)

struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]
    
    func makeUIViewController(context: Context) -> UIActivityViewController {
        let controller = UIActivityViewController(activityItems: items, applicationActivities: nil)
        return controller
    }
    
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

// MARK: - Preview

#Preview("Preview Sheet") {
    ShareStatsPreviewSheet(
        weeklyData: [
            UsageTracker.WeeklyUsageData(day: "Mon", seconds: 3600),
            UsageTracker.WeeklyUsageData(day: "Tue", seconds: 5400),
            UsageTracker.WeeklyUsageData(day: "Wed", seconds: 2700),
            UsageTracker.WeeklyUsageData(day: "Thu", seconds: 4200),
            UsageTracker.WeeklyUsageData(day: "Fri", seconds: 6000),
            UsageTracker.WeeklyUsageData(day: "Sat", seconds: 7200),
            UsageTracker.WeeklyUsageData(day: "Sun", seconds: 4800)
        ],
        todayUsage: "1h 23m",
        percentageChange: -32
    )
    .preferredColorScheme(.dark)
}

#Preview("Share Card") {
    ShareStatsCard(
        weeklyData: [
            UsageTracker.WeeklyUsageData(day: "Mon", seconds: 3600),
            UsageTracker.WeeklyUsageData(day: "Tue", seconds: 5400),
            UsageTracker.WeeklyUsageData(day: "Wed", seconds: 2700),
            UsageTracker.WeeklyUsageData(day: "Thu", seconds: 4200),
            UsageTracker.WeeklyUsageData(day: "Fri", seconds: 6000),
            UsageTracker.WeeklyUsageData(day: "Sat", seconds: 7200),
            UsageTracker.WeeklyUsageData(day: "Sun", seconds: 4800)
        ],
        todayUsage: "1h 23m",
        percentageChange: -32
    )
    .preferredColorScheme(.dark)
}
