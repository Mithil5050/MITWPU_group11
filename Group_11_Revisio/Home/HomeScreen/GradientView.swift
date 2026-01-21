// Swift: GradientView.swift
import UIKit

@IBDesignable
class GradientView: UIView {

    private let gradientLayer = CAGradientLayer()

    // MARK: - Adaptive Theme Colors
    // These colors automatically switch based on the current trait collection (Dark vs Light mode)

    // Start Color (Top-Left)
    private let adaptiveStartColor = UIColor { traitCollection in
        switch traitCollection.userInterfaceStyle {
        case .dark:
            // Deep charcoal/near-black (Your provided dark mode color)
            return UIColor(red: 30/255, green: 32/255, blue: 38/255, alpha: 1.0)
        default:
            // Bright Brand Blue (Original bright theme color)
            return UIColor(red: 73/255, green: 172/255, blue: 253/255, alpha: 1.0)
        }
    }

    // Middle Color
    private let adaptiveMidColor = UIColor { traitCollection in
        switch traitCollection.userInterfaceStyle {
        case .dark:
            // Deep rich blue (Your provided dark mode color)
            return UIColor(red: 25/255, green: 75/255, blue: 145/255, alpha: 1.0)
        default:
            // Pale mint/white (Original bright theme color)
            return UIColor(red: 215/255, green: 252/255, blue: 237/255, alpha: 1.0)
        }
    }

    // End Color (Bottom-Right)
    private let adaptiveEndColor = UIColor { traitCollection in
        switch traitCollection.userInterfaceStyle {
        case .dark:
            // Deep forest green/teal (Your provided dark mode color)
            return UIColor(red: 35/255, green: 100/255, blue: 85/255, alpha: 1.0)
        default:
            // Brand Green (Original bright theme color)
            return UIColor(red: 135/255, green: 227/255, blue: 177/255, alpha: 1.0)
        }
    }

    // NOTE: IBInspectable colors are ignored in favor of the adaptive colors above.
    @IBInspectable var startColor: UIColor = .clear { didSet { updateGradient() } }
    @IBInspectable var endColor: UIColor = .clear { didSet { updateGradient() } }

    // Direction defaulted to Top-Left to Bottom-Right diagonal
    @IBInspectable var startPointX: CGFloat = 0.0 { didSet { updateGradient() } }
    @IBInspectable var startPointY: CGFloat = 0.0 { didSet { updateGradient() } } // Top
    @IBInspectable var endPointX: CGFloat = 1.0 { didSet { updateGradient() } }
    @IBInspectable var endPointY: CGFloat = 1.0 { didSet { updateGradient() } } // Bottom

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupGradient()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupGradient()
    }

    // MARK: - Lifecycle & Theme Changes

    override func layoutSubviews() {
        super.layoutSubviews()
        gradientLayer.frame = bounds
        gradientLayer.cornerRadius = layer.cornerRadius
        if #available(iOS 13.0, *) {
            gradientLayer.cornerCurve = layer.cornerCurve
        }
    }

    /**
     Crucial for Layers: By default, CALayers (like CAGradientLayer) do NOT automatically
     update their colors when the system switches between dark/light mode.
     We must detect the trait collection change and manually force the gradient update.
     */
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)

        // Check if the system's color appearance has changed
        if traitCollection.hasDifferentColorAppearance(comparedTo: previousTraitCollection) {
            updateGradient()
        }
    }

    // MARK: - Setup

    private func setupGradient() {
        self.layer.insertSublayer(gradientLayer, at: 0)
        updateGradient()
    }

    private func updateGradient() {
        // When traitCollectionDidChange calls this, .cgColor automatically
        // resolves to the correct color for the current mode.
        gradientLayer.colors = [
            adaptiveStartColor.cgColor,
            adaptiveMidColor.cgColor,
            adaptiveEndColor.cgColor
        ]

        // Define locations.
        // Using 0.55 as a balanced midpoint for both light and dark modes.
        gradientLayer.locations = [0.0, 0.55, 1.0]

        gradientLayer.startPoint = CGPoint(x: startPointX, y: startPointY)
        gradientLayer.endPoint = CGPoint(x: endPointX, y: endPointY)
    }
}
