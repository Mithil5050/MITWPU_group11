//
//  MonthlyBadgeCollectionViewCell.swift
//  Group_11_Revisio
//
//  Created by Ashika Yadav on 16/12/25.
//

import UIKit


protocol MonthlyBadgeCellDelegate: AnyObject {
    func didTapShowAllButton()
    func didTapMonthlyBadgeCard()
    func didTapXPInfo()    
}
class MonthlyBadgeCollectionViewCell: UICollectionViewCell {
    
    
    @IBOutlet weak var monthlyBadgeImageView: UIImageView!
    @IBOutlet weak var xpLabel: UILabel!
    
    @IBOutlet weak var xpProgressBar: UIProgressView!
    
    @IBOutlet weak var xpValueLabel: UILabel!
    
    @IBOutlet weak var monthlyBadgeContainerView: UIView!
    
    weak var delegate: MonthlyBadgeCellDelegate?

    // Tag guards the ⓘ button from being added twice on cell reuse
       private let infoButtonTag = 8_002

       override func awakeFromNib() {
           super.awakeFromNib()
           setupAppleLayout()
           setupCardStyle()
           setupImageTapGesture()
           setupInfoButton()
       }

       private func setupAppleLayout() {
           xpLabel.font      = .systemFont(ofSize: 22, weight: .semibold)
           xpLabel.textColor = .white

           xpValueLabel.font      = .systemFont(ofSize: 14, weight: .regular)
           xpValueLabel.textColor = .systemGray

           xpProgressBar.layer.cornerRadius = 4
           xpProgressBar.clipsToBounds      = true
           xpProgressBar.progressTintColor  = .systemBlue
           xpProgressBar.trackTintColor     = UIColor.systemBlue.withAlphaComponent(0.2)

           if let sub = xpProgressBar.subviews.last {
               sub.layer.cornerRadius = 4
               sub.clipsToBounds = true
           }
       }

       func configure(with badge: Badging.Badge) {
           let manager    = ProgressDataManager.shared
           let currentXP  = manager.currentLevelXP
           let requiredXP = manager.requiredXPForCurrentLevel
           let level      = manager.userLevel

           xpLabel.text   = "Xp Progress"
           xpValueLabel.text = "\(currentXP) / \(requiredXP) XP"

           if let image = UIImage(named: "awards_monthly_main") {
               monthlyBadgeImageView.image    = image
               monthlyBadgeImageView.alpha    = 1.0
               monthlyBadgeImageView.isHidden = false
           } else {
               monthlyBadgeImageView.image     = UIImage(systemName: "lock.fill")
               monthlyBadgeImageView.tintColor = .systemGray
               monthlyBadgeImageView.alpha     = 0.3
           }
           contentView.bringSubviewToFront(monthlyBadgeImageView)

           xpProgressBar.setProgress(0, animated: false)
           UIView.animate(withDuration: 0.3, delay: 0, options: .curveEaseInOut) {
               self.xpProgressBar.setProgress(manager.progressToNextLevel, animated: true)
           }
       }

    // ⓘ Button
       private func setupInfoButton() {
           guard contentView.viewWithTag(infoButtonTag) == nil else { return }

           let button = UIButton(type: .system)
           button.tag = infoButtonTag
           button.setImage(UIImage(systemName: "info.circle"), for: .normal)
           button.tintColor = UIColor.white.withAlphaComponent(0.6)
           button.translatesAutoresizingMaskIntoConstraints = false
           button.addTarget(self, action: #selector(infoTapped), for: .touchUpInside)

           contentView.addSubview(button)
           NSLayoutConstraint.activate([
               button.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 10),
               button.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -12),
               button.widthAnchor.constraint(equalToConstant: 26),
               button.heightAnchor.constraint(equalToConstant: 26)
           ])
       }

       @objc private func infoTapped() {
           delegate?.didTapXPInfo()
       }

    // Badge image tap
       private func setupImageTapGesture() {
           monthlyBadgeImageView.isUserInteractionEnabled = true
           let tap = UITapGestureRecognizer(target: self, action: #selector(imageTapped))
           monthlyBadgeImageView.addGestureRecognizer(tap)
       }

       @objc private func imageTapped() {
           delegate?.didTapMonthlyBadgeCard()
       }


       private func setupCardStyle() {
           backgroundColor              = .clear
           contentView.backgroundColor  = .clear

           let blurEffect = UIBlurEffect(style: .systemThinMaterialDark)
           let blurView   = UIVisualEffectView(effect: blurEffect)
           blurView.frame = bounds
           blurView.autoresizingMask  = [.flexibleWidth, .flexibleHeight]
           blurView.layer.cornerRadius = 16
           blurView.clipsToBounds      = true

           contentView.insertSubview(blurView, at: 0)
       }
   }

























