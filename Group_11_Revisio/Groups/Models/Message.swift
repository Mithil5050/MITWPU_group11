//
//  Message.swift
//  Group_11_Revisio
//
//  Created by Chirag Poojari on 10/12/25.
//

import Foundation

struct Message: Codable {
    let id: UUID
    let groupId: UUID
    let senderId: UUID
    let content: String
    let createdAt: Date

    enum CodingKeys: String, CodingKey {
        case id
        case groupId = "group_id"
        case senderId = "sender_id"
        case content
        case createdAt = "created_at"
    }
}
