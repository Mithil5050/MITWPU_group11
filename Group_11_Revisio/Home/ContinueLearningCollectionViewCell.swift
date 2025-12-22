import UIKit

class ContinueLearningCollectionViewCell: UICollectionViewCell {
    
    // MARK: - IBOutlets
    @IBOutlet weak var ContinueLearning: UIView!
    
    // MARK: - Lifecycle
    override func awakeFromNib() {
        super.awakeFromNib()
        setupAdaptiveUI()
    }
    
    // MARK: - UI Configuration
    private func setupAdaptiveUI() {
        // 1. Define the Dynamic Color logic
        // We use your custom hex for Light mode and a semantic color for Dark mode
        ContinueLearning.backgroundColor = UIColor { traitCollection in
            return traitCollection.userInterfaceStyle == .dark ?
                   .secondarySystemGroupedBackground :
                   UIColor(hex: "F5F5F5")
        }
        
        // 2. Apply Modern iOS 26 Visual Patterns
        // Smooth continuous corners are the standard for premium prototypes
        ContinueLearning.layer.cornerRadius = 16.0
        ContinueLearning.layer.cornerCurve = .continuous
        
        // 3. Add a dynamic separator border for definition
//        ContinueLearning.layer.borderWidth = 1.0
//        ContinueLearning.layer.borderColor = UIColor.separator.cgColor
    }
    
    // MARK: - Environment Handling
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        
        // CALayer colors (CGColor) do not update automatically.
        // We must re-resolve the border color when the theme changes.
        if traitCollection.hasDifferentColorAppearance(comparedTo: previousTraitCollection) {
            ContinueLearning.layer.borderColor = UIColor.separator.cgColor
        }
    }
}
