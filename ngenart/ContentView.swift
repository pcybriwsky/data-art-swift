import SwiftUI
import HealthKit

struct ContentView: View {
    @State private var isOnboarding = true
    @State private var userName = ""
    @State private var screenTimeData = ""
    // Create an instance of HealthKitManager
    private let healthKitManager = HealthKitManager()
    @StateObject private var screenTimeManager = ScreenTimeManager.shared
    
    var body: some View {
        Group {
            if isOnboarding {
                OnboardingView(isOnboarding: $isOnboarding)
            } else {
                HomeView()
            }
        }
        .environmentObject(healthKitManager)  // Pass HealthKitManager as an environment object
        .environmentObject(screenTimeManager)  // Pass ScreenTimeManager as an environment object
        .onAppear {
            if let name = UserDefaults.standard.string(forKey: "userName") {
                userName = name
                isOnboarding = false
            }
            screenTimeManager.requestAuthorization { success, error in
                if success {
                    print("Screen Time authorization granted")
                    screenTimeManager.fetchBasicScreenTimeData { data in
                screenTimeData = data
                        print(screenTimeData)
                    }
                } else {
                    print("Failed to get Screen Time authorization: \(error?.localizedDescription ?? "Unknown error")")
                }
            }
            
            
                    
            
        }
    }
    
    private func checkAndRequestHealthKitPermissions() {
        print("Initial HealthKit authorization check:")
        healthKitManager.checkAuthorizationStatus()
        
        if !healthKitManager.isAuthorized {
            print("HealthKit not authorized, requesting authorization...")
            healthKitManager.requestAuthorization { success, error in
                if success {
                    print("HealthKit permissions request successful")
                    // Check authorization status again after successful request
                    DispatchQueue.main.async {
                        print("Checking HealthKit authorization status after successful request:")
                        self.healthKitManager.checkAuthorizationStatus()
                        // Attempt to fetch data regardless of reported status
                        self.healthKitManager.testFetchSleepData()
                    }
                } else {
                    print("Failed to get HealthKit permissions: \(error?.localizedDescription ?? "Unknown error")")
                }
            }
        } else {
            print("HealthKit already authorized, attempting to fetch data:")
            healthKitManager.testFetchSleepData()
        }
    }
}
