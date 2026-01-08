//
//  SubjectCardCell.swift
//  Group_11_Revisio
//
//  Created by Mithil on 10/12/25.
//

import UIKit

// Renamed from StudyPlanSPCollectionViewCell
class SubjectCardCell: UICollectionViewCell {
    
    @IBOutlet var subjectCard: UIView!
    @IBOutlet weak var subjectLabel: UILabel!
    @IBOutlet weak var nextTaskLabel: UILabel!
    @IBOutlet weak var progressContainerView: UIView! // The view that will contain the CircularProgressView

    override func awakeFromNib() {
        super.awakeFromNib()
        
        // 🍏 iOS 26 Aesthetic: Prominent Glass Card
        contentView.layer.cornerRadius = 16
        contentView.clipsToBounds = true
        subjectCard.backgroundColor = UIColor(hex: "91C1EF", alpha: 0.25)
        // Add shadow for depth (optional, depends on specific iOS 26 style)
//        layer.shadowColor = UIColor.black.cgColor
//        layer.shadowOffset = CGSize(width: 0, height: 8)
//        layer.shadowRadius = 8
//        layer.shadowOpacity = 0.1
//        layer.masksToBounds = false
        
        // Initialize and add the circular progress view
        let progressView = CircularProgressView(frame: progressContainerView.bounds)
        progressView.progressColor = .systemGreen
        progressView.lineWidth = 6.0
        progressContainerView.addSubview(progressView)
        progressContainerView.backgroundColor = UIColor(hex: "91C1EF", alpha: 0.05)
        // Set constraints to make the progress view fill the container
        progressView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            progressView.topAnchor.constraint(equalTo: progressContainerView.topAnchor),
            progressView.bottomAnchor.constraint(equalTo: progressContainerView.bottomAnchor),
            progressView.leadingAnchor.constraint(equalTo: progressContainerView.leadingAnchor),
            progressView.trailingAnchor.constraint(equalTo: progressContainerView.trailingAnchor)
        ])
        
        // Example update after setup
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            progressView.progress = 0.75 // Set a sample progress
        }
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        // Ensure the shadow path is updated when the cell's frame changes
//        layer.shadowPath = UIBezierPath(roundedRect: bounds, cornerRadius: contentView.layer.cornerRadius).cgPath
    }
}
