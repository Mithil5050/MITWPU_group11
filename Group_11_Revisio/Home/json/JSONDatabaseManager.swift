//
//  JSONDatabaseManager.swift
//  Group_11_Revisio
//

import Foundation

// ✅ 1. Re-define the missing struct here
struct StudyContent: Codable {
    let filename: String
    let dateAdded: Date
    
    init(filename: String, dateAdded: Date = Date()) {
        self.filename = filename
        self.dateAdded = dateAdded
    }
}

class JSONDatabaseManager {
    static let shared = JSONDatabaseManager()
    
    // MARK: - File Names
    private let materialsFileName = "StudyMaterials.json"
    
    // Removed: planFileName, todaysTasksFileName (Files deleted)
    
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
        
        // 1. Try loading from Documents (User changes)
        if let data = try? Data(contentsOf: url),
           let files = try? JSONDecoder().decode([StudyContent].self, from: data) {
            return files
        }
        
        // 2. Fallback to Bundle (Initial Data)
        if let bundleURL = Bundle.main.url(forResource: "StudyMaterials", withExtension: "json"),
           let data = try? Data(contentsOf: bundleURL),
           let files = try? JSONDecoder().decode([StudyContent].self, from: data) {
            return files
        }
        
        return []
    }
}
