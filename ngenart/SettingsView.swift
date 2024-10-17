import SwiftUI
import HealthKit

struct SettingsView: View {
    @EnvironmentObject var healthKitManager: HealthKitManager
    @State private var userName: String = UserDefaults.standard.string(forKey: "userName") ?? ""
    @State private var useImperialUnits: Bool = UserManager.shared.useImperialUnits
    @State private var totalStepCount: Double?
    @State private var isLoading: Bool = false
    @State private var errorMessage: String?
    @State private var healthDataAuthorized: Bool = false
    
    @State private var screenTimeAuthorized: Bool = false
    
    @AppStorage("isOnboarding") private var isOnboarding: Bool = false
    
    @StateObject private var screenTimeManager = ScreenTimeManager.shared
    
    
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
            
            VStack(spacing: 20) {
                Text("Linked Data Sources")
                    .font(.custom("BodoniModa18pt-Italic", size: 20))
                    .padding(.top)
                
                HStack(spacing: 20) {
                VStack {
                    Image(systemName: healthKitManager.stepCountAuthorized ? "figure.walk.circle.fill" : "figure.walk.circle")
                        .font(.system(size: 30))
                    Text("Step Count")
                        .font(.custom("BodoniModa18pt-Italic", size: 16))
                }
                .foregroundColor(healthKitManager.stepCountAuthorized ? .primary : .gray)
                
                VStack {
                    Image(systemName: healthKitManager.sleepAuthorized ? "bed.double.circle.fill" : "bed.double.circle")
                        .font(.system(size: 30))
                    Text("Sleep")
                        .font(.custom("BodoniModa18pt-Italic", size: 16))
                }
                .foregroundColor(healthKitManager.sleepAuthorized ? .primary : .gray)
            }

            HStack(spacing: 20) {
                VStack {
                    Image(systemName: healthKitManager.distanceWalkingRunningAuthorized ? "figure.walk.circle.fill" : "figure.walk.circle")
                        .font(.system(size: 30))
                    Text("Walking + Running\nDistance")
                        .font(.custom("BodoniModa18pt-Italic", size: 16))
                        .multilineTextAlignment(.center)
                }
                .foregroundColor(healthKitManager.distanceWalkingRunningAuthorized ? .primary : .gray)
                    
                    VStack {
                        Image(systemName: screenTimeManager.isAuthorized ? "hourglass.circle.fill" : "hourglass.circle")
                            .font(.system(size: 30))
                        Text("Screen Time")
                            .font(.custom("BodoniModa18pt-Italic", size: 16))
                    }
                    .foregroundColor(screenTimeManager.isAuthorized ? .primary : .gray)
                }
            }
            .padding(.top, 8)
            
            Spacer()
        }
        .padding()
        .background(Color(hex: 0xfffef7))
        .onAppear(
            perform: {
                healthKitManager.checkAuthorizationStatus()
                fetchTotalSteps()
                screenTimeManager.checkAuthorizationStatus()
                 
            }
        )
        .onChange(of: healthKitManager.isAuthorized) { newValue in
            healthDataAuthorized = newValue
        }
        
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
        ScreenTimeReportView()
    .tabItem {
        Image(systemName: "hourglass")
            Text("Screen Time")
        }
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
