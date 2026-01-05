//
//  UsageTracker.swift
//  LessIsMore
//
//  Created by Angel Geoffroy on 05/01/2026.
//

import Foundation
import Combine
import UIKit

class UsageTracker: ObservableObject {
    static let shared = UsageTracker()

    @Published var todayUsageSeconds: Int = 0

    private var timer: Timer?
    private var isTracking = false
    private let userDefaults = UserDefaults.standard

    private let usageSecondsKey = "usage_today_seconds"
    private let lastDateKey = "usage_last_date"

    private init() {
        loadTodayUsage()
        setupNotifications()
        startTracking()
    }

    deinit {
        stopTracking()
        NotificationCenter.default.removeObserver(self)
    }

    // MARK: - Public Methods

    var formattedTime: String {
        let hours = todayUsageSeconds / 3600
        let minutes = (todayUsageSeconds % 3600) / 60

        if hours > 0 {
            return "\(hours)h \(minutes)m"
        } else if minutes > 0 {
            return "\(minutes)m"
        } else {
            return "0m"
        }
    }

    var formattedTimeShort: String {
        let minutes = todayUsageSeconds / 60
        if minutes >= 60 {
            let hours = minutes / 60
            let remainingMinutes = minutes % 60
            return "\(hours)h\(remainingMinutes > 0 ? " \(remainingMinutes)m" : "")"
        }
        return "\(minutes)m"
    }

    // MARK: - Private Methods

    private func loadTodayUsage() {
        let savedDate = userDefaults.string(forKey: lastDateKey) ?? ""
        let today = currentDateString()

        if savedDate == today {
            todayUsageSeconds = userDefaults.integer(forKey: usageSecondsKey)
        } else {
            // Nouveau jour, reset du compteur
            todayUsageSeconds = 0
            userDefaults.set(0, forKey: usageSecondsKey)
            userDefaults.set(today, forKey: lastDateKey)
        }
    }

    private func saveUsage() {
        userDefaults.set(todayUsageSeconds, forKey: usageSecondsKey)
        userDefaults.set(currentDateString(), forKey: lastDateKey)
    }

    private func currentDateString() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: Date())
    }

    private func setupNotifications() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(appDidBecomeActive),
            name: UIApplication.didBecomeActiveNotification,
            object: nil
        )

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(appWillResignActive),
            name: UIApplication.willResignActiveNotification,
            object: nil
        )

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(appWillTerminate),
            name: UIApplication.willTerminateNotification,
            object: nil
        )
    }

    @objc private func appDidBecomeActive() {
        loadTodayUsage() // Recharger au cas où le jour a changé
        startTracking()
    }

    @objc private func appWillResignActive() {
        stopTracking()
        saveUsage()
    }

    @objc private func appWillTerminate() {
        stopTracking()
        saveUsage()
    }

    private func startTracking() {
        guard !isTracking else { return }
        isTracking = true

        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            DispatchQueue.main.async {
                self.todayUsageSeconds += 1

                // Sauvegarder toutes les 30 secondes
                if self.todayUsageSeconds % 30 == 0 {
                    self.saveUsage()
                }
            }
        }
    }

    private func stopTracking() {
        timer?.invalidate()
        timer = nil
        isTracking = false
    }
}
