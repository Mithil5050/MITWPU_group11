import Foundation
import Supabase
import Combine
import UIKit

class RevisioManager: ObservableObject {
    static let shared = RevisioManager()
    
    // Internal Managers
    private let localStore = DataManager.shared
    private let progressStore = ProgressDataManager.shared
    
    // Use your existing SupabaseManager client
    private let supabase = SupabaseManager.shared.client
    
    // Properties for UI binding
    @Published var currentUserProfile: Profile?
    private(set) var todayXP: Int = 0
    
    private init() {
        checkDailyReset()
        validateStreakContinuity() // Check if streak was lost since last launch
    }

    // MARK: - THE CONQUEROR FUNCTION: XP & STREAK
    func earnXP(amount: Int, reason: String) async {
        
        // 1. & 2. Use the combined logic in ProgressDataManager
        // This single call handles: Carry-over math, Leveling up, and Level Badge checks.
        progressStore.addXP(amount: amount)
        
        // 3. Update Today's XP for Streak Requirement
        progressStore.todayXP += amount
        self.todayXP = progressStore.todayXP
        
        // 4. Update streak status (Checks the 100 XP threshold)
        updateStreakStatus()
        
        // 5. Refresh the UI
        DispatchQueue.main.async {
            NotificationCenter.default.post(name: .xpDidUpdate, object: nil)
            XPNotificationBanner.show(amount: amount, reason: reason)
            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        }
        
        // 6. Cloud Sync to Supabase
        await syncProgressToCloud(amount: amount, reason: reason)
    }

    // MARK: - CLOUD SYNC LOGIC
    private func syncProgressToCloud(amount: Int, reason: String) async {
        guard let userID = supabase.auth.currentUser?.id else { return }
        
        struct ProfileUpdate: Encodable {
            let total_xp: Int
            let current_streak: Int
        }
        
        struct XPLogEntry: Encodable {
            let user_id: UUID
            let amount: Int
            let reason: String
        }
        
        do {
            try await supabase.from("profiles")
                .update(ProfileUpdate(total_xp: progressStore.totalXP,
                                      current_streak: progressStore.currentStreak))
                .eq("id", value: userID)
                .execute()
            
            try await supabase.from("xp_log")
                .insert(XPLogEntry(user_id: userID,
                                   amount: amount,
                                   reason: reason))
                .execute()
                
        } catch {
            print("❌ Supabase Sync Failed: \(error.localizedDescription)")
        }
    }

    // MARK: - STREAK VALIDATION
    private func updateStreakStatus() {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let lastStreakUpdate = UserDefaults.standard.object(forKey: "last_streak_increment_date") as? Date ?? .distantPast
        
        // Rule: Streak increases only if Today's XP is >= 100
        if progressStore.todayXP >= 100 && !calendar.isDate(lastStreakUpdate, inSameDayAs: today) {
            progressStore.currentStreak += 1
            UserDefaults.standard.set(today, forKey: "last_streak_increment_date")
        }
    }

    private func validateStreakContinuity() {
        let calendar = Calendar.current
        let lastActivityDate = UserDefaults.standard.object(forKey: "last_xp_date") as? Date ?? .distantPast
        
        if !calendar.isDateInToday(lastActivityDate) {
            let yesterday = calendar.date(byAdding: .day, value: -1, to: Date())!
            
            // Rule: If user didn't hit 100 XP yesterday or skipped, reset to 0
            let yesterdayFinalXP = UserDefaults.standard.integer(forKey: "today_xp_accumulated")
            
            if !calendar.isDate(lastActivityDate, inSameDayAs: yesterday) || yesterdayFinalXP < 100 {
                progressStore.currentStreak = 0
            }
        }
    }

    private func checkDailyReset() {
        let lastOpen = UserDefaults.standard.object(forKey: "last_launch_date") as? Date ?? .now
        if !Calendar.current.isDateInToday(lastOpen) {
            self.todayXP = 0
            UserDefaults.standard.set(Date(), forKey: "last_launch_date")
        }
    }
    
    func backupTopicToCloud(_ topic: Topic) async {
        do {
            try await supabase.from("topics").upsert(topic).execute()
        } catch {
            print("❌ Cloud Backup Error: \(error)")
        }
    }
}
