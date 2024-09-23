import CoreLocation
import SwiftUI

class LocationManager: NSObject, ObservableObject, CLLocationManagerDelegate {
    private let manager = CLLocationManager()

    override init() {
        super.init()
        manager.delegate = self
    }

    func requestLocationAuthorization() {
        // This line triggers the authorization request
        manager.requestWhenInUseAuthorization()
    }

    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        switch status {
        case .authorizedWhenInUse, .authorizedAlways:
            // Permission granted
            print("Location access granted")
        case .denied, .restricted:
            // Permission denied
            print("Location access denied")
        case .notDetermined:
            // Permission not determined yet
            print("Location access not determined")
        @unknown default:
            break
        }
    }
}
