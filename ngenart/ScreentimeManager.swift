import SwiftUI
import FamilyControls
import DeviceActivity
import ManagedSettings

extension DeviceActivityName {
    static let daily = Self("daily")
}

extension DeviceActivityEvent.Name {
    static let encouraged = Self("encouraged")
}


class ScreenTimeManager: ObservableObject {
    static let shared = ScreenTimeManager()
    
    @Published var isAuthorized: Bool = false
    @Published var screenTimeData: String = "No data available"
    @Published var screenTimeReport: DeviceActivityReport.Context?
    @Published var monitoringStatus: String = "Not monitoring"
    
    private let center = AuthorizationCenter.shared
    private let deviceActivityCenter = DeviceActivityCenter()

    
    private init() {
        model = MyModel() // Initialize your model here

    }
    
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

    func startMonitoringDeviceActivity() {
        guard isAuthorized else {
            print("Not authorized to monitor device activity")
            return
        }
        
        let schedule = DeviceActivitySchedule(
            intervalStart: DateComponents(hour: 0, minute: 0),
            intervalEnd: DateComponents(hour: 23, minute: 59),
            repeats: true
        )
        
        let events: [DeviceActivityEvent.Name: DeviceActivityName] = [
            .encouraged: DeviceActivityName(
                applications: model.selectionToEncourage.applicationsTokens,
                threshold: DateComponents(minute: model.minutes) // Assuming 'minutes' is a property of MyModel
            )
        ]
        
        do {
        try deviceActivityCenter.startMonitoring(.daily, events: events, during: schedule)
        monitoringStatus = "Monitoring started"
        print("Successfully started monitoring device activity")
    } catch {
        monitoringStatus = "Failed to start monitoring: \(error.localizedDescription)"
            print("Failed to start monitoring device activity: \(error.localizedDescription)")
        }   
    }
    
    func stopMonitoringDeviceActivity() {
        deviceActivityCenter.stopMonitoring([.daily])
        monitoringStatus = "Monitoring stopped"
        print("Stopped monitoring device activity")
    }
    
    func setDeviceActivityFilter() {
        let filter = DeviceActivityFilter(
            segment: .daily(during: DeviceActivitySchedule(
                intervalStart: DateComponents(hour: 0, minute: 0),
                intervalEnd: DateComponents(hour: 23, minute: 59),
                repeats: true
            )),
            users: .all,
            devices: .init([.iPhone, .iPad])
        )
        
        // You can use this filter when requesting reports or setting up monitoring
        // For example, you could pass this to a DeviceActivityReport.request call
    }
}

struct MyModel {
    var selectionToEncourage: FamilyActivitySelection
    var minutes: Int
    
    init() {
        // Initialize with default values or load from user preferences
        self.selectionToEncourage = FamilyActivitySelection()
        self.minutes = 60 // Default to 1 hour
    }
}
