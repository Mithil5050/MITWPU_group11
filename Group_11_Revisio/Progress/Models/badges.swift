import Foundation

// MARK: - Badge Data Model
// Represents a single award or achievement item
struct Badge {
    let title: String
    let detail: String
    let isLocked: Bool
    let imageAssetName: String
}

// MARK: - Data Manager
struct BadgeData {
    
    // Data for the main Awards/Achievements screen
    static let allBadges: [Badge] = [
        Badge(title: "Monthly Challenge", detail: "Upcoming Badge: Pace Setter", isLocked: false, imageAssetName: "awards_monthly_main"),
        Badge(title: "Squad MVP", detail: "Earned: 13/09/2025", isLocked: false, imageAssetName: "badge1_squad_mvp"),
        Badge(title: "Flash Genius", detail: "Earned: 18/09/2025", isLocked: false, imageAssetName: "badge2_flash_genuis"),
        Badge(title: "Monthly Hustler", detail: "Earned: 1/10/2025", isLocked: false, imageAssetName: "badge3_monthly_hustler"),
        Badge(title: "Plan Perfected", detail: "Earned: 17/10/2025", isLocked: false, imageAssetName: "badge4_plan_perfected"),
        Badge(title: "Quiz Master", detail: "Unlock the badge", isLocked: true, imageAssetName: "badge5_quiz_master_lock"),
        Badge(title: "Streak Master", detail: "Unlock the badge", isLocked: true, imageAssetName: "badge6_streak_master_lock")
    ]
    
    // NEW: Data for the "Show All" Monthly Badges grid
    // You can update these strings once you have your new badge details ready.
    static let monthlyGridBadges: [Badge] = [
        Badge(title: "Coming Soon", detail: "Locked", isLocked: true, imageAssetName: "placeholder"),
        Badge(title: "Coming Soon", detail: "Locked", isLocked: true, imageAssetName: "placeholder"),
        Badge(title: "Coming Soon", detail: "Locked", isLocked: true, imageAssetName: "placeholder"),
        Badge(title: "Coming Soon", detail: "Locked", isLocked: true, imageAssetName: "placeholder"),
        Badge(title: "Coming Soon", detail: "Locked", isLocked: true, imageAssetName: "placeholder"),
        Badge(title: "Coming Soon", detail: "Locked", isLocked: true, imageAssetName: "placeholder"),
        Badge(title: "Coming Soon", detail: "Locked", isLocked: true, imageAssetName: "placeholder"),
        Badge(title: "Coming Soon", detail: "Locked", isLocked: true, imageAssetName: "placeholder")
    ]
}
