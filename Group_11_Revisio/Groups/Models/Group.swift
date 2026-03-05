//
//  Group.swift
//  Group_11_Revisio
//
//  Created by Chirag Poojari on 26/11/25.
//

import Foundation

struct Group: Codable {
    var id: String
    var name: String
    var avatarName: String

    enum CodingKeys: String, CodingKey {
        case id
        case name
        case avatarName = "avatar_name"
    }
}
