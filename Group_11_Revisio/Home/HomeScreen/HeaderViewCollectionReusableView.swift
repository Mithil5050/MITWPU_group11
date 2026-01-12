//
//  HeaderViewCollectionReusableView.swift
//  Group_11_Revisio
//
//  Updated: Enforces clear background on selection & trailing chevron
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
        setupViewAllButton()
    }
    
    private func setupViewAllButton() {
        // 1. Initialize Modern Configuration
        var config = UIButton.Configuration.plain()
        
        // 2. Set Text & Color
        config.title = "View All"
        config.baseForegroundColor = .systemBlue
        
        // 3. Force Icon to Trailing Position (Right)
        config.imagePlacement = .trailing
        config.imagePadding = 6 // Space between "View All" and ">"
        
        // 4. Set Font
        config.titleTextAttributesTransformer = UIConfigurationTextAttributesTransformer { incoming in
            var outgoing = incoming
            outgoing.font = UIFont.systemFont(ofSize: 15, weight: .regular)
            return outgoing
        }
        
        viewAllButton.configuration = config
        
        // 5. Automatic State Handling
        viewAllButton.configurationUpdateHandler = { button in
            var updatedConfig = button.configuration
            
            // Create small scale icons
            let symbolConfig = UIImage.SymbolConfiguration(scale: .small)
            let downIcon = UIImage(systemName: "chevron.down", withConfiguration: symbolConfig)
            let upIcon = UIImage(systemName: "chevron.up", withConfiguration: symbolConfig)
            
            // Toggle Image based on selection
            updatedConfig?.image = button.isSelected ? upIcon : downIcon
            
            // FORCE CLEAR BACKGROUND
            // This ensures no gray box appears when the button is in the 'Selected' state
            updatedConfig?.background.backgroundColor = .clear
            
            button.configuration = updatedConfig
        }
    }
    
    func configureHeader(with title: String, showViewAll: Bool, section: Int, isExpanded: Bool = false) {
        titleLabel.text = title
        viewAllButton.isHidden = !showViewAll
        sectionIndex = section
        
        // Triggers the configurationUpdateHandler
        viewAllButton.isSelected = isExpanded
    }
    
    @IBAction func viewAllTapped(_ sender: UIButton) {
        sender.isSelected.toggle()
        delegate?.didTapViewAll(in: sectionIndex)
    }
}
