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
    // Basically, this is the art piece. So I can edit this but the data input and structure is determined by GenArtView
    public static func renderOdometer(distance: Double, unit: String, size: CGSize, year: Int, endYear: Int) -> UIImage {
        let renderer = UIGraphicsImageRenderer(size: size)
        
        return renderer.image { context in
            // Set up colors
            let backgroundColor = UIColor(hex: 0x0a0a0a)
            let accentColor = UIColor(hex: 0xFF5733)
            
            // Fill background
            backgroundColor.setFill()
            context.fill(CGRect(origin: .zero, size: size))
            
            // Calculate digit properties
            
            let numberFormatter = NumberFormatter()
            numberFormatter.numberStyle = .decimal
            numberFormatter.minimumFractionDigits = 1
            numberFormatter.maximumFractionDigits = 1
            numberFormatter.usesGroupingSeparator = false  // This removes the comma

            let formattedMiles = numberFormatter.string(from: NSNumber(value: distance)) ?? "0.0"
            let wholeDigits = Array(formattedMiles)
            print(wholeDigits)


            let digitCount = wholeDigits.count
            let padding: CGFloat = 8 // Adjust this value for desired spacing between rects
            let totalPadding = padding * CGFloat(digitCount - 1)
            let maxDigitWidth: CGFloat = 80 // Maximum width for each digit rect, adjust as needed
            let totalWidth = min(CGFloat(digitCount) * maxDigitWidth + totalPadding, size.width * 0.9)
            let digitWidth = (totalWidth - totalPadding) / CGFloat(digitCount)
            let digitHeight = min(size.height * 0.6, digitWidth * 1.5) // Adjust the ratio as needed
            let yOffset = (size.height - digitHeight) / 2
            let xOffset = (size.width - totalWidth) / 2 // This centers the entire set of rects

            // In your drawing loop:
            for (index, digit) in wholeDigits.enumerated() {
                let xPosition = xOffset + CGFloat(index) * (digitWidth + padding)
                let rect = CGRect(x: xPosition, y: yOffset, width: digitWidth, height: digitHeight)
                let path = UIBezierPath(roundedRect: rect, cornerRadius: 8)

            
                UIColor(hex: 0xfffef7).setFill()    
                path.fill()
                
                var attributes: [NSAttributedString.Key: Any] = [
                    .font: UIFont.monospacedDigitSystemFont(ofSize: digitHeight * 0.7, weight: .bold),
                    .foregroundColor: textColor
                ]
                if index >= digitCount - 1 {
                    attributes = [
                    .font: UIFont.monospacedDigitSystemFont(ofSize: digitHeight * 0.7, weight: .bold),
                    .foregroundColor: accentColor
                ]
                }


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
                .foregroundColor: UIColor(hex: 0xfffef7)
            ]
            

            // Update the label to use the dynamic year
            var label = "\(unit == "miles" ? "Miles" : "Kilometers") from the start of \(year) to end of \(endYear)"
            if year >= endYear {
                label = "\(unit == "miles" ? "Miles" : "Kilometers") in \(year)"
            }
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

    public static func animateOdometer(distance: Double, unit: String, size: CGSize, year: Int, endYear: Int) -> some View {
        AnimatedOdometerView(value: distance, 
                             size: size, 
                             accentColor: UIColor(hex: 0xFF5733), 
                             textColor: textColor, 
                             digitBackgroundColor: UIColor(hex: 0xfffef7))
    }
}

public struct AnimatedOdometerView: UIViewRepresentable {
    @Binding public var value: Double
    public let size: CGSize
    public let accentColor: UIColor
    public let textColor: UIColor
    public let digitBackgroundColor: UIColor  // Renamed from backgroundColor

    public init(value: Double, size: CGSize, accentColor: UIColor, textColor: UIColor, digitBackgroundColor: UIColor) {
        self._value = Binding.constant(value)
        self.size = size
        self.accentColor = accentColor
        self.textColor = textColor
        self.digitBackgroundColor = digitBackgroundColor
    }

    public func makeUIView(context: Context) -> AnimatedOdometerUIView {
        let view = AnimatedOdometerUIView(frame: CGRect(origin: .zero, size: size), 
                                          accentColor: accentColor, 
                                          textColor: textColor, 
                                          digitBackgroundColor: digitBackgroundColor)
        view.setValue(value, animated: false)
        return view
    }

    public func updateUIView(_ uiView: AnimatedOdometerUIView, context: Context) {
        uiView.setValue(value, animated: true)
    }
}

public class AnimatedOdometerUIView: UIView {
    private var digitLayers: [CATextLayer] = []
    private var currentValue: Double = 0
    private var targetValue: Double = 0
    public let accentColor: UIColor
    public let textColor: UIColor
    public let digitBackgroundColor: UIColor  // Renamed from backgroundColor

    public init(frame: CGRect, accentColor: UIColor, textColor: UIColor, digitBackgroundColor: UIColor) {
        self.accentColor = accentColor
        self.textColor = textColor
        self.digitBackgroundColor = digitBackgroundColor
        super.init(frame: frame)
        setupLayers()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupLayers() {
        let digitCount = 8 // Adjust as needed
        let digitWidth = bounds.width / CGFloat(digitCount)
        let digitHeight = bounds.height

        for i in 0..<digitCount {
            let layer = CATextLayer()
            layer.frame = CGRect(x: CGFloat(i) * digitWidth, y: 0, width: digitWidth, height: digitHeight)
            layer.alignmentMode = .center
            layer.fontSize = digitHeight * 0.7
            layer.font = UIFont.monospacedDigitSystemFont(ofSize: digitHeight * 0.7, weight: .bold)
            layer.foregroundColor = (i == digitCount - 1) ? accentColor.cgColor : textColor.cgColor
            layer.backgroundColor = digitBackgroundColor.cgColor
            layer.cornerRadius = 8
            layer.masksToBounds = true
            layer.string = "0"
            layer.contentsScale = UIScreen.main.scale
            layer.transform = CATransform3DMakeScale(0.85, 0.85, 1)
            self.layer.addSublayer(layer)
            digitLayers.append(layer)
        }
    }

    func setValue(_ value: Double, animated: Bool) {
        targetValue = value
        if animated {
            animateToValue()
        } else {
            currentValue = value
            updateDisplay()
        }
    }

    private func animateToValue() {
        let animation = CABasicAnimation(keyPath: "string")
        animation.fromValue = currentValue
        animation.toValue = targetValue
        animation.duration = 2.0 // Adjust duration as needed
        animation.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)

        CATransaction.begin()
        CATransaction.setCompletionBlock { [weak self] in
            self?.currentValue = self?.targetValue ?? 0
            self?.updateDisplay()
        }

        for (index, layer) in digitLayers.enumerated().reversed() {
            let digit = Int(targetValue / pow(10, Double(digitLayers.count - index - 1))) % 10
            layer.add(animation, forKey: "numberAnimation")
            layer.string = "\(digit)"
        }

        CATransaction.commit()
    }

    private func updateDisplay() {
        let formatter = NumberFormatter()
        formatter.minimumIntegerDigits = digitLayers.count
        formatter.maximumFractionDigits = 0

        if let formattedString = formatter.string(from: NSNumber(value: currentValue)) {
            for (index, char) in formattedString.enumerated() {
                digitLayers[index].string = String(char)
            }
        }
    }
}
