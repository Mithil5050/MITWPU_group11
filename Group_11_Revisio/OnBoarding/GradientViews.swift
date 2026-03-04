//
//  GradientView.swift
//  App_Onboarding
//
//  Created by Chirag Poojari on 03/02/26.
//

import UIKit

@IBDesignable

class GradientViews: UIView {

    private let gradientLayer = CAGradientLayer()

    private let adaptiveStartColor = UIColor { trait in
        trait.userInterfaceStyle == .dark
        ? UIColor(red: 30/255, green: 32/255, blue: 38/255, alpha: 1)
        : UIColor(red: 73/255, green: 172/255, blue: 253/255, alpha: 1)
    }

    private let adaptiveMidColor = UIColor { trait in
        trait.userInterfaceStyle == .dark
        ? UIColor(red: 25/255, green: 75/255, blue: 145/255, alpha: 1)
        : UIColor(red: 215/255, green: 252/255, blue: 237/255, alpha: 1)
    }

    private let adaptiveEndColor = UIColor { trait in
        trait.userInterfaceStyle == .dark
        ? UIColor(red: 35/255, green: 100/255, blue: 85/255, alpha: 1)
        : UIColor(red: 135/255, green: 227/255, blue: 177/255, alpha: 1)
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setup()
    }

    private func setup() {
        layer.insertSublayer(gradientLayer, at: 0)
        updateGradient()
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        gradientLayer.frame = bounds
    }

    private func updateGradient() {
        gradientLayer.colors = [
            adaptiveStartColor.cgColor,
            adaptiveMidColor.cgColor,
            adaptiveEndColor.cgColor
        ]
        gradientLayer.locations = [0.0, 0.55, 1.0]
        gradientLayer.startPoint = CGPoint(x: 0, y: 0)
        gradientLayer.endPoint = CGPoint(x: 1, y: 1)
    }
}
