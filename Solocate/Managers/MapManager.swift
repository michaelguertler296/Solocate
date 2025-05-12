import Foundation
import MapKit

class MapManager {
    
    static func showLocationOnMap(mapView: MKMapView, latitude: Double, longitude: Double) {
        // Clear existing annotations
        mapView.removeAnnotations(mapView.annotations)

        // Create coordinate and annotation
        let coordinate = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
        let annotation = MKPointAnnotation()
        annotation.coordinate = coordinate

        // Default title while loading
        annotation.title = String(format: "%.4f, %.4f", latitude, longitude)
        mapView.addAnnotation(annotation)

        // Zoom to region
        let region = MKCoordinateRegion(center: coordinate,
                                        latitudinalMeters: 500,
                                        longitudinalMeters: 500)
        mapView.setRegion(region, animated: true)

        // Reverse geocode to get address
        let location = CLLocation(latitude: latitude, longitude: longitude)
        CLGeocoder().reverseGeocodeLocation(location) { placemarks, error in
            if let placemark = placemarks?.first {
                var address = ""
                if let name = placemark.name {
                    address += name
                }
                if let locality = placemark.locality {
                    address += ", \(locality)"
                }
                if let state = placemark.administrativeArea {
                    address += ", \(state)"
                }
                if let country = placemark.country {
                    address += ", \(country)"
                }
                
                DispatchQueue.main.async {
                    annotation.title = address.isEmpty ? annotation.title : address
                }
            }
        }
    }
}
