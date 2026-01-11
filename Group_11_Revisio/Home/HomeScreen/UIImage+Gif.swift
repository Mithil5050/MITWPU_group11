//
//  func.swift
//  Group_11_Revisio
//
//  Created by Mithil on 11/01/26.
//


//
//  UIImage+Gif.swift
//  Group_11_Revisio
//
//  Created by Your Name on 11/12/25.
//

import UIKit
import ImageIO

extension UIImage {
    
    public class func gifImageWithData(_ data: Data) -> UIImage? {
        guard let source = CGImageSourceCreateWithData(data as CFData, nil) else {
            print("image doesn't exist")
            return nil
        }
        
        return UIImage.animatedImageWithSource(source)
    }
    
    public class func gifImageWithName(_ name: String) -> UIImage? {
        guard let bundleURL = Bundle.main.url(forResource: name, withExtension: "gif") else {
            print("SwiftGif: This image named \"\(name)\" does not exist")
            return nil
        }
        
        guard let imageData = try? Data(contentsOf: bundleURL) else {
            print("SwiftGif: Cannot turn image named \"\(name)\" into NSData")
            return nil
        }
        
        return gifImageWithData(imageData)
    }
    
    class func animatedImageWithSource(_ source: CGImageSource) -> UIImage? {
        let count = CGImageSourceGetCount(source)
        var images = [UIImage]()
        var duration = 0.0
        
        for i in 0..<count {
            if let cgImage = CGImageSourceCreateImageAtIndex(source, i, nil) {
                if let properties = CGImageSourceCopyPropertiesAtIndex(source, i, nil) as? [String: Any],
                   let gifInfo = properties[kCGImagePropertyGIFDictionary as String] as? [String: Any] {
                    
                    // Get frame duration
                    var frameDuration = 0.1
                    if let delayTimeUnclamped = gifInfo[kCGImagePropertyGIFUnclampedDelayTime as String] as? Double {
                        frameDuration = delayTimeUnclamped
                    } else {
                        if let delayTime = gifInfo[kCGImagePropertyGIFDelayTime as String] as? Double {
                            frameDuration = delayTime
                        }
                    }
                    
                    // Fix for extremely fast frames
                    if frameDuration < 0.011 {
                        frameDuration = 0.100
                    }
                    
                    duration += frameDuration
                    images.append(UIImage(cgImage: cgImage))
                }
            }
        }
        
        if !images.isEmpty {
            return UIImage.animatedImage(with: images, duration: duration)
        }
        
        return nil
    }
}