//
//  UserInfoCellTableViewCell.swift
//  Group_11_Revisio
//
//  Created by Mithil on 08/12/25.
//

import UIKit

class UserInfoCellTableViewCell: UITableViewCell {

    // MARK: - Outlets
    @IBOutlet weak var pfp: UIImageView!
    @IBOutlet weak var Edit: UIButton!
    
    // ⚠️ IMPORTANT: You must connect this Label in your XIB file!
    @IBOutlet weak var nameLabel: UILabel!
    
    // ✅ THIS FIXES THE ERROR: The closure variable
    var didTapEditButton: (() -> Void)?

    override func awakeFromNib() {
        super.awakeFromNib()
        setupUI()
    }
    
    private func setupUI() {
        // Round Image
        pfp.layer.cornerRadius = pfp.frame.size.width / 2
        pfp.clipsToBounds = true
        pfp.contentMode = .scaleAspectFill
        
        // Style Edit Button
        Edit.layer.cornerRadius = 20 // Adjusted radius
        Edit.backgroundColor = UIColor { traitCollection in
            return traitCollection.userInterfaceStyle == .dark ? .secondarySystemBackground : UIColor(red: 0.97, green: 0.97, blue: 0.97, alpha: 1.0)
        }
        
        // ✅ Add Action Target
        Edit.addTarget(self, action: #selector(editButtonTapped), for: .touchUpInside)
    }

    // MARK: - Configuration
    func configure(name: String, image: UIImage?) {
        // Only set text if nameLabel is connected to avoid crash
        if let label = nameLabel {
            label.text = name
        } else {
            print("⚠️ WARNING: nameLabel is not connected in UserInfoCell.xib")
        }
        
        if let img = image {
            pfp.image = img
        } else {
            pfp.image = UIImage(systemName: "person.circle.fill")
        }
    }
    
    // MARK: - Actions
    @objc private func editButtonTapped() {
        // Trigger the closure when button is pressed
        didTapEditButton?()
    }
}
