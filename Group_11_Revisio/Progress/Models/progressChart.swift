//
//  progressChart.swift
//  Group_11_Revisio
//
//  Created by Ashika Yadav on 17/12/25.
//
import Foundation
import SwiftUI
import Combine

// MARK: - Chart Data Model
struct StudyData: Identifiable, Codable, Hashable {
    var id = UUID()
    let label: String
    let focusMinutes: Double
    let extraMinutes: Double
    
    // Custom initializer to allow manual creation and decoding
    init(label: String, focusMinutes: Double, extraMinutes: Double) {
        self.label = label
        self.focusMinutes = focusMinutes
        self.extraMinutes = extraMinutes
    }
    
    // CodingKeys ensure UUID doesn't conflict during JSON parsing
    enum CodingKeys: String, CodingKey {
        case label, focusMinutes, extraMinutes
    }
}

// MARK: - Log History Model (Matches your JSON structure)
struct LogHistoryItem: Codable, Identifiable {
    var id: String
    let amount: String
    let hours: Double
    let time: String
    let date: Date
}

struct LogDataWrapper: Codable {
    var logs: [LogHistoryItem]
}

// MARK: - Study Chart ViewModel
class StudyChartModel: ObservableObject {
    @Published var dailyHistory: [[StudyData]] = [[]]
    @Published var weeklyHistory: [[StudyData]] = [[]]
    
    init() {
        // Initial empty state or dummy data load
        loadDummyData()
    }
    
    /// Loads the initial state from your StudyData.json file
    func loadDummyData() {
        guard let url = Bundle.main.url(forResource: "StudyData", withExtension: "json"),
              let data = try? Data(contentsOf: url) else {
            print("❌ Could not find StudyData.json")
            return
        }
        
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601 // Handles the "2026-01-14T..." format
        
        do {
            let wrapper = try decoder.decode(LogDataWrapper.self, from: data)
            updateChart(with: wrapper.logs)
        } catch {
            print("❌ Error decoding JSON: \(error)")
        }
    }

    func updateChart(with logs: [LogHistoryItem]) {
        let calendar = Calendar.current
        let now = Date()
        
        // --- 1. DAILY PAGING (Last 14 Days) ---
        var dailyPages: [[StudyData]] = []
        
        // Create pages for the last 14 days (from 13 days ago until today)
        for offset in 0..<14 {
            let targetDate = calendar.date(byAdding: .day, value: -13 + offset, to: now)!
            let startOfTargetDay = calendar.startOfDay(for: targetDate)
            
            // Filter logs that happened on this specific day
            let logsForDay = logs.filter { calendar.isDate($0.date, inSameDayAs: startOfTargetDay) }
            
            var slots: [String: Double] = ["00": 0, "06": 0, "12": 0, "18": 0]
            for log in logsForDay {
                let hour = calendar.component(.hour, from: log.date)
                let label = hour < 6 ? "00" : (hour < 12 ? "06" : (hour < 18 ? "12" : "18"))
                slots[label, default: 0] += (log.hours * 60)
            }
            
            let pageData = slots.map { StudyData(label: $0.key, focusMinutes: $0.value, extraMinutes: 0) }
                .sorted { $0.label < $1.label }
            dailyPages.append(pageData)
        }
        
        // --- 2. WEEKLY PAGING (Last 4 Weeks) ---
        var weeklyPages: [[StudyData]] = []
        let daysOrder = ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"]
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "EEE"
        dateFormatter.locale = Locale(identifier: "en_US_POSIX")

        // Create pages for the last 4 weeks
        for weekOffset in 0..<4 {
            // Find the start of the week for each of the last 4 weeks
            guard let targetWeekDate = calendar.date(byAdding: .weekOfYear, value: -3 + weekOffset, to: now),
                  let weekRange = calendar.dateInterval(of: .weekOfYear, for: targetWeekDate) else { continue }
            
            // Filter logs that fall within this week's start and end dates
            let logsForWeek = logs.filter { $0.date >= weekRange.start && $0.date < weekRange.end }
            
            var weeklySlots: [String: Double] = ["Mon": 0, "Tue": 0, "Wed": 0, "Thu": 0, "Fri": 0, "Sat": 0, "Sun": 0]
            for log in logsForWeek {
                let dayLabel = dateFormatter.string(from: log.date)
                if weeklySlots.keys.contains(dayLabel) {
                    weeklySlots[dayLabel, default: 0] += (log.hours * 60)
                }
            }
            
            let pageData = daysOrder.map { day in
                StudyData(label: day, focusMinutes: weeklySlots[day] ?? 0, extraMinutes: 0)
            }
            weeklyPages.append(pageData)
        }

        // --- 3. UI REFRESH ---
        DispatchQueue.main.async {
            self.dailyHistory = dailyPages
            self.weeklyHistory = weeklyPages
        }
    }
}
