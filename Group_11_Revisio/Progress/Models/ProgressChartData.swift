import Foundation
import SwiftUI
import Combine

struct StudyData: Identifiable, Codable, Hashable {
    var id = UUID()
    let label: String
    var studyMinutes: Double = 0
    var gamesMinutes: Double = 0
    
    var totalMinutes: Double {
        studyMinutes + gamesMinutes
    }
}

struct LogHistoryItem: Codable, Identifiable {
    var id: String
    let amount: String
    let hours: Double
    let time: String?
    let date: Date
    let category: String
}

struct LogDataWrapper: Codable {
    var logs: [LogHistoryItem]
}

class StudyChartModel: ObservableObject {
    @Published var dailyHistory: [[StudyData]] = [[]]
    @Published var weeklyHistory: [[StudyData]] = [[]]
    
    init() { loadDummyData() }
    
    func loadDummyData() {
        guard let url = Bundle.main.url(forResource: "ProgressLogData", withExtension: "json"),
              let data = try? Data(contentsOf: url) else { return }
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        if let wrapper = try? decoder.decode(LogDataWrapper.self, from: data) {
            updateChart(with: wrapper.logs)
        }
    }

    func updateChart(with logs: [LogHistoryItem]) {
        let calendar = Calendar.current
        let now = Date()
        var dailyPages: [[StudyData]] = []
        
        for offset in 0..<14 {
            let targetDate = calendar.date(byAdding: .day, value: -13 + offset, to: now)!
            let startOfTargetDay = calendar.startOfDay(for: targetDate)
            let logsForDay = logs.filter { calendar.isDate($0.date, inSameDayAs: startOfTargetDay) }
            var slots = ["00": StudyData(label: "00"), "06": StudyData(label: "06"), "12": StudyData(label: "12"), "18": StudyData(label: "18")]

            for log in logsForDay {
                let hour = calendar.component(.hour, from: log.date)
                let slotKey = hour < 6 ? "00" : (hour < 12 ? "06" : (hour < 18 ? "12" : "18"))
                let mins = log.hours * 60
                if log.category == "Games" {
                    slots[slotKey]?.gamesMinutes += mins
                } else {
                    slots[slotKey]?.studyMinutes += mins
                }
            }
            dailyPages.append(slots.values.sorted { $0.label < $1.label })
        }
        
        var weeklyPages: [[StudyData]] = []
        let daysOrder = ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"]
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "EEE"

        for weekOffset in 0..<4 {
            guard let targetWeekDate = calendar.date(byAdding: .weekOfYear, value: -3 + weekOffset, to: now),
                  let weekRange = calendar.dateInterval(of: .weekOfYear, for: targetWeekDate) else { continue }
            let logsForWeek = logs.filter { $0.date >= weekRange.start && $0.date < weekRange.end }
            var weeklySlots = daysOrder.reduce(into: [String: StudyData]()) { $0[$1] = StudyData(label: $1) }

            for log in logsForWeek {
                let dayLabel = dateFormatter.string(from: log.date)
                let mins = log.hours * 60
                if log.category == "Games" {
                    weeklySlots[dayLabel]?.gamesMinutes += mins
                } else {
                    weeklySlots[dayLabel]?.studyMinutes += mins
                }
            }
            weeklyPages.append(daysOrder.compactMap { weeklySlots[$0] })
        }

        DispatchQueue.main.async {
            self.dailyHistory = dailyPages
            self.weeklyHistory = weeklyPages
        }
    }
}
