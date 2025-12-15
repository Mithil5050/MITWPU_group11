//
//  ChatModels.swift
//  Group_11_Revisio
//
//  Created by Chirag Poojari on 15/12/25.
//

import Foundation
import MessageKit
import UIKit

struct ChatSender: SenderType {
    let senderId: String
    let displayName: String
}

struct ChatMessage: MessageType {
    let sender: SenderType
    let messageId: String
    let sentDate: Date
    let kind: MessageKind
}
