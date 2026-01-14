//
//  LeaveGroupDelegate.swift
//  Group_11_Revisio
//
//  Created by Chirag Poojari on 12/12/25.
//

import Foundation

protocol LeaveGroupDelegate: AnyObject {
    func didLeaveGroup(_ group: Group)
    func didUpdateGroup(_ group: Group)
}
