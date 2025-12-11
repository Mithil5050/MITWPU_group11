//
//  LeaderboardCell.swift
//  Group_11_Revisio
//
//  Created by Chirag Poojari on 11/12/25.
//

import UIKit

class LeaderboardCell: UITableViewCell {
    @IBOutlet weak var rankLabel: UILabel!
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var scoreLabel: UILabel!
    @IBOutlet weak var progressBar: UIView! // simple color bar you can set width

    override func awakeFromNib() {
        super.awakeFromNib()
        rankLabel?.font = UIFont.systemFont(ofSize: 14, weight: .bold)
        nameLabel?.font = UIFont.systemFont(ofSize: 14)
        scoreLabel?.font = UIFont.systemFont(ofSize: 14, weight: .semibold)
    }
}
