//
//  AIChatSender.swift
//  Group_11_Revisio
//
//  Created by Mithil on 17/01/26.
//


import Foundation
import MessageKit
import UIKit

struct AIChatSender: SenderType {
    let senderId: String
    let displayName: String
}

struct AIChatMessage: MessageType {
    let sender: SenderType
    let messageId: String
    let sentDate: Date
    let kind: MessageKind
}
