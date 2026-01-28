//
//  ProgressDataManager.swift
//  Group_11_Revisio
//
//  Created by Ashika Yadav on 14/01/26.



import Foundation
import UIKit

class ProgressDataManager {
    static let shared = ProgressDataManager()
    
    var history: [LogHistoryItem] = []
    
    // MARK: - Persistent Properties
    var totalXP: Int {
        get { UserDefaults.standard.integer(forKey: "user_total_xp") }
        set { UserDefaults.standard.set(newValue, forKey: "user_total_xp") }
    }
    
    var currentStreak: Int {
        get { UserDefaults.standard.integer(forKey: "user_current_streak") }
        set { UserDefaults.standard.set(newValue, forKey: "user_current_streak") }
    }
    
    private var lastActiveDate: Date? {
        get { UserDefaults.standard.object(forKey: "user_last_active_date") as? Date }
        set { UserDefaults.standard.set(newValue, forKey: "user_last_active_date") }
    }
    
    // MARK: - Calculations
    var currentLevel: Int {
        Int(sqrt(Double(totalXP)) * 0.1) + 1
    }
    
    var xpToNextLevel: Int {
        let nextLevel = currentLevel + 1
        let requiredXP = Int(pow(Double(nextLevel) / 0.1, 2))
        return max(0, requiredXP - totalXP)
    }

    private init() {
        loadInitialData()
        refreshStreakStatus()
    }
    
    // MARK: - Data Loading
    func loadInitialData() {
        guard let url = Bundle.main.url(forResource: "ProgressLogData", withExtension: "json"),
              let data = try? Data(contentsOf: url) else { return }

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601

        if let decodedWrapper = try? decoder.decode(LogDataWrapper.self, from: data) {
            self.history = decodedWrapper.logs
        }
    }
    
    // MARK: - Actions
    func addXP(amount: Int, source: String) {
        totalXP += amount
        // When user earns XP, we ensure their streak is updated for today
        updateStreak()
        NotificationCenter.default.post(name: .xpDidUpdate, object: nil)
        print("🌟 Earned \(amount) XP from \(source). Total: \(totalXP)")
    }
    
    /// Checks if a streak was broken upon app launch
    private func refreshStreakStatus() {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        guard let lastDate = lastActiveDate else { return }
        let lastActiveStart = calendar.startOfDay(for: lastDate)
        
        let components = calendar.dateComponents([.day], from: lastActiveStart, to: today)
        
        // If more than 1 day has passed since last activity, streak is broken
        if let daysPassed = components.day, daysPassed > 1 {
            currentStreak = 0
            print("💔 Streak broken. Days since last activity: \(daysPassed)")
        }
    }
    
    /// Updates or increments the streak when activity occurs
    private func updateStreak() {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let lastDate = lastActiveDate != nil ? calendar.startOfDay(for: lastActiveDate!) : nil
        
        if lastDate == today {
            return // Already updated today
        }
        
        if let yesterday = calendar.date(byAdding: .day, value: -1, to: today), lastDate == yesterday {
            currentStreak += 1 // Consecutive day
        } else {
            currentStreak = 1 // New streak or restarted after break
        }
        
        lastActiveDate = Date()
    }
}

extension Notification.Name {
    static let xpDidUpdate = Notification.Name("xpDidUpdate")
}
