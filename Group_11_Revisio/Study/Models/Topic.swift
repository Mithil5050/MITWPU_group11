//
//  Topic.swift
//  Group_11_Revisio
//
//  Created by SDC-USER on 26/11/25.
//

import Foundation

struct Topic: Codable {
    let name: String
    let lastAccessed: String
    let materialType: String
    var largeContentBody: String? 
    var parentSubjectName: String?
    var notesContent: String?
    var cheatsheetContent: String?
}
