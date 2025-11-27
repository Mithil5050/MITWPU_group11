//
//  Color.swift
//  Group_11_Revisio
//
//  Created by SDC-USER on 27/11/25.
//

import Foundation
import UIKit

extension UIColor {
    // Custom initializer to convert a HEX string to a UIColor with optional alpha
    convenience init(hex: String, alpha: CGFloat = 1.0) {
        var hexSanitized = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        hexSanitized = hexSanitized.replacingOccurrences(of: "#", with: "")
        
        var rgb: UInt64 = 0
        
        // Ensure we only read the first 6 characters (RRGGBB)
        let startIndex = hexSanitized.startIndex
        let endIndex = hexSanitized.index(startIndex, offsetBy: 6, limitedBy: hexSanitized.endIndex) ?? hexSanitized.endIndex
        hexSanitized = String(hexSanitized[startIndex..<endIndex])
        
        Scanner(string: hexSanitized).scanHexInt64(&rgb)
        
        let red = CGFloat((rgb & 0xFF0000) >> 16) / 255.0
        let green = CGFloat((rgb & 0x00FF00) >> 8) / 255.0
        let blue = CGFloat(rgb & 0x0000FF) / 255.0
        
        // Use the provided alpha value for opacity
        self.init(red: red, green: green, blue: blue, alpha: alpha)
    }
    
    // --- Define your custom colors using your exact HEX and opacity ---
    
    // Flashcards: #91C1EF (100% opacity)
    static let flashcardColor = UIColor(hex: "91C1EF")
    
    // Quiz: #88D769 (100% opacity)
    static let quizColor = UIColor(hex: "88D769")
    
    // Cheatsheet: #8A38F5 (50% opacity = 0.5 alpha)
    static let cheatsheetColor = UIColor(hex: "8A38F5", alpha: 0.50)
    
    // Notes: #FFC445 (75% opacity = 0.75 alpha)
    static let noteColor = UIColor(hex: "FFC445", alpha: 0.75)
    static let cardBackgroundColor = UIColor(hex: "BBB3B3", alpha: 0.17)
}
