import SwiftUI
import HealthKit

struct OnboardingView: View {

    @Binding var isOnboarding: Bool
    @StateObject private var healthKitManager = HealthKitManager()
    @State private var isLoading: Bool = false
    @State private var allTimeSteps: Double? = nil
    @State private var currentPage: Int = 0
    @State private var userName: String = ""
    @State private var useImperialUnits: Bool = true
    @State private var themeManager = ThemeManager()
    @State private var shouldMoveToNextPage: Bool = false
    
    
    
    private var isValidName: Bool {
        return userName.trimmingCharacters(in: .whitespacesAndNewlines).count >= 2
    }
    
    var body: some View {
        VStack() {
            let totalPages = 6
            ProgressView(value: Double(currentPage), total: Double(totalPages))

            ZStack {
                welcomeView.opacity(currentPage == 0 ? 1 : 0)
                nameInputView.opacity(currentPage == 1 ? 1 : 0)
                welcomeMessage.opacity(currentPage == 2 ? 1 : 0)
                dataMessage.opacity(currentPage == 3 ? 1 : 0)
                stepsMessage.opacity(currentPage == 4 ? 1 : 0)
                stepsDisplayView.opacity(currentPage == 5 ? 1 : 0)
                finalView.opacity(currentPage == 6 ? 1 : 0)
            }
            .animation(.easeInOut, value: currentPage)

            
            HStack {
                if currentPage > 0 {
                    Button("Back") {
                        withAnimation {
                            currentPage -= 1
                        }
                    }
                }
                
                Spacer()
                
                Button(currentPage == totalPages ? "Get Started" : "Next") {
                    withAnimation {
                        if currentPage == totalPages {
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
        .frame(maxWidth: .infinity, maxHeight: .infinity)
.edgesIgnoringSafeArea(.all)
        .preferredColorScheme(themeManager.currentTheme)
        .applyTheme()
    }
    
    private var welcomeView: some View {
        VStack(spacing: 20) {
            Text("Welcome to Data OS")
                .font(.custom("BodoniModa18pt-Regular", size: 28))
                .multilineTextAlignment(.center)
            
            Text("the app that turns your data into works of art.")
                .font(.custom("BodoniModa18pt-Regular", size: 24))
                .multilineTextAlignment(.center)
        }
        .padding(16)
    }

    private var nameInputView: some View {
    VStack(spacing: 20) {
        Text("What's your name?")
            .font(.custom("BodoniModa18pt-Regular", size: 24))
        
        TextField("Enter your name", text: $userName)
            .textFieldStyle(RoundedBorderTextFieldStyle())
            .padding(.horizontal)
            .font(.custom("BodoniModa18pt-Regular", size: 24))
        
        Text("Don't worry, you can always change this later in settings.")
            .font(.custom("BodoniModa18pt-Regular", size: 14))
            .foregroundColor(Color(hex: 0x0a0a0a))
            .multilineTextAlignment(.center)
            .padding(.horizontal)
        }
        .padding(16)
    }

    private var welcomeMessage: some View {
        VStack(spacing: 20) {
            Text("Nice to meet you, ")
                .font(.custom("BodoniModa18pt-Regular", size: 24)) +
            Text(userName)
                .font(.custom("BodoniModa18pt-Regular", size: 24))
                .foregroundColor(.red) +
            Text("!\nWelcome to Data OS, the app that turns your data into works of art.")
                .font(.custom("BodoniModa18pt-Regular", size: 24))
        }
        .multilineTextAlignment(.center)
        .padding(16)
    }

    private var dataMessage: some View {
        VStack(spacing: 20) {
            Text("In-order to create art, you’ll be asked to share different data with us. Your data is private and secure, and you can always change your settings later.")
                .font(.custom("BodoniModa18pt-Regular", size: 24))
                .multilineTextAlignment(.center)
        }
        .padding(8)
    }

    private var stepsMessage: some View {
        VStack(spacing: 20) {
            Text("Let's start by counting your steps!")
                .font(.custom("BodoniModa18pt-Regular", size: 24))
                .multilineTextAlignment(.center)
            
            Button(action: {
                healthKitManager.requestAuthorization { success, error in
                    if success {
                        print("Step count authorization successful")
                    } else {
                        print("Step count authorization failed")
                        if let error = error {
                            print(error)
                        }
                    }
                    shouldMoveToNextPage = true
                }
            }) {
                Text("Allow Step Counting")
                    .font(.headline)
                    .foregroundColor(.white)
                    .padding()
                    .background(Color.blue)
                    .cornerRadius(10)
            }
        }
        .padding(8)
        .onChange(of: shouldMoveToNextPage) { newValue in
            if newValue {
                withAnimation {
                    currentPage += 1
                }
                shouldMoveToNextPage = false
            }
        }
        .onAppear {
            healthKitManager.checkAuthorizationStatus()
        }
    }
    
    private var stepsDisplayView: some View {
        VStack(spacing: 20) {
            Text("Debug: isAuthorized = \(healthKitManager.isAuthorized)")
                .font(.caption)
                .foregroundColor(.gray)
            
            if healthKitManager.isAuthorized {
                if isLoading {
                    ProgressView("Fetching step count...")
                        .scaleEffect(1.5)
                } else if let steps = allTimeSteps {
                    Text("Wow! You've taken")
                        .font(.custom("BodoniModa18pt-Regular", size: 24))
                    Text("\(Int(steps))")
                        .font(.custom("BodoniModa18pt-Regular", size: 36))
                        .foregroundColor(.blue)
                    Text("steps all-time!")
                        .font(.custom("BodoniModa18pt-Regular", size: 24))
                } else {
                    Text("We couldn't fetch your step count. Please try again later.")
                        .font(.custom("BodoniModa18pt-Regular", size: 18))
                        .multilineTextAlignment(.center)
                    
                    Button("Retry Fetch") {
                        fetchAllTimeSteps()
                    }
                    .font(.headline)
                    .foregroundColor(.white)
                    .padding()
                    .background(Color.blue)
                    .cornerRadius(10)
                }
            } else {
                Text("No worries! You can always enable step counting later in the app settings.")
                    .font(.custom("BodoniModa18pt-Regular", size: 18))
                    .multilineTextAlignment(.center)
                    .padding()
                
                Button("Check Authorization Again") {
                    healthKitManager.checkAuthorizationStatus()
                }
                .font(.headline)
                .foregroundColor(.white)
                .padding()
                .background(Color.blue)
                .cornerRadius(10)
            }
        }
        .padding(8)
        .onAppear {
            print("Debug: stepsDisplayView appeared")
            healthKitManager.checkAuthorizationStatus()
            if healthKitManager.isAuthorized {
                fetchAllTimeSteps()
            }
        }
    }

    private func fetchAllTimeSteps() {
        isLoading = true
        healthKitManager.fetchTotalSteps { steps, error in
            isLoading = false
            if let steps = steps {
                allTimeSteps = steps
            } else if let error = error {
                print("Failed to fetch steps: \(error.localizedDescription)")
            }
        }
    }

    private var unitsAndThemeView: some View {
        VStack(spacing: 20) {
            Text("Nice to meet you, \(userName)! Welcome to Data OS.")
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