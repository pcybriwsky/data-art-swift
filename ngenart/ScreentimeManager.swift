import SwiftUI
import FamilyControls
import DeviceActivity
import ManagedSettings

extension DeviceActivityName {
    static let daily = Self("daily")
}

class ScreenTimeManager: ObservableObject {
    static let shared = ScreenTimeManager()
    
    @Published var isAuthorized: Bool = false
    @Published var screenTimeData: String = "No data available"
    
    private let center = AuthorizationCenter.shared
    private let deviceActivityCenter = DeviceActivityCenter()

    
    private init() {}
    
    func requestAuthorization(completion: @escaping (Bool, Error?) -> Void) {
        Task {
            do {
                // Request authorization for FamilyControls
                try await center.requestAuthorization(for: .individual)
                
                // DeviceActivity and ManagedSettings don't require separate authorization
                // They are implicitly authorized when FamilyControls is authorized
                
                DispatchQueue.main.async {
                    self.isAuthorized = true
                    self.checkAuthorizationStatus()
                    completion(true, nil)
                }
            } catch {
                DispatchQueue.main.async {
                    self.isAuthorized = false
                    print("Failed to get Screen Time authorization: \(error.localizedDescription)")
                    completion(false, error)
                }
            }
        }
    }
    
    func checkAuthorizationStatus() {
        let status = center.authorizationStatus
        DispatchQueue.main.async {
            self.isAuthorized = (status == .approved)
            print("Screen Time authorization status: \(self.isAuthorized ? "Approved" : "Not Approved")")
        }
    }

    func fetchBasicScreenTimeData(completion: @escaping (String) -> Void) {
        guard isAuthorized else {
            completion("Not authorized to access Screen Time data")
            return
        }
        
        let schedule = DeviceActivitySchedule(
            intervalStart: DateComponents(hour: 0, minute: 0),
            intervalEnd: DateComponents(hour: 23, minute: 59),
            repeats: true
        )
        
        do {
            try deviceActivityCenter.startMonitoring(.daily, during: schedule)
            
            // Wait for a short period to collect some data
            DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
                self.deviceActivityCenter.stopMonitoring([.daily])
                
                // In a real scenario, you would implement a DeviceActivityReportExtension
                // to process the collected data. For this example, we'll use mock data.
                let totalScreenTime = Int.random(in: 60...480) // 1-8 hours in minutes
                let mostUsedApp = ["Social Media", "Productivity", "Entertainment", "Games"].randomElement()!
                let pickups = Int.random(in: 10...100)
                
                let dataString = """
                Total Screen Time: \(totalScreenTime / 60)h \(totalScreenTime % 60)m
                Most Used App Category: \(mostUsedApp)
                Device Pickups: \(pickups)
                """
                
                completion(dataString)
            }
        } catch {
            completion("Failed to start monitoring: \(error.localizedDescription)")
        }
    }
}
