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
        Badge(title: "Monthly Challenge", detail: "Upcoming Badge: Streak Master II", isLocked: false, imageAssetName: "awards_monthly_main"),
        Badge(title: "Monthly Hustler", detail: "Earned: 13/09/2025", isLocked: false, imageAssetName: "badge1_monthly_hustler"),
        Badge(title: "Flash Genius", detail: "Earned: 18/09/2025", isLocked: false, imageAssetName: "badge2_flash_genuis"),
        Badge(title: "CheatSheet Pro", detail: "Earned: 1/10/2025", isLocked: false, imageAssetName: "badge3_cheatsheet_pro"),
        Badge(title: "Quiz Master", detail: "Unlock the badge", isLocked: true, imageAssetName: "badge4_quiz_master"),
        Badge(title: "Summary Genius", detail: "Unlock the badge", isLocked: true, imageAssetName: "badge5_summary_genius"),
        Badge(title: "Ultimate Grinder", detail: "Unlock the badge", isLocked: true, imageAssetName: "badge6_ultimate_grinder_lock"),
        Badge(title: "Plan Perfected", detail: "Earned: 17/10/2025", isLocked: false, imageAssetName: "badge7_plan_perfected"),
    ]
    
    // NEW: Data for the "Show All" Monthly Badges grid
    // You can update these strings once you have your new badge details ready.
    static let monthlyGridBadges: [Badge] = [
        Badge(title: "Coming Soon", detail: "Locked", isLocked: true, imageAssetName: "new1"),
        Badge(title: "Coming Soon", detail: "Locked", isLocked: true, imageAssetName: "new2"),
        Badge(title: "Coming Soon", detail: "Locked", isLocked: true, imageAssetName: "new3"),
        Badge(title: "Coming Soon", detail: "Locked", isLocked: true, imageAssetName: "new4"),
        Badge(title: "Coming Soon", detail: "Locked", isLocked: true, imageAssetName: "new5"),
        Badge(title: "Coming Soon", detail: "Locked", isLocked: true, imageAssetName: "placeholder"),
        Badge(title: "Coming Soon", detail: "Locked", isLocked: true, imageAssetName: "placeholder"),
        Badge(title: "Coming Soon", detail: "Locked", isLocked: true, imageAssetName: "placeholder")
    ]
}
