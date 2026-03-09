//
//  Group.swift
//  Group_11_Revisio
//

import Foundation

struct Group: Codable {
    var id: String
    var name: String
    var avatarUrl: String?  // nil means show the default person.3.fill icon

    enum CodingKeys: String, CodingKey {
        case id
        case name
        case avatarUrl = "avatar_url"
    }
}
