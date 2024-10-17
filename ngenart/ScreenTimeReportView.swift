import SwiftUI

struct ScreenTimeReportView: View {
    @ObservedObject var manager = ScreenTimeManager.shared
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Screen Time Monitoring")
                .font(.title)
            
            Text("Authorization Status: \(manager.isAuthorized ? "Authorized" : "Not Authorized")")
            
            Text("Monitoring Status: \(manager.monitoringStatus)")
            
            Button("Request Authorization") {
                manager.requestAuthorization { success, error in
                    if success {
                        print("Authorization granted")
                    } else if let error = error {
                        print("Authorization failed: \(error.localizedDescription)")
                    }
                }
            }
            
            Button("Start Monitoring") {
                manager.startMonitoringDeviceActivity()
            }
            .disabled(!manager.isAuthorized)
            
            Button("Stop Monitoring") {
                manager.stopMonitoringDeviceActivity()
            }
            
            Button("Fetch Basic Screen Time Data") {
                manager.fetchBasicScreenTimeData { data in
                    print(data)
                }
            }
            .disabled(!manager.isAuthorized)
            
            Text(manager.screenTimeData)
                .padding()
        }
        .padding()
    }
}