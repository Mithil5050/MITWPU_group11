//
//  StudyContent.swift
//  MITWPU_group11 
//
//  Created by Mithil on 08/01/26.
//
import Foundation

struct StudyContent: Codable {
    let id: UUID
    var filename: String
    
    init(filename: String) {
        self.id = UUID()
        self.filename = filename
    }
}
