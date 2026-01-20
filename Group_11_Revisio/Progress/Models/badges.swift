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
    
    static let allBadges: [Badge] = [
        Badge(title: "Monthly Challenge", detail: "Upcoming Badge: Streak Master II", isLocked: false, imageAssetName: "awards_monthly_main"),
        
//        Badge(title: "CheatSheet Pro", detail: "6 out of 10", isLocked: false, imageAssetName: "badge3_cheatsheet_pro"),
//        Badge(title: "Monthly Hustler II", detail: "6 out of 10", isLocked: false, imageAssetName: "monthly_hustler1"),
        Badge(title: "Summary Genius", detail: "6 out of 10", isLocked: true, imageAssetName: "badge5_summary_genius"),
        Badge(title: "Quiz Master", detail: "6 out of 10", isLocked: true, imageAssetName: "badge4_quiz_master"),
        Badge(title: "Ultimate Grinder", detail: "6 out of 10", isLocked: true, imageAssetName: "badge6_ultimate_grinder_lock"),
        Badge(title: "Plan Perfected II", detail: "6 out of 10", isLocked: true, imageAssetName: "badge7_plan_perfected"),
        Badge(title: "Streak Master III", detail: "6 out of 10", isLocked: true, imageAssetName: "streak master 3"),
        Badge(title: "Flash Genius", detail: "6 out of 10", isLocked: true, imageAssetName: "badge2_flash_genuis"),
    ]
    
   
    static let earnedBadges: [Badge] = [
//        Badge(title: "Monthly Hustler I", detail: "Earned: 17/10/2025", isLocked: false, imageAssetName: "monthly_hustler1"),
        Badge(title: "Streak Master I", detail: "Earned: 11/10/2025", isLocked: false, imageAssetName: "streak master 1"),
        Badge(title: "Summary Genius", detail: "Earned: 11/10/2025", isLocked: false, imageAssetName: "badge5_summary_genius"),
        Badge(title: "Streak Master II", detail: "Earned: 14/11/2025", isLocked: false, imageAssetName: "streak master 2"),
        Badge(title: "Plan Perfected", detail: "Earned: 14/11/2025", isLocked: false, imageAssetName: "badge7_plan_perfected"),
        Badge(title: "CheatSheet Pro", detail: "Earned: 14/11/2025", isLocked: false, imageAssetName: "badge3_cheatsheet_pro"),
        Badge(title: "Monthly Hustler I", detail: "Earned: 17/10/2025", isLocked: false, imageAssetName: "monthly_hustler1"),
//        Badge(title: "Coming Soon", detail: "Locked", isLocked: true, imageAssetName: "placeholder"),
//        Badge(title: "Coming Soon", detail: "Locked", isLocked: true, imageAssetName: "placeholder")
    ]
}
