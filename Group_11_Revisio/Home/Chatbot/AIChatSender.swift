//
//  AIChatSender.swift
//  Group_11_Revisio
//
//  Created by Mithil on 17/01/26.
//


//
//  AIChatModels.swift
//  Group_11_Revisio
//
//  Created for AI Assistant Feature
//

import Foundation
import MessageKit
import UIKit

// Renamed to avoid conflict with ChatSender
struct AIChatSender: SenderType {
    let senderId: String
    let displayName: String
}

// Renamed to avoid conflict with ChatMessage
struct AIChatMessage: MessageType {
    let sender: SenderType
    let messageId: String
    let sentDate: Date
    let kind: MessageKind
}