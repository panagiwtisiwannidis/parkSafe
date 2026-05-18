import Foundation
import CoreLocation
import Combine

// MARK: - LocationService
// Wraps CLLocationManager. Emits location updates and auth changes via Combine.
// No UI, no persistence, no business logic.

final class LocationService: NSObject, ObservableObject {

    // MARK: Published
    @Published var currentLocation: CLLocation?
    @Published var authorizationStatus: CLAuthorizationStatus = .notDetermined
    @Published var error: LocationError?

    // MARK: Private
    private let manager = CLLocationManager()

    override init() {
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyBest
        authorizationStatus = manager.authorizationStatus
    }

    // MARK: Public API

    func requestPermission() {
        manager.requestWhenInUseAuthorization()
    }

    func requestOneTimeLocation() {
        guard authorizationStatus == .authorizedWhenInUse ||
              authorizationStatus == .authorizedAlways else {
            requestPermission()
            return
        }
        manager.requestLocation()
    }

    var isAuthorized: Bool {
        authorizationStatus == .authorizedWhenInUse ||
        authorizationStatus == .authorizedAlways
    }

    var isDenied: Bool {
        authorizationStatus == .denied ||
        authorizationStatus == .restricted
    }
}

// MARK: - CLLocationManagerDelegate

extension LocationService: CLLocationManagerDelegate {

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        currentLocation = locations.last
        error = nil
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        self.error = .underlying(error)
    }

    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        DispatchQueue.main.async {
            self.authorizationStatus = manager.authorizationStatus
            if self.isAuthorized {
                manager.requestLocation()
            }
        }
    }
}

// MARK: - LocationError

enum LocationError: LocalizedError {
    case notAuthorized
    case noLocationAvailable
    case underlying(Error)

    var errorDescription: String? {
        switch self {
        case .notAuthorized:
            return NSLocalizedString("location.error.denied", comment: "")
        case .noLocationAvailable:
            return NSLocalizedString("location.error.no_location", comment: "")
        case .underlying(let e):
            return e.localizedDescription
        }
    }
}
