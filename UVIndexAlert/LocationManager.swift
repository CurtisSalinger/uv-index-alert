import CoreLocation
import Combine
import WidgetKit

class LocationManager: NSObject, ObservableObject, CLLocationManagerDelegate {
    private let manager = CLLocationManager()
    @Published var lastLocation: CLLocation?

    override init() {
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyKilometer
        manager.distanceFilter = 1000

        // Load last known location from shared storage
        if let defaults = AppConstants.sharedDefaults {
            let lat = defaults.double(forKey: AppConstants.latitudeKey)
            let lng = defaults.double(forKey: AppConstants.longitudeKey)
            if lat != 0, lng != 0 {
                lastLocation = CLLocation(latitude: lat, longitude: lng)
            }
        }
    }

    func requestPermission() {
        manager.requestAlwaysAuthorization()
        manager.startUpdatingLocation()
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        lastLocation = locations.last

        // Share location with widget
        if let location = locations.last, let defaults = AppConstants.sharedDefaults {
            defaults.set(location.coordinate.latitude, forKey: AppConstants.latitudeKey)
            defaults.set(location.coordinate.longitude, forKey: AppConstants.longitudeKey)
            WidgetCenter.shared.reloadAllTimelines()
        }
    }

    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        switch manager.authorizationStatus {
        case .authorizedAlways, .authorizedWhenInUse:
            manager.startUpdatingLocation()
        default:
            break
        }
    }
}
