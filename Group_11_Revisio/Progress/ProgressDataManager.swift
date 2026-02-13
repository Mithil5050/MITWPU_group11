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
    
    /// The core XP value. Every time this is set, it triggers local storage, cloud sync, and level-up checks.
    var totalXP: Int {
        get { UserDefaults.standard.integer(forKey: "user_total_xp") }
        set {
            // 1. Capture the level BEFORE we save the new XP to check for a level-up later
            let oldLevel = currentLevel
            
            // 2. Save the new value to the phone's local storage (UserDefaults)
            UserDefaults.standard.set(newValue, forKey: "user_total_xp")
            
            // 3. Sync with Supabase Cloud automatically
            Task {
                // This assumes your SupabaseManager has a syncXP function
                await SupabaseManager.shared.syncXP(totalXP: newValue)
            }
            
            // 4. Check for a Level Up!
            // If the formula results in a higher number than before, tell the UI to celebrate.
            if currentLevel > oldLevel {
                print("🎉 LEVEL UP! User reached level \(currentLevel)")
                NotificationCenter.default.post(name: NSNotification.Name("UserLeveledUp"), object: nil)
            }
        }
    }
    
    var currentStreak: Int {
        get { UserDefaults.standard.integer(forKey: "user_current_streak") }
        set { UserDefaults.standard.set(newValue, forKey: "user_current_streak") }
    }
    
    private var lastActiveDate: Date? {
        get { UserDefaults.standard.object(forKey: "user_last_active_date") as? Date }
        set { UserDefaults.standard.set(newValue, forKey: "user_last_active_date") }
    }
    
    // MARK: - Calculations (The Conqueror Formulas)
    
    /// Calculates the user's level based on XP: (0.1 * sqrt(XP)) + 1
    var currentLevel: Int {
        return Int(sqrt(Double(totalXP)) * 0.1) + 1
    }
    
    /// Calculates how much XP is needed to reach the start of the next level
    var xpToNextLevel: Int {
        let nextLevel = currentLevel + 1
        let requiredXP = Int(pow(Double(nextLevel) / 0.1, 2))
        return max(0, requiredXP - totalXP)
    }

    private init() { }

    /// Call this on app launch to load data and check if the streak was broken
    func start() {
        loadInitialData()
        refreshStreakStatus()
    }
    
    // MARK: - Actions
    
    /// Use this function to grant XP from Wordle, Quizzes, or Daily Login
    func addXP(amount: Int, source: String) {
        // Updating totalXP here triggers the 'set' logic at the top of the file
        totalXP += amount
        
        // Ensure the streak is recorded for today's activity
        updateStreak()
        
        // Post a notification so all screens (Profile, Awards) refresh their bars
        NotificationCenter.default.post(name: .xpDidUpdate, object: nil)
        print("🌟 Earned \(amount) XP from \(source). Total: \(totalXP)")
    }
    
    // MARK: - Streak Logic
    
    /// Checks if a streak was broken (more than 24 hours of inactivity)
    private func refreshStreakStatus() {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        guard let lastDate = lastActiveDate else { return }
        let lastActiveStart = calendar.startOfDay(for: lastDate)
        
        let components = calendar.dateComponents([.day], from: lastActiveStart, to: today)
        
        if let daysPassed = components.day, daysPassed > 1 {
            currentStreak = 0 // Reset streak if user missed a day
            print("💔 Streak broken.")
        }
    }
    
    /// Increments the streak when the user performs an action
    private func updateStreak() {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let lastDate = lastActiveDate != nil ? calendar.startOfDay(for: lastActiveDate!) : nil
        
        if lastDate == today {
            return // Already updated today, do nothing
        }
        
        if let yesterday = calendar.date(byAdding: .day, value: -1, to: today), lastDate == yesterday {
            currentStreak += 1 // Logged in two days in a row
        } else {
            currentStreak = 1 // New streak or restarted after a break
        }
        
        lastActiveDate = Date()
    }

    // MARK: - Data Loading
    
    /// Loads the dummy JSON data for the Progress Graph
    func loadInitialData() {
        guard let url = Bundle.main.url(forResource: "ProgressLogData", withExtension: "json"),
              let data = try? Data(contentsOf: url) else { return }

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601

        if let decodedWrapper = try? decoder.decode(LogDataWrapper.self, from: data) {
            self.history = decodedWrapper.logs
        }
    }
}

// MARK: - Notification Extension
extension Notification.Name {
    static let xpDidUpdate = Notification.Name("xpDidUpdate")
}
