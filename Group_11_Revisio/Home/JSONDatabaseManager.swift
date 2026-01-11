//
//  JSONDatabaseManager.swift
//  Updated for Study Plan Support
//

import Foundation

class JSONDatabaseManager {
    static let shared = JSONDatabaseManager()
    
    // MARK: - Existing Properties
    private let materialsFileName = "StudyMaterials.json"
    private let planFileName = "StudyPlanData.json" // 🆕 New JSON File
    
    private func getFileURL(forName name: String) -> URL {
        let documentDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        return documentDirectory.appendingPathComponent(name)
    }

    // MARK: - Study Materials Logic (Existing)
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
        }
    }
    
    func loadFiles() -> [StudyContent] {
        let url = getFileURL(forName: materialsFileName)
        if !FileManager.default.fileExists(atPath: url.path) {
            // Fallback to Bundle if not in Documents
            guard let bundleURL = Bundle.main.url(forResource: "StudyMaterials", withExtension: "json"),
                  let data = try? Data(contentsOf: bundleURL) else { return [] }
            return (try? JSONDecoder().decode([StudyContent].self, from: data)) ?? []
        }
        
        do {
            let data = try Data(contentsOf: url)
            return try JSONDecoder().decode([StudyContent].self, from: data)
        } catch {
            return []
        }
    }
    
    // MARK: - 🆕 Study Plan Logic
    func loadStudyPlan() -> [PlanSubject] {
        let url = getFileURL(forName: planFileName)
        
        // 1. Try loading from Documents (User specific data)
        if let data = try? Data(contentsOf: url),
           let subjects = try? JSONDecoder().decode([PlanSubject].self, from: data) {
            return subjects
        }
        
        // 2. Fallback: Load from App Bundle (Default data included with app)
        if let bundleURL = Bundle.main.url(forResource: "StudyPlanData", withExtension: "json"),
           let data = try? Data(contentsOf: bundleURL),
           let subjects = try? JSONDecoder().decode([PlanSubject].self, from: data) {
            return subjects
        }
        
        return [] // Return empty if nothing found
    }
}
