import SwiftUI

struct OnboardingView: View {
    @Binding var isOnboarding: Bool
    @State private var currentPage = 0
    @State private var userName = ""
    @State private var useImperialUnits = true
    @EnvironmentObject var themeManager: ThemeManager

    
    private var isValidName: Bool {
        return userName.trimmingCharacters(in: .whitespacesAndNewlines).count >= 2
    }
    
    var body: some View {
        VStack {
            ProgressView(value: Double(currentPage), total: 3)
                .padding()
            
            TabView(selection: $currentPage) {
                welcomeView.tag(0)
                nameInputView.tag(1)
                unitsAndThemeView.tag(2)
                finalView.tag(3)
            }
            .tabViewStyle(PageTabViewStyle())
            .indexViewStyle(PageIndexViewStyle(backgroundDisplayMode: .always))
            .animation(.easeInOut, value: currentPage)
            .transition(.opacity.combined(with: .slide))
            
            HStack {
                if currentPage > 0 {
                    Button("Back") {
                        withAnimation {
                            currentPage -= 1
                        }
                    }
                }
                
                Spacer()
                
                Button(currentPage == 3 ? "Get Started" : "Next") {
                    withAnimation {
                        if currentPage == 3 {
                            completeOnboarding()
                        } else if currentPage == 1 && isValidName {
                            currentPage += 1
                        } else if currentPage != 1 {
                            currentPage += 1
                        }
                    }
                }
                .disabled(currentPage == 1 && !isValidName)
            }
            .padding()
        }
        .preferredColorScheme(themeManager.currentTheme)
        .applyTheme()
    }
    
    private var welcomeView: some View {
        VStack(spacing: 20) {
            Text("Welcome to Data OS")
                .font(.custom("BodoniModa18pt-Regular", size: 28))
                .multilineTextAlignment(.center)
            
            Text("Let's get you set up!")
                .font(.system(size: 18))
        }
        .padding()
    }
    
    private var nameInputView: some View {
        VStack(spacing: 20) {
            Text("What's your name?")
                .font(.custom("BodoniModa18pt-Regular", size: 24))
            
            TextField("Enter your name", text: $userName)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding(.horizontal)
        }
        .padding()
    }
    
    private var unitsAndThemeView: some View {
        VStack(spacing: 20) {
            Text("Hi \(userName), let's personalize your experience")
                .font(.custom("BodoniModa18pt-Regular", size: 24))
            
            Picker("Units", selection: $useImperialUnits) {
                Text("Imperial").tag(true)
                Text("Metric").tag(false)
            }
            .pickerStyle(SegmentedPickerStyle())
            
            Picker("Theme", selection: $themeManager.currentTheme) {
                Text("Light").tag(ColorScheme.light)
                Text("Dark").tag(ColorScheme.dark)
            }
            .pickerStyle(SegmentedPickerStyle())
        }
        .padding()
    }
    
    private var finalView: some View {
        VStack(spacing: 20) {
            Text("You're all set, \(userName)!")
                .font(.custom("BodoniModa18pt-Regular", size: 24))
            
            Text("Tap 'Get Started' to begin your journey.")
                .font(.system(size: 18))
        }
        .padding()
    }
    
    private func completeOnboarding() {
        UserDefaults.standard.set(userName, forKey: "userName")
        UserManager.shared.useImperialUnits = useImperialUnits
        isOnboarding = false
    }
}