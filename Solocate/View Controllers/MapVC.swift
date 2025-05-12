import UIKit
import CoreLocation
import CoreMotion
import MapKit

class MapVC: UIViewController {
    var receivedAzimuth: Double?
    var receivedElevation: Double?
    var imageToDisplay: UIImage?
    let estimator = LocationEstimator()
    var mapView: MKMapView!

    // Labels
    let solarAzimuthLabel = UILabel()
    let solarElevationLabel = UILabel()
    let locationLabel = UILabel()
    
    var hasEstimatedLocation = false

    override func viewDidLoad() {
        super.viewDidLoad()

        // Set up map view
        mapView = MKMapView(frame: self.view.bounds)
        mapView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        self.view.addSubview(mapView)

        // Set up labels and back button
        setupSolarLabels()
        setupLocationLabel()
        setupBackButton()

        // Safely unwrap and estimate location
        if let azimuth = receivedAzimuth, let elevation = receivedElevation {
            EstimateLocation(solarAzimuth: azimuth, solarElevation: elevation)
        } else {
            print("Missing solar data")
        }
    }

    func EstimateLocation(solarAzimuth: Double, solarElevation: Double) {
        let (estimatedLat, estimatedLon) = estimator.estimateLocation(
            solarAz: solarAzimuth,
            solarEl: solarElevation,
            initialLat: 34,
            initialLon: -116
        )

        // Update labels
        solarAzimuthLabel.text = String(format: "Azimuth: %.2f°", solarAzimuth)
        solarElevationLabel.text = String(format: "Elevation: %.2f°", solarElevation)
        locationLabel.text = String(format: "Lat: %.4f, Lon: %.4f", estimatedLat, estimatedLon)

        MapManager.showLocationOnMap(
            mapView: mapView,
            latitude: estimatedLat,
            longitude: estimatedLon
        )
    }

    func setupSolarLabels() {
        [solarAzimuthLabel, solarElevationLabel].forEach { label in
            label.translatesAutoresizingMaskIntoConstraints = false
            label.textColor = .white
            label.backgroundColor = UIColor.black.withAlphaComponent(0.6)
            label.font = UIFont.systemFont(ofSize: 14, weight: .medium)
            label.layer.cornerRadius = 6
            label.clipsToBounds = true
            view.addSubview(label)
        }

        NSLayoutConstraint.activate([
            solarAzimuthLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 10),
            solarAzimuthLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            solarElevationLabel.topAnchor.constraint(equalTo: solarAzimuthLabel.bottomAnchor, constant: 8),
            solarElevationLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16)
        ])
    }

    func setupLocationLabel() {
        locationLabel.translatesAutoresizingMaskIntoConstraints = false
        locationLabel.textColor = .white
        locationLabel.backgroundColor = UIColor.black.withAlphaComponent(0.6)
        locationLabel.font = UIFont.systemFont(ofSize: 14, weight: .medium)
        locationLabel.textAlignment = .center
        locationLabel.layer.cornerRadius = 6
        locationLabel.clipsToBounds = true
        view.addSubview(locationLabel)

        NSLayoutConstraint.activate([
            locationLabel.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -20),
            locationLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            locationLabel.widthAnchor.constraint(lessThanOrEqualTo: view.widthAnchor, multiplier: 0.9),
            locationLabel.heightAnchor.constraint(equalToConstant: 30)
        ])
    }

    func setupBackButton() {
        let backButton = UIButton(type: .system)
        let config = UIImage.SymbolConfiguration(pointSize: 18, weight: .medium)
        let backImage = UIImage(systemName: "chevron.backward.circle.fill", withConfiguration: config)
        backButton.setImage(backImage, for: .normal)
        backButton.tintColor = .white
        backButton.backgroundColor = UIColor.black.withAlphaComponent(0.6)
        backButton.layer.cornerRadius = 20
        backButton.clipsToBounds = true
        backButton.addTarget(self, action: #selector(backButtonTapped), for: .touchUpInside)

        backButton.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(backButton)

        NSLayoutConstraint.activate([
            backButton.topAnchor.constraint(equalTo: solarElevationLabel.bottomAnchor, constant: 10),
            backButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            backButton.widthAnchor.constraint(equalToConstant: 40),
            backButton.heightAnchor.constraint(equalToConstant: 40)
        ])
    }

    @objc func backButtonTapped() {
        self.dismiss(animated: true, completion: nil)
    }
}
