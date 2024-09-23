import SwiftUI
import CoreGraphics

public class StepArtRenderer: ObservableObject {
    private static let textColor: UIColor = {
        if #available(iOS 13.0, *) {
            return .label
        } else {
            return .black
        }
    }()

    public static func renderOdometer(distance: Double, unit: String, size: CGSize, year: Int) -> UIImage {
        let renderer = UIGraphicsImageRenderer(size: size)
        
        return renderer.image { context in
            // Set up colors
            let backgroundColor = UIColor.systemBackground
            let accentColor = UIColor.systemPink
            
            // Fill background
            backgroundColor.setFill()
            context.fill(CGRect(origin: .zero, size: size))
            
            // Calculate digit properties
            let digitCount = 8
            
            let digitWidth = size.width / CGFloat(digitCount)
            let digitHeight = digitWidth
            let yOffset = (size.height - digitHeight) / 2
            
            // Format miles to 8 digits with 2 decimal places
            let formattedMiles = String(format: "%08.2f", distance)
            let wholeDigits = Array(formattedMiles)
            
            // Draw digits
            for (index, digit) in wholeDigits.enumerated() {
                let rect = CGRect(x: CGFloat(index) * digitWidth, y: yOffset, width: digitWidth, height: digitHeight)
                let path = UIBezierPath(roundedRect: rect, cornerRadius: 8)
                
                if index >= digitCount - 2 {
                    accentColor.setFill()
                } else {
                    UIColor.black.setFill()
                }
                path.fill()
                
                let attributes: [NSAttributedString.Key: Any] = [
                    .font: UIFont.monospacedDigitSystemFont(ofSize: digitHeight * 0.7, weight: .bold),
                    .foregroundColor: UIColor.white
                ]
                let digitString = String(digit)
                let textSize = digitString.size(withAttributes: attributes)
                let textRect = CGRect(
                    x: rect.midX - textSize.width / 2,
                    y: rect.midY - textSize.height / 2,
                    width: textSize.width,
                    height: textSize.height
                )
                digitString.draw(in: textRect, withAttributes: attributes)
            }
            
            // Define labelAttributes
            let labelAttributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 14),
                .foregroundColor: textColor
            ]

            // Update the label to use the dynamic year
            let label = "\(unit == "miles" ? "Miles" : "Kilometers") since the start of \(year)"
            let labelSize = label.size(withAttributes: labelAttributes)
            let labelRect = CGRect(
                x: size.width / 2 - labelSize.width / 2,
                y: size.height - labelSize.height - 10,
                width: labelSize.width,
                height: labelSize.height
            )
            label.draw(in: labelRect, withAttributes: labelAttributes)
        }
    }
}
