//
//  Topic.swift
//  Group_11_Revisio
//
//  Created by SDC-USER on 26/11/25.
//

import Foundation
// Topic.swift


struct Topic:Codable {
    let name: String
    let lastAccessed: String
    let materialType: String
   
    var parentSubjectName: String?
    
    var largeContentBody: String?
}
