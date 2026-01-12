//
//  UploadContentCollectionViewCell.swift
//  Group_11_Revisio
//
//  Created by Mithil on 10/12/25.
//

import UIKit

protocol UploadContentCellDelegate: AnyObject {
    func uploadCellDidTapDocument(_ cell: UploadContentCollectionViewCell)
    func uploadCellDidTapMedia(_ cell: UploadContentCollectionViewCell)
    func uploadCellDidTapLink(_ cell: UploadContentCollectionViewCell)
    func uploadCellDidTapText(_ cell: UploadContentCollectionViewCell)
}

class UploadContentCollectionViewCell: UICollectionViewCell {

    // MARK: - Outlets
    @IBOutlet weak var containerView: UIView!
    
    // The 4 White Button Containers
    @IBOutlet weak var docContainer: UIView!
    @IBOutlet weak var mediaContainer: UIView!
    @IBOutlet weak var linkContainer: UIView!
    @IBOutlet weak var textContainer: UIView!
    
    weak var delegate: UploadContentCellDelegate?

    override func awakeFromNib() {
        super.awakeFromNib()
        setupMainCard()
        setupButtons()
        addGestures()
    }

    // MARK: - Styling
    
    private func setupMainCard() {
            // Dynamic Background for the Main Container
            // Light Mode: #F5F5F5, Dark Mode: System Secondary Grouped Background
            containerView.backgroundColor = UIColor { traitCollection in
                if traitCollection.userInterfaceStyle == .dark {
                    return .secondarySystemGroupedBackground
                } else {
                    return UIColor(hex: "F5F5F5")
                }
            }
            
            containerView.layer.cornerRadius = 20
            containerView.clipsToBounds = true
        }
    
    private func setupButtons() {
            let containers = [docContainer, mediaContainer, linkContainer, textContainer]
            
            for view in containers {
                guard let view = view else { continue }
                
                // Dynamic Background for the Buttons
                // Light Mode: Pure White (Stands out on F5F5F5 container)
                // Dark Mode: Tertiary Grouped (Stands out on Secondary container)
                view.backgroundColor = UIColor { traitCollection in
                    if traitCollection.userInterfaceStyle == .dark {
                        return .tertiarySystemGroupedBackground
                    } else {
                        return .white
                    }
                }
                
                view.layer.cornerRadius = 16
                
                // Shadows
                view.layer.shadowColor = UIColor.black.cgColor
                view.layer.shadowOpacity = 0.05
                view.layer.shadowOffset = CGSize(width: 0, height: 2)
                view.layer.shadowRadius = 4
                view.layer.masksToBounds = false
            }
        
    }

    // MARK: - Interaction (Tap Gestures)
    
    private func addGestures() {
        let docTap = UITapGestureRecognizer(target: self, action: #selector(handleDocTap))
        docContainer.addGestureRecognizer(docTap)
        
        let mediaTap = UITapGestureRecognizer(target: self, action: #selector(handleMediaTap))
        mediaContainer.addGestureRecognizer(mediaTap)
        
        let linkTap = UITapGestureRecognizer(target: self, action: #selector(handleLinkTap))
        linkContainer.addGestureRecognizer(linkTap)
        
        let textTap = UITapGestureRecognizer(target: self, action: #selector(handleTextTap))
        textContainer.addGestureRecognizer(textTap)
    }
    
    @objc private func handleDocTap() { delegate?.uploadCellDidTapDocument(self) }
    @objc private func handleMediaTap() { delegate?.uploadCellDidTapMedia(self) }
    @objc private func handleLinkTap() { delegate?.uploadCellDidTapLink(self) }
    @objc private func handleTextTap() { delegate?.uploadCellDidTapText(self) }
    
    func configure(with items: [ContentItem]) {
        // No data config needed for static layout
    }
}
