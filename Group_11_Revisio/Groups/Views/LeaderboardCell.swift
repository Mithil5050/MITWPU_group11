//
//  LeaderboardCell.swift
//  Group_11_Revisio
//
//  Created by Chirag Poojari on 12/12/25.
//

import UIKit

class LeaderboardCell: UITableViewCell {
    func configure(rank: Int, name: String, score: Int) {
        textLabel?.text = "\(rank). \(name)"
        detailTextLabel?.text = "\(score)"
    }
}
