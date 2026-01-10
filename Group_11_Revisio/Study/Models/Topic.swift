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
    var largeContentBody: String? // Move this UP to position 4
    
    var parentSubjectName: String? // Move this DOWN to the end
}
