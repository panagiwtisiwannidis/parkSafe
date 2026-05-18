import Foundation

// MARK: - PersistenceService
// Thin wrapper around UserDefaults for encoding/decoding ParkingSpot.
// No UI, no location, no notifications.

final class PersistenceService {

    private let key = "parksafe_saved_spot"
    private let defaults: UserDefaults

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    // MARK: - Load

    func loadSpot() -> ParkingSpot? {
        guard let data = defaults.data(forKey: key) else { return nil }
        return try? JSONDecoder().decode(ParkingSpot.self, from: data)
    }

    // MARK: - Save

    func saveSpot(_ spot: ParkingSpot) {
        guard let data = try? JSONEncoder().encode(spot) else { return }
        defaults.set(data, forKey: key)
    }

    // MARK: - Clear

    func clearSpot() {
        defaults.removeObject(forKey: key)
    }
}
