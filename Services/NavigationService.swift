import Foundation
import CoreLocation
import UIKit

// MARK: - NavigationService
// Builds deep-link URLs and opens Apple Maps / Google Maps.
// No UI, no state, pure functions.

final class NavigationService {

    // MARK: - Apple Maps

    func openAppleMaps(to coordinate: CLLocationCoordinate2D) {
        let url = URL(string:
            "maps://?daddr=\(coordinate.latitude),\(coordinate.longitude)&dirflg=w"
        )
        open(url)
    }

    // MARK: - Google Maps

    func openGoogleMaps(to coordinate: CLLocationCoordinate2D) {
        let nativeURL = URL(string:
            "comgooglemaps://?daddr=\(coordinate.latitude),\(coordinate.longitude)&directionsmode=walking"
        )
        let webURL = URL(string:
            "https://www.google.com/maps/dir/?api=1&destination=\(coordinate.latitude),\(coordinate.longitude)&travelmode=walking"
        )

        if let native = nativeURL, UIApplication.shared.canOpenURL(native) {
            open(native)
        } else {
            open(webURL)
        }
    }

    // MARK: - Private

    private func open(_ url: URL?) {
        guard let url else { return }
        DispatchQueue.main.async {
            UIApplication.shared.open(url)
        }
    }
}
