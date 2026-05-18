import Foundation
import Supabase
import Combine
import UIKit

class RevisioManager: ObservableObject {
    static let shared = RevisioManager()

    private let localStore     = DataManager.shared
    private let progressStore  = ProgressDataManager.shared
    private let supabase       = SupabaseManager.shared.client

    @Published var currentUserProfile: Profile?
    private(set) var todayXP: Int = 0

    private init() {
        checkDailyReset()
        validateStreakContinuity()
    }

    //  XP & Streak

    func earnXP(amount: Int, reason: String) async {
        // addXP already calls recordXPEvent → syncXPEvent → xp_log insert internally.
        progressStore.addXP(amount: amount, reason: reason)

        progressStore.todayXP += amount
        self.todayXP = progressStore.todayXP

        updateStreakStatus()

        DispatchQueue.main.async {
            NotificationCenter.default.post(name: .xpDidUpdate, object: nil)
            XPNotificationBanner.show(amount: amount, reason: reason)
            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        }

        // Only sync profile totals — xp_log is handled by ProgressDataManager
        await syncProfileToCloud()
    }

    //  Cloud Sync
    private func syncProfileToCloud() async {
        guard let userID = supabase.auth.currentUser?.id else { return }

        struct ProfileUpdate: Encodable {
            let total_xp: Int
            let current_streak: Int
        }

        do {
            try await supabase.from("profiles")
                .update(ProfileUpdate(
                    total_xp: progressStore.totalXP,
                    current_streak: progressStore.currentStreak
                ))
                .eq("id", value: userID)
                .execute()
        } catch {
            print("❌ Supabase Profile Sync Failed: \(error.localizedDescription)")
        }
    }

    // Streak Validation

    private func updateStreakStatus() {
        let calendar = Calendar.current
        let today    = calendar.startOfDay(for: Date())
        let lastStreakUpdate = UserDefaults.standard.object(forKey: "last_streak_increment_date") as? Date ?? .distantPast

        if progressStore.todayXP >= 100 && !calendar.isDate(lastStreakUpdate, inSameDayAs: today) {
            progressStore.currentStreak += 1
            UserDefaults.standard.set(today, forKey: "last_streak_increment_date")
            // Persist this date so the calendar can show an orange dot
            var streakDates = UserDefaults.standard.stringArray(forKey: "streak_dot_dates") ?? []
            let key = ISO8601DateFormatter().string(from: today)
            if !streakDates.contains(key) {
                streakDates.append(key)
                UserDefaults.standard.set(streakDates, forKey: "streak_dot_dates")
            }
            // Push updated dot-dates to Supabase so they survive reinstalls
            Task { await SupabaseManager.shared.syncUserStats() }
        }
    }

    private func validateStreakContinuity() {
        let calendar         = Calendar.current
        let lastActivityDate = UserDefaults.standard.object(forKey: "last_xp_date") as? Date ?? .distantPast

        if !calendar.isDateInToday(lastActivityDate) {
            let yesterday        = calendar.date(byAdding: .day, value: -1, to: Date())!
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
