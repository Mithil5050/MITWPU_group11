//
//  CircularProgressView.swift
//  Group_11_Revisio
//
//  Created by Your Name on 11/12/25.
//

import UIKit

// Implements the custom circular progress bar using Core Graphics.
class CircularProgressView: UIView {
    
    private let trackLayer = CAShapeLayer()
    private let progressLayer = CAShapeLayer()
    
    var lineWidth: CGFloat = 8.0 {
        didSet {
            trackLayer.lineWidth = lineWidth
            progressLayer.lineWidth = lineWidth
            setNeedsLayout()
        }
    }
    
    var trackColor: UIColor = UIColor.systemGray4 {
        didSet {
            trackLayer.strokeColor = trackColor.cgColor
        }
    }
    
    var progressColor: UIColor = UIColor.systemGreen {
        didSet {
            progressLayer.strokeColor = progressColor.cgColor
        }
    }
    
    var progress: Float = 0.0 {
        didSet {
            // Animates the progress change
            let basicAnimation = CABasicAnimation(keyPath: "strokeEnd")
            basicAnimation.toValue = progress
            basicAnimation.duration = 0.5
            basicAnimation.fillMode = .forwards
            basicAnimation.isRemovedOnCompletion = false
            progressLayer.add(basicAnimation, forKey: "progressAnim")
        }
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupLayers()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupLayers()
    }
    
    private func setupLayers() {
        layer.addSublayer(trackLayer)
        layer.addSublayer(progressLayer)
        
        // Initial setup for line caps
        trackLayer.lineCap = .round
        progressLayer.lineCap = .round
        
        // Initial color setup
        trackLayer.strokeColor = trackColor.cgColor
        progressLayer.strokeColor = progressColor.cgColor
        
        // Clear fill color
        trackLayer.fillColor = UIColor.clear.cgColor
        progressLayer.fillColor = UIColor.clear.cgColor
        
        // Start progress at 0
        progressLayer.strokeEnd = 0.0
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        let center = CGPoint(x: bounds.midX, y: bounds.midY)
        // Ensure the radius is within the bounds, considering the line width
        let radius = (min(bounds.width, bounds.height) - lineWidth) / 2
        
        // Start angle at 12 o'clock (-90 degrees)
        let startAngle: CGFloat = -CGFloat.pi / 2
        let endAngle: CGFloat = 2 * CGFloat.pi + startAngle
        
        let circularPath = UIBezierPath(
            arcCenter: center,
            radius: radius,
            startAngle: startAngle,
            endAngle: endAngle,
            clockwise: true
        )
        
        // Set the path for both layers
        trackLayer.path = circularPath.cgPath
        progressLayer.path = circularPath.cgPath
        
        // Position layers within the bounds
        trackLayer.frame = bounds
        progressLayer.frame = bounds
    }
}
