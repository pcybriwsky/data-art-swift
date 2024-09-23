import SwiftUI

extension Color {
    init(hex: Int, alpha: Double = 1.0) {
        let red = Double((hex & 0xff0000) >> 16) / 255.0
        let green = Double((hex & 0xff00) >> 8) / 255.0
        let blue = Double((hex & 0xff) >> 0) / 255.0
        self.init(.sRGB, red: red, green: green, blue: blue, opacity: alpha)
    }
}

// MARK: Allows for percentage based layouts
struct SizeCalculator: ViewModifier {
    @Binding var size: CGSize
    func body(content: Content) -> some View {
        content.background(
            GeometryReader { proxy in
                Color.clear
                .onAppear { size = proxy.size }
            }
        )
    }
}

struct ArtPiece: Identifiable {
    let id = UUID()
    let title: String
    let subtitle: String
    let imageURL: String
    let destinationView: AnyView
    let description: String
}
 
extension View {
    func saveSize(in size: Binding<CGSize>) -> some View {
        modifier(SizeCalculator(size: size))
    }
    func applyTheme() -> some View {
        self.modifier(ThemeModifier())
    }
}

struct ThemeModifier: ViewModifier {
    @EnvironmentObject var themeManager: ThemeManager
    
    func body(content: Content) -> some View {
        content
            .background(themeManager.backgroundColor)
            .foregroundColor(themeManager.textColor)
    }
}
