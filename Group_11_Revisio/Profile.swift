//
//  Profile.swift
//  Group_11_Revisio
//
//  Created by Ayaana Talwar on 12/02/26.
//

import Foundation

struct Profile: Codable {
    let id: UUID
    var username: String?
    var total_xp: Int
    var current_streak: Int
    
    enum CodingKeys: String, CodingKey {
        case id, username
        case total_xp = "total_xp"
        case current_streak = "current_streak"
    }
}
