import SwiftUI
import CoreMotion

class MotionManager: ObservableObject {
    private let motionManager = CMMotionManager()
    @Published var x = 0.0
    @Published var y = 0.0
    @Published var z = 0.0

    init() {
        motionManager.gyroUpdateInterval = 1/60
        motionManager.startGyroUpdates(to: .main) { [weak self] data, _ in
            guard let data = data else { return }
            self?.x = data.rotationRate.x
            self?.y = data.rotationRate.y
            self?.z = data.rotationRate.z
        }
    }
}