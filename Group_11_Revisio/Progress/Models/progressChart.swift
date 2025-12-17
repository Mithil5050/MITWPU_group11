//
//  progressChart.swift
//  Group_11_Revisio
//
//  Created by Ashika Yadav on 17/12/25.
//

import Foundation

struct StudyData: Identifiable {
    let id = UUID()
    let label: String
    let hours: Double
}

struct StudyChartModel {

    static let dayData: [StudyData] = [
        StudyData(label: "6 AM", hours: 2),
        StudyData(label: "9 AM", hours: 4),
        StudyData(label: "12 PM", hours: 6),
        StudyData(label: "3 PM", hours: 5),
        StudyData(label: "6 PM", hours: 3)
    ]

    static let weekData: [StudyData] = [
        StudyData(label: "Mon", hours: 6),
        StudyData(label: "Tue", hours: 5),
        StudyData(label: "Wed", hours: 3),
        StudyData(label: "Thu", hours: 7),
        StudyData(label: "Fri", hours: 4),
        StudyData(label: "Sat", hours: 5),
        StudyData(label: "Sun", hours: 6)
    ]
}

