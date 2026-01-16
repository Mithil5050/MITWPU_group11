//
//  UserInfoCellTableViewCell.swift
//  Group_11_Revisio
//
//  Created by Mithil on 08/12/25.
//

import UIKit

class UserInfoCellTableViewCell: UITableViewCell {

    @IBOutlet var pfp: UIImageView!
    @IBOutlet var Edit: UIButton!
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        Edit.layer.cornerRadius = 27
        Edit.backgroundColor = UIColor { traitCollection in
            // Return Light Mode Color if user is not in Dark Mode
            if traitCollection.userInterfaceStyle == .dark {
                return UIColor.secondarySystemBackground // Or your specific Dark Hex
            } else {
                return UIColor(hex: "F7F7F7") // Your specific Light Hex
            }
        }
        pfp.layer.cornerRadius = pfp.frame.size.width / 2
        
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
}
