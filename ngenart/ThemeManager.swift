import SwiftUI

class ThemeManager: ObservableObject {
    @Published var currentTheme: ColorScheme = .light
    
    var backgroundColor: Color {
        currentTheme == .light ? Color(hex: 0xfffef7) : Color(hex: 0x1a1a1a)
    }
    
    var textColor: Color {
        currentTheme == .light ? Color(hex: 0x0a0a0a) : Color(hex: 0xf5f5f5)
    }
    
    var secondaryBackgroundColor: Color {
        currentTheme == .light ? Color(hex: 0xf6f6f6) : Color(hex: 0x2a2a2a)
    }
    
    // Add more color properties as needed
    
    func toggleTheme() {
        currentTheme = currentTheme == .light ? .dark : .light
    }
}
