//
//  GroupCell.swift
//  Group_11_Revisio
//
//  Created by Chirag Poojari on 27/11/25.
//

import UIKit

class GroupCell: UITableViewCell {

    
    @IBOutlet weak var groupNameLabel: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()

        self.accessoryType = .disclosureIndicator
        self.selectionStyle = .none
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
