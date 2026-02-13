import Foundation
import Supabase
import Combine

class RevisioManager: ObservableObject {
    static let shared = RevisioManager()
    
    // Internal Managers
    private let localStore = DataManager.shared
    private let progressStore = ProgressDataManager.shared
    
    // ✅ CHANGE: Use your existing SupabaseManager client instead of SupabaseConfig
    private let supabase = SupabaseManager.shared.client
    
    // Properties for UI binding
    @Published var currentUserProfile: Profile?
    private(set) var todayXP: Int = 0
    
    private init() {
        checkDailyReset()
    }

    // MARK: - THE CONQUEROR FUNCTION: XP & STREAK
    func earnXP(amount: Int, reason: String) async {
        // 1. Update Local XP Logic
        progressStore.addXP(amount: amount, source: reason)
        self.todayXP += amount
        
        // 2. Evaluate Streak: If daily threshold (20 XP) is met, update streak
        if self.todayXP >= GameConfig.dailyXPThreshold {
            updateStreakStatus()
        }
        
        // 3. Post notification for Storyboard ViewControllers to refresh UI
        // ✅ This uses the extension we define below
        NotificationCenter.default.post(name: .xpDidUpdate, object: nil)
        
        // 4. Cloud Sync: Push updates to Supabase
        await syncProgressToCloud(amount: amount, reason: reason)
    }

    // MARK: - CLOUD SYNC LOGIC
    private func syncProgressToCloud(amount: Int, reason: String) async {
        guard let userID = supabase.auth.currentUser?.id else { return }
        
        // Create structs to handle mixed types safely
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
            // Update Profile using the struct instead of a dictionary
            try await supabase.from("profiles")
                .update(ProfileUpdate(total_xp: progressStore.totalXP,
                                      current_streak: progressStore.currentStreak))
                .eq("id", value: userID)
                .execute()
            
            // Insert Log using the struct
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
        let lastUpdate = UserDefaults.standard.object(forKey: "last_streak_save_date") as? Date ?? .distantPast
        
        if !calendar.isDate(lastUpdate, inSameDayAs: today) {
            progressStore.currentStreak += 1
            UserDefaults.standard.set(today, forKey: "last_streak_save_date")
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
            // ✅ Ensure the topic has the user_id for Supabase
            try await supabase.from("topics").upsert(topic).execute()
        } catch {
            print("❌ Cloud Backup Error: \(error)")
        }
    }
}

