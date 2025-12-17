//
//  badges.swift
//  Group_11_Revisio
//
//  Created by Ashika Yadav on 16/12/25.
//

import Foundation

// MARK: - Badge Data Model
// Represents a single award or achievement item
struct Badge {
    let title: String
    let detail: String
    let isLocked: Bool
    let imageAssetName: String
}
// Create a Data Manager to hold your list
struct BadgeData {
    static let allBadges: [Badge] = [
        Badge(title: "Monthly Challenge", detail: "Upcoming Badge: Pace Setter", isLocked: false, imageAssetName: "awards_monthly_main"),
        Badge(title: "Squad MVP", detail: "Earned: 13/09/2025", isLocked: false, imageAssetName: "badge1_squad_mvp"),
        Badge(title: "Flash Genius", detail: "Earned: 18/09/2025", isLocked: false, imageAssetName: "badge2_flash_genuis"),
        Badge(title: "Monthly Hustler", detail: "Earned: 1/10/2025", isLocked: false, imageAssetName: "badge3_monthly_hustler"),
        Badge(title: "Plan Perfected", detail: "Earned: 17/10/2025", isLocked: false, imageAssetName: "badge4_plan_perfected"),
        Badge(title: "Quiz Master", detail: "Unlock the badge", isLocked: true, imageAssetName: "badge5_quiz_master_lock"),
        Badge(title: "Streak Master", detail: "Unlock the badge", isLocked: true, imageAssetName: "badge6_streak_master_lock")
    ]
}
