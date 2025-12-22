import UIKit

class StudyPlanCollectionViewCell: UICollectionViewCell {

    // MARK: - IBOutlets
    @IBOutlet weak var StudyPlan: UIView!
    
    // MARK: - Lifecycle
    override func awakeFromNib() {
        super.awakeFromNib()
        setupAdaptiveUI()
    }
    
    // MARK: - UI Configuration
    private func setupAdaptiveUI() {
        // 1. Define the Hybrid Background Color
        // Resolves to your hex in Light mode, and Secondary System Grouped in Dark mode.
        StudyPlan.backgroundColor = UIColor { traitCollection in
            if traitCollection.userInterfaceStyle == .dark {
                return .secondarySystemGroupedBackground
            } else {
                return UIColor(hex: "F5F5F5")
            }
        }
        
        // 2. Modern Surface Smoothing
        StudyPlan.layer.cornerRadius = 16.0
        StudyPlan.layer.cornerCurve = .continuous
        
        // 3. Subtle adaptive border
//        StudyPlan.layer.borderWidth = 1.0
//        StudyPlan.layer.borderColor = UIColor.separator.cgColor
    }
    
    // MARK: - Theme Resolution
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        
        // Core for iOS 26: Re-assigning the borderColor ensures the CALayer
        // respects the new theme immediately upon appearance change.
        if traitCollection.hasDifferentColorAppearance(comparedTo: previousTraitCollection) {
            StudyPlan.layer.borderColor = UIColor.separator.cgColor
        }
    }
}
