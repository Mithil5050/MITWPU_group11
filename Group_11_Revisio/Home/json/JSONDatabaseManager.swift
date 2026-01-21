//
//  JSONDatabaseManager.swift
//  Group_11_Revisio
//
//

import Foundation

class JSONDatabaseManager {
    static let shared = JSONDatabaseManager()
    
    // MARK: - File Names
    private let materialsFileName = "StudyMaterials.json"
    private let planFileName = "StudyPlanData.json"
    private let todaysTasksFileName = "TodaysTasks.json"
    
    private func getFileURL(forName name: String) -> URL {
        let documentDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        return documentDirectory.appendingPathComponent(name)
    }

    // MARK: - Study Materials (Uploads)
    
    func addUploadedFile(name: String) {
        var currentFiles = loadFiles()
        let newContent = StudyContent(filename: name)
        currentFiles.append(newContent)
        saveFiles(currentFiles)
    }

    func saveFiles(_ files: [StudyContent]) {
        do {
            let data = try JSONEncoder().encode(files)
            try data.write(to: getFileURL(forName: materialsFileName))
        } catch {
            print("Save Error: \(error)")
        }
    }
    
    func deleteFile(at index: Int) {
        var currentFiles = loadFiles()
        if index >= 0 && index < currentFiles.count {
            currentFiles.remove(at: index)
            saveFiles(currentFiles)
            print("🗑️ Deleted file at index: \(index)")
        }
    }
    
    func loadFiles() -> [StudyContent] {
        let url = getFileURL(forName: materialsFileName)
        
        if let data = try? Data(contentsOf: url),
           let files = try? JSONDecoder().decode([StudyContent].self, from: data) {
            return files
        }
        
        if let bundleURL = Bundle.main.url(forResource: "StudyMaterials", withExtension: "json"),
           let data = try? Data(contentsOf: bundleURL),
           let files = try? JSONDecoder().decode([StudyContent].self, from: data) {
            return files
        }
        
        return []
    }
    
    // MARK: - Study Plan Logic
    func loadStudyPlan() -> [PlanSubject] {
        let url = getFileURL(forName: planFileName)
        
        if let data = try? Data(contentsOf: url),
           let subjects = try? JSONDecoder().decode([PlanSubject].self, from: data) {
            return subjects
        }
        
        if let bundleURL = Bundle.main.url(forResource: "StudyPlanData", withExtension: "json"),
           let data = try? Data(contentsOf: bundleURL),
           let subjects = try? JSONDecoder().decode([PlanSubject].self, from: data) {
            return subjects
        }
        return []
    }
    
    // MARK: - Today's Tasks Logic
    func loadTodaysTasks() -> [TodaySubject] {
        let url = getFileURL(forName: todaysTasksFileName)
        
        if let data = try? Data(contentsOf: url),
           let subjects = try? JSONDecoder().decode([TodaySubject].self, from: data) {
            return subjects
        }
        
        if let bundleURL = Bundle.main.url(forResource: "TodaysTasks", withExtension: "json"),
           let data = try? Data(contentsOf: bundleURL),
           let subjects = try? JSONDecoder().decode([TodaySubject].self, from: data) {
            return subjects
        }
        
        return []
    }
}
