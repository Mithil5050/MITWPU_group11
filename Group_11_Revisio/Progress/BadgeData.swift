//
//  BadgeModels.swift
//  Placeholder badge models and data for AwardsViewController and related views.
//

import Foundation

/// Represents the state of a badge.
enum BadgeState {
    case locked
    case inProgress
    case earned
}

/// Represents the tier of a badge.
enum BadgeTier: Int {
    case one = 1
    case two
    case three
}

/// Model representing a badge.
struct Badge {
    let title: String
    let imageAssetName: String
    let startingXP: Int
    let goalXP: Int
    let isEarned: Bool
    let earnedDate: Date?
    let progress: Double       // From 0.0 to 1.0
    let currentValue: Int
    let goalValue: Int
    let tier: BadgeTier
    let state: BadgeState
}

/// Provides sample badge data.
/// This is placeholder data to enable compilation and running of UI components.
struct BadgeData {
    
    /// All badges including regular and milestone badges.
    static let allBadges: [Badge] = [
        Badge(
            title: "Swift Beginner",
            imageAssetName: "badge_swift_beginner",
            startingXP: 0,
            goalXP: 100,
            isEarned: false,
            earnedDate: nil,
            progress: 0.5,
            currentValue: 50,
            goalValue: 100,
            tier: .one,
            state: .inProgress
        ),
        Badge(
            title: "iOS Developer",
            imageAssetName: "badge_ios_developer",
            startingXP: 100,
            goalXP: 300,
            isEarned: true,
            earnedDate: Date(timeIntervalSinceNow: -86400 * 10),
            progress: 1.0,
            currentValue: 300,
            goalValue: 300,
            tier: .two,
            state: .earned
        ),
        Badge(
            title: "App Architect",
            imageAssetName: "badge_app_architect",
            startingXP: 300,
            goalXP: 600,
            isEarned: false,
            earnedDate: nil,
            progress: 0.0,
            currentValue: 0,
            goalValue: 600,
            tier: .three,
            state: .locked
        )
    ]
    
    /// Milestone badges with special achievements.
    static let milestoneBadges: [Badge] = [
        Badge(
            title: "1000 XP Milestone",
            imageAssetName: "badge_milestone_1000xp",
            startingXP: 900,
            goalXP: 1000,
            isEarned: false,
            earnedDate: nil,
            progress: 0.75,
            currentValue: 750,
            goalValue: 1000,
            tier: .three,
            state: .inProgress
        ),
        Badge(
            title: "5000 XP Milestone",
            imageAssetName: "badge_milestone_5000xp",
            startingXP: 4000,
            goalXP: 5000,
            isEarned: false,
            earnedDate: nil,
            progress: 0.0,
            currentValue: 0,
            goalValue: 5000,
            tier: .three,
            state: .locked
        )
    ]
}
