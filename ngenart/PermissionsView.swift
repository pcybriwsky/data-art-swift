import SwiftUI

struct PermissionsView: View {
    @EnvironmentObject var locationManager: LocationManager
    @EnvironmentObject var healthKitManager: HealthKitManager
    
    @State private var healthPermissionGranted = false
    @State private var locationPermissionGranted = false
    
    var body: some View {
        VStack {
            Text("We need your permission to access your Health and Location data.")
                .padding()
            
            Button("Allow Health Access") {
                healthKitManager.requestAuthorization { success, error in
                    if success {
                        healthPermissionGranted = true
                    } else {
                        // Handle the error appropriately
                    }
                }
            }
            .padding()
            .disabled(healthPermissionGranted)
            
            Button("Allow Location Access") {
                locationManager.requestLocationAuthorization()
                // You can set a flag here when permission is granted
            }
            .padding()
            .disabled(locationPermissionGranted)
        }
    }
}
