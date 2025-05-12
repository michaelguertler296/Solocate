import Foundation
import CoreLocation

protocol HeadingManagerDelegate: AnyObject {
    func didUpdateHeading(_ heading: CLLocationDirection)
    func didFailWithError(_ error: Error)
}

class HeadingManager: NSObject, CLLocationManagerDelegate {
    
    private let locationManager = CLLocationManager()
    weak var delegate: HeadingManagerDelegate?

    override init() {
        super.init()
        
        locationManager.delegate = self
        locationManager.requestWhenInUseAuthorization()
        
        if CLLocationManager.headingAvailable() {
            locationManager.headingFilter = kCLHeadingFilterNone
            locationManager.startUpdatingHeading()
        } else {
            delegate?.didFailWithError(NSError(
                domain: "HeadingManager",
                code: 0,
                userInfo: [NSLocalizedDescriptionKey: "Heading not available"]
            ))
        }
    }

    func locationManager(_ manager: CLLocationManager, didUpdateHeading newHeading: CLHeading) {
        guard newHeading.headingAccuracy >= 0 else { return }
        delegate?.didUpdateHeading(newHeading.magneticHeading)
        // Removed stopUpdatingHeading() so heading updates continuously
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        delegate?.didFailWithError(error)
    }

    func locationManagerShouldDisplayHeadingCalibration(_ manager: CLLocationManager) -> Bool {
        return true
    }
}
