//
//  progressChart.swift
//  Group_11_Revisio
//
//  Created by Ashika Yadav on 17/12/25.
//

//import Foundation
//
//struct StudyData: Identifiable {
//    let id = UUID()
//    let label: String
//    let hours: Double
//}
//
//struct StudyChartModel {
//
//    static let dayData: [StudyData] = [
//        StudyData(label: "6 AM", hours: 2),
//        StudyData(label: "9 AM", hours: 4),
//        StudyData(label: "12 PM", hours: 6),
//        StudyData(label: "3 PM", hours: 5),
//        StudyData(label: "6 PM", hours: 3)
//    ]
//
//    static let weekData: [StudyData] = [
//        StudyData(label: "Mon", hours: 6),
//        StudyData(label: "Tue", hours: 5),
//        StudyData(label: "Wed", hours: 3),
//        StudyData(label: "Thu", hours: 7),
//        StudyData(label: "Fri", hours: 4),
//        StudyData(label: "Sat", hours: 5),
//        StudyData(label: "Sun", hours: 6)
//    ]
//}
//
import Foundation

struct StudyData: Identifiable {
    let id = UUID()
    let label: String
    let focusMinutes: Double
    let extraMinutes: Double
}

struct StudyChartModel {

    static let dayData: [StudyData] = [
        StudyData(label: "00", focusMinutes: 8,  extraMinutes: 2),
        StudyData(label: "02", focusMinutes: 5,  extraMinutes: 1),
        StudyData(label: "04", focusMinutes: 30, extraMinutes: 12),
        StudyData(label: "08", focusMinutes: 18, extraMinutes: 6),
        StudyData(label: "10", focusMinutes: 6,  extraMinutes: 2)
    ]

    static let weekData: [StudyData] = [
        StudyData(label: "Mon", focusMinutes: 40, extraMinutes: 10),
        StudyData(label: "Tue", focusMinutes: 35, extraMinutes: 8),
        StudyData(label: "Wed", focusMinutes: 20, extraMinutes: 5),
        StudyData(label: "Thu", focusMinutes: 50, extraMinutes: 12),
        StudyData(label: "Fri", focusMinutes: 30, extraMinutes: 6)
    ]
}

