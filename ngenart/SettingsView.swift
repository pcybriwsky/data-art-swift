import SwiftUI
import HealthKit

struct SettingsView: View {
    @State private var userName: String = UserDefaults.standard.string(forKey: "userName") ?? ""
    @State private var useImperialUnits: Bool = UserManager.shared.useImperialUnits
    @State private var totalStepCount: Double?
    @State private var isLoading: Bool = false
    @State private var errorMessage: String?
    @State private var healthDataAuthorized: Bool = false
    @AppStorage("isOnboarding") private var isOnboarding: Bool = false

// Add this function to check HealthKit authorization status
// private func checkHealthDataAuthorization() {
//     guard HKHealthStore.isHealthDataAvailable() else {
//         DispatchQueue.main.async {
//             self.healthDataAuthorized = false
//             print("HealthKit is not available on this device")
//         }
//         return
//     }

//     let healthStore = HKHealthStore()
//     let stepType = HKQuantityType.quantityType(forIdentifier: .stepCount)!
    
//     let authStatus = healthStore.authorizationStatus(for: stepType)
//     print("Authorization status: \(authStatus)")
    
//     DispatchQueue.main.async {
//         switch authStatus {
//         case .sharingAuthorized:
//             self.healthDataAuthorized = true
//             print("Health data is authorized")
//         case .sharingDenied:
//             self.healthDataAuthorized = false
//             print("Health data sharing is denied")
//         case .notDetermined:
//             self.healthDataAuthorized = false
//             print("Health data authorization is not determined")
//         @unknown default:
//             self.healthDataAuthorized = false
//             print("Unknown health data authorization status: \(authStatus.rawValue)")
//         }
//         print("Health data authorized: \(self.healthDataAuthorized)")
//     }
// }

// private func checkActualAuthorizationStatus(for stepType: HKQuantityType, healthStore: HKHealthStore) {
//     DispatchQueue.main.async {
//         self.healthDataAuthorized = healthStore.authorizationStatus(for: stepType) == .sharingAuthorized
//         print("Health data authorized: \(self.healthDataAuthorized)")
//     }
// }

// private func requestHealthDataAuthorization() {
//     let healthStore = HKHealthStore()
//     let stepType = HKQuantityType.quantityType(forIdentifier: .stepCount)!
    
//     healthStore.requestAuthorization(toShare: [], read: [stepType]) { (success, error) in
//         DispatchQueue.main.async {
//             if success {
//                 self.healthDataAuthorized = true
//                 print("Health data authorization granted")
//             } else {
//                 self.healthDataAuthorized = false
//                 if let error = error {
//                     print("Health data authorization failed: \(error.localizedDescription)")
//                 } else {
//                     print("Health data authorization denied")
//                 }
//             }
//             self.checkHealthDataAuthorization() // Check again after requesting
//         }
//     }
// }

    var body: some View {
        VStack {
            Text("Settings")
                .font(.custom("BodoniModa18pt-Italic", size: 24))
                .padding()
            
            TextField("Enter your name", text: $userName)
                .padding()
                .background(Color(hex: 0xfffef7))
                .font(.custom("BodoniModa18pt-Italic", size: 18))
                .cornerRadius(8)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color(hex: 0x0a0a0a), lineWidth: 1)
                )
                .padding()
                .onChange(of: userName) { newValue in
                    UserDefaults.standard.set(newValue, forKey: "userName")
                }
            
            Toggle(isOn: $useImperialUnits) {
                Text("Use Imperial Units")
            }
            .padding()
            .onChange(of: useImperialUnits) { value in
                UserManager.shared.useImperialUnits = value
            }
            
            HStack {
    Text("Health Data")
        .font(.custom("BodoniModa18pt-Italic", size: 18))
    
    if healthDataAuthorized {
        Image(systemName: "checkmark.circle.fill")
            .foregroundColor(.green)
    } else {
        Image(systemName: "exclamationmark.circle.fill")
            .foregroundColor(.red)
    }
}
.padding(.top, 8)

            HStack(spacing: 8) {
                Text("Your Total Steps:")
                if isLoading {
                    ProgressView()
                } else if let stepCount = totalStepCount {
                    Text("\(Int(stepCount))")
                        .font(.custom("BodoniModa18pt-Italic", size: 24))
                } else {
                    Text("Health Data not available")
                        .font(.custom("BodoniModa18pt-Italic", size: 18))
                        .foregroundColor(.gray)
                }
            }
            .padding(.top, 8)
            
            Spacer()
        }
        .padding()
        .background(Color(hex: 0xfffef7))
        // .onAppear(perform: checkHealthDataAuthorization)
        // .onAppear(perform: requestHealthDataAuthorization)
        .onAppear(perform: fetchTotalSteps)
        
        Button(action: {
            UserDefaults.standard.removeObject(forKey: "userName")
            isOnboarding = true
        }) {
            Text("Reset Onboarding")
                .padding()
                .background(Color.red)
                .foregroundColor(.white)
                .cornerRadius(8)
        }
        .padding()
    }
    
    private func fetchTotalSteps() {
        isLoading = true
        HealthKitManager().fetchTotalSteps { steps, error in
            isLoading = false
            if let steps = steps {
                totalStepCount = steps
            } else {
                totalStepCount = nil
            }
        }
    }
}

