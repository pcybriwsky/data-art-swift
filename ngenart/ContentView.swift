import SwiftUI
import HealthKit

struct ContentView: View {
    @State private var isOnboarding = true
    @State private var userName = ""
    
    
    var body: some View {
        Group {
            if isOnboarding {
                OnboardingView(isOnboarding: $isOnboarding)
            } else {
                HomeView()
            }
        }
        .onAppear {
            if let name = UserDefaults.standard.string(forKey: "userName") {
                userName = name
                isOnboarding = false
            }
        }
    }
}
