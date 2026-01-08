//
//  JSONDatabaseManager.swift
//  MITWPU_group11 
//
//  Created by Mithil on 08/01/26.
//


import Foundation

class JSONDatabaseManager {
    static let shared = JSONDatabaseManager()
    private let fileName = "StudyMaterials.json"
    
    private var fileURL: URL {
        let documentDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        return documentDirectory.appendingPathComponent(fileName)
    }

    // Adds a single file name to the JSON database
    func addUploadedFile(name: String) {
        var currentFiles = loadFiles()
        let newContent = StudyContent(filename: name)
        currentFiles.append(newContent)
        saveFiles(currentFiles)
    }

    func saveFiles(_ files: [StudyContent]) {
        do {
            let data = try JSONEncoder().encode(files)
            try data.write(to: fileURL)
        } catch {
            print("Save Error: \(error)")
        }
    }
    
    // Add this inside class JSONDatabaseManager

    /// Removes the file at the specific index and saves the updated list
    func deleteFile(at index: Int) {
        var currentFiles = loadFiles()
        
        // Safety check to prevent crashing if index is out of bounds
        if index >= 0 && index < currentFiles.count {
            currentFiles.remove(at: index)
            saveFiles(currentFiles)
            print("🗑️ Deleted file at index: \(index)")
        }
    }
    
    func loadFiles() -> [StudyContent] {
        // If file doesn't exist in Documents yet, try to load from Bundle (the file you created above)
        if !FileManager.default.fileExists(atPath: fileURL.path) {
            guard let bundleURL = Bundle.main.url(forResource: "StudyMaterials", withExtension: "json"),
                  let data = try? Data(contentsOf: bundleURL) else { return [] }
            return (try? JSONDecoder().decode([StudyContent].self, from: data)) ?? []
        }
        
        do {
            let data = try Data(contentsOf: fileURL)
            return try JSONDecoder().decode([StudyContent].self, from: data)
        } catch {
            return []
        }
    }
}
