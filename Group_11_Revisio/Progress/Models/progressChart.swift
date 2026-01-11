//
//  progressChart.swift
//  Group_11_Revisio
//
//  Created by Ashika Yadav on 17/12/25.
//

import Foundation
import SwiftUI // Adds support for ObservableObject and @Published
internal import Combine

struct StudyData: Identifiable {
    let id = UUID()
    let label: String
    let focusMinutes: Double
    let extraMinutes: Double
}

class StudyChartModel: ObservableObject {
    @Published var dailyHistory: [[StudyData]] = [
        [StudyData(label: "00", focusMinutes: 5, extraMinutes: 2), StudyData(label: "06", focusMinutes: 10, extraMinutes: 3), StudyData(label: "12", focusMinutes: 8, extraMinutes: 2), StudyData(label: "18", focusMinutes: 12, extraMinutes: 4)],
        [StudyData(label: "00", focusMinutes: 4, extraMinutes: 1), StudyData(label: "06", focusMinutes: 15, extraMinutes: 5), StudyData(label: "12", focusMinutes: 20, extraMinutes: 8), StudyData(label: "18", focusMinutes: 5, extraMinutes: 2)],
        [StudyData(label: "00", focusMinutes: 8, extraMinutes: 2), StudyData(label: "06", focusMinutes: 25, extraMinutes: 10), StudyData(label: "12", focusMinutes: 18, extraMinutes: 6), StudyData(label: "18", focusMinutes: 6, extraMinutes: 2)]
    ]
    
    @Published var weeklyHistory: [[StudyData]] = [
        ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"].map { StudyData(label: $0, focusMinutes: 100, extraMinutes: 20) }
    ]
}


//struct StudyChartModel {
//    // Organize your data so each inner array represents ONE FULL DAY or ONE FULL WEEK
//    static var dailyHistory: [[StudyData]] = [
//        // Page 1: Two Days Ago (Full day data)
//        [StudyData(label: "00", focusMinutes: 5, extraMinutes: 2), StudyData(label: "06", focusMinutes: 10, extraMinutes: 3), StudyData(label: "12", focusMinutes: 8, extraMinutes: 2), StudyData(label: "18", focusMinutes: 12, extraMinutes: 4)],
//        // Page 2: Yesterday (Full day data)
//        [StudyData(label: "00", focusMinutes: 4, extraMinutes: 1), StudyData(label: "06", focusMinutes: 15, extraMinutes: 5), StudyData(label: "12", focusMinutes: 20, extraMinutes: 8), StudyData(label: "18", focusMinutes: 5, extraMinutes: 2)],
//        // Page 3: Today (Full day data)
//        [StudyData(label: "00", focusMinutes: 8, extraMinutes: 2), StudyData(label: "06", focusMinutes: 25, extraMinutes: 10), StudyData(label: "12", focusMinutes: 18, extraMinutes: 6), StudyData(label: "18", focusMinutes: 6, extraMinutes: 2)]
//    ]
//    
//    static var weeklyHistory: [[StudyData]] = [
//        // Page 1: Last Week (Mon-Sun)
//        ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"].map { StudyData(label: $0, focusMinutes: 100, extraMinutes: 20) },
//        // Page 2: This Week (Mon-Sun)
//        ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"].map { StudyData(label: $0, focusMinutes: 120, extraMinutes: 30) }
//    ]
//}
