
import Foundation
import UIKit

extension UIColor {
    
    convenience init(hex: String, alpha: CGFloat = 1.0) {
        var hexSanitized = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        hexSanitized = hexSanitized.replacingOccurrences(of: "#", with: "")
        
        var rgb: UInt64 = 0

        let startIndex = hexSanitized.startIndex
        let endIndex = hexSanitized.index(startIndex, offsetBy: 6, limitedBy: hexSanitized.endIndex) ?? hexSanitized.endIndex
        hexSanitized = String(hexSanitized[startIndex..<endIndex])
        
        Scanner(string: hexSanitized).scanHexInt64(&rgb)
        
        let red = CGFloat((rgb & 0xFF0000) >> 16) / 255.0
        let green = CGFloat((rgb & 0x00FF00) >> 8) / 255.0
        let blue = CGFloat(rgb & 0x0000FF) / 255.0

        self.init(red: red, green: green, blue: blue, alpha: alpha)
    }

    static let flashcardColor = UIColor(hex: "91C1EF")

    static let quizColor = UIColor(hex: "88D769")

    static let cheatsheetColor = UIColor(hex: "8A38F5", alpha: 0.50)

    static let noteColor = UIColor(hex: "FFC445", alpha: 0.75)
    static let cardBackgroundColor = UIColor(hex: "BBB3B3", alpha: 0.17)
}
