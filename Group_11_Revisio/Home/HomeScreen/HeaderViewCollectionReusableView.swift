//
//  HeaderViewCollectionReusableView.swift
//  Group_11_Revisio
//

import UIKit

protocol HeaderViewDelegate: AnyObject {
    func didTapViewAll(in section: Int)
}

class HeaderViewCollectionReusableView: UICollectionReusableView {

    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var viewAllButton: UIButton!
    
    weak var delegate: HeaderViewDelegate?
    var sectionIndex: Int = 0

    override func awakeFromNib() {
        super.awakeFromNib()
        viewAllButton.setTitle("View all", for: .normal)
        viewAllButton.setTitle("Close", for: .selected) // Text when expanded
        viewAllButton.setTitleColor(.systemBlue, for: .normal)
    }
    
    func configureHeader(with title: String, showViewAll: Bool, section: Int, isExpanded: Bool = false) {
        titleLabel.text = title
        viewAllButton.isHidden = !showViewAll
        sectionIndex = section
        
        // Update button state based on expansion
        viewAllButton.isSelected = isExpanded
    }
    
    @IBAction func viewAllTapped(_ sender: UIButton) {
        // Toggle visual state immediately for responsiveness
        sender.isSelected.toggle()
        delegate?.didTapViewAll(in: sectionIndex)
    }
}
