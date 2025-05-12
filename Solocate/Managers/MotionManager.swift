import Foundation
import CoreMotion

class MotionManager {
    private let motionManager = CMMotionManager()
    var onMotionUpdate: ((CMDeviceMotion) -> Void)?

    init(updateInterval: TimeInterval = 0.05) {
        motionManager.deviceMotionUpdateInterval = updateInterval
    }

    func start() {
        guard motionManager.isDeviceMotionAvailable else {
            print("Device motion is not available")
            return
        }

        motionManager.startDeviceMotionUpdates(to: .main) { [weak self] motion, error in
            if let motion = motion {
                self?.onMotionUpdate?(motion)
            } else if let error = error {
                print("Motion error: \(error.localizedDescription)")
            }
        }
    }
    
    func getPitch(completion: @escaping (Double?) -> Void) {
            guard motionManager.isDeviceMotionAvailable else {
                completion(nil)
                return
            }

            motionManager.deviceMotionUpdateInterval = 0.1
            motionManager.startDeviceMotionUpdates(to: .main) { (motion, error) in
                if let attitude = motion?.attitude {
                    let pitchDegrees = attitude.pitch * (180 / .pi)
                    completion(pitchDegrees)
                    self.motionManager.stopDeviceMotionUpdates()
                } else {
                    completion(nil)
                }
            }
        }

    func stop() {
        motionManager.stopDeviceMotionUpdates()
    }
}
