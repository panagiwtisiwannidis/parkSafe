import Foundation
import CoreLocation

// MARK: - Model
// Pure data container. No business logic, no UI dependencies.

struct ParkingSpot: Codable, Identifiable {
    let id: UUID
    let latitude: Double
    let longitude: Double
    let timestamp: Date
    var address: String?
    var note: String?

    // MARK: Init
    init(
        id: UUID = UUID(),
        coordinate: CLLocationCoordinate2D,
        timestamp: Date = Date(),
        address: String? = nil,
        note: String? = nil
    ) {
        self.id = id
        self.latitude = coordinate.latitude
        self.longitude = coordinate.longitude
        self.timestamp = timestamp
        self.address = address
        self.note = note
    }

    // MARK: Computed
    var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }

    var coordinateString: String {
        String(format: "%.4f, %.4f", latitude, longitude)
    }

    var formattedTimestamp: String {
        let f = DateFormatter()
        f.timeStyle = .short
        f.dateStyle = .medium
        return f.string(from: timestamp)
    }

    var relativeTime: String {
        let f = RelativeDateTimeFormatter()
        f.unitsStyle = .abbreviated
        return f.localizedString(for: timestamp, relativeTo: Date())
    }

    func distance(from location: CLLocation) -> CLLocationDistance {
        let spotLocation = CLLocation(latitude: latitude, longitude: longitude)
        return location.distance(from: spotLocation)
    }

    func formattedDistance(from location: CLLocation) -> String {
        let meters = distance(from: location)
        return Strings.Chip.distanceLabel(meters: meters)
    }
}
