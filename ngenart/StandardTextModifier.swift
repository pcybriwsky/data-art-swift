import SwiftUI

struct StandardTextModifier: ViewModifier {
    let fontSize: CGFloat
    let textColor: Color
    let backgroundColor: Color?
    
    func body(content: Content) -> some View {
        content
            .font(.custom("Marker Felt", size: fontSize))
            .foregroundColor(textColor)
            .padding()
            .background(backgroundColor ?? Color.clear)
            .cornerRadius(8)
    }
}

extension View {
    func standardTextStyle(fontSize: CGFloat = 24, textColor: Color = .black, backgroundColor: Color? = nil) -> some View {
        self.modifier(StandardTextModifier(fontSize: fontSize, textColor: textColor, backgroundColor: backgroundColor))
    }
}
