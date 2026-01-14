//
//  ProgressDataManager.swift
//  Group_11_Revisio
//
//  Created by Ashika Yadav on 14/01/26.
//

import Foundation

class ProgressDataManager {
    static let shared = ProgressDataManager()
    var history: [LogHistoryItem] = []

    func loadInitialData() {
        // Try loading real user data first
        if let savedData = UserDefaults.standard.data(forKey: "UserLogs"),
           let decoded = try? JSONDecoder().decode([LogHistoryItem].self, from: savedData) {
            self.history = decoded
        } else {
            // Fallback to your JSON dummy data if no real logs exist
            loadFromJSONFile()
        }
    }

    private func loadFromJSONFile() {
        guard let url = Bundle.main.url(forResource: "StudyData", withExtension: "json"),
              let data = try? Data(contentsOf: url) else { return }
        
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601 // Critical for your date format
        
        if let decoded = try? decoder.decode(LogDataWrapper.self, from: data) {
            self.history = decoded.logs
        }
    }

    func save() {
        if let encoded = try? JSONEncoder().encode(history) {
            UserDefaults.standard.set(encoded, forKey: "UserLogs")
        }
    }
}

