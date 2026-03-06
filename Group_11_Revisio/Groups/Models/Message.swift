//
//  Message.swift
//  Group_11_Revisio
//

import Foundation

struct Message: Codable {
    let id: UUID
    let groupId: UUID
    let senderId: UUID
    let content: String
    let createdAt: Date
    let fileUrl: String?
    let fileName: String?
    let fileType: String?   // "image", "document", "link"

    enum CodingKeys: String, CodingKey {
        case id
        case groupId   = "group_id"
        case senderId  = "sender_id"
        case content
        case createdAt = "created_at"
        case fileUrl   = "file_url"
        case fileName  = "file_name"
        case fileType  = "file_type"
    }
}
