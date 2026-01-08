// Swift: GradientView.swift
import UIKit

@IBDesignable // Allows viewing the gradient directly in Storyboard
class GradientView: UIView {

    // Define the gradient layer
    private let gradientLayer = CAGradientLayer()

    // Define the colors (Set default colors matching the target design aesthetic)
    @IBInspectable var startColor: UIColor = UIColor(red: 0.5, green: 0.7, blue: 1.0, alpha: 1.0) { // Light Blue
        didSet { updateGradient() }
    }

    @IBInspectable var endColor: UIColor = UIColor(red: 0.7, green: 1.0, blue: 0.7, alpha: 1.0) { // Light Green
        didSet { updateGradient() }
    }
    
    // MODIFIED: Direction set for Left-to-Right
    @IBInspectable var startPointX: CGFloat = 0.0 { didSet { updateGradient() } } // Start at Left edge
    @IBInspectable var startPointY: CGFloat = 0.5 { didSet { updateGradient() } } // Start at Y center (Middle)
    @IBInspectable var endPointX: CGFloat = 1.0 { didSet { updateGradient() } } // End at Right edge
    @IBInspectable var endPointY: CGFloat = 0.5 { didSet { updateGradient() } } // End at Y center (Middle)

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupGradient()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupGradient()
    }

    // Crucial: Update the frame of the gradient layer whenever the view size changes.
    override func layoutSubviews() {
        super.layoutSubviews()
        gradientLayer.frame = bounds
        // Ensure the corner radius is applied to the layer as well
        gradientLayer.cornerRadius = layer.cornerRadius
    }

    private func setupGradient() {
        // Apply the gradient layer at index 0 so it sits behind other content (like labels/images)
        self.layer.insertSublayer(gradientLayer, at: 0)
        updateGradient()
    }

    private func updateGradient() {
        gradientLayer.colors = [startColor.cgColor, endColor.cgColor]
        
        // Define the direction of the gradient
        gradientLayer.startPoint = CGPoint(x: startPointX, y: startPointY)
        gradientLayer.endPoint = CGPoint(x: endPointX, y: endPointY)
    }
}
