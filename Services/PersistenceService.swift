import Foundation

// MARK: - PersistenceService
// Thin wrapper around UserDefaults for encoding/decoding ParkingSpot.
// No UI, no location, no notifications.

final class PersistenceService {

    private let key        = "parksafe_saved_spot"
    private let historyKey = "parksafe_spot_history"
    private let maxHistory = 20
    private let defaults: UserDefaults

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    // MARK: - Current Spot

    func loadSpot() -> ParkingSpot? {
        guard let data = defaults.data(forKey: key) else { return nil }
        return try? JSONDecoder().decode(ParkingSpot.self, from: data)
    }

    func saveSpot(_ spot: ParkingSpot) {
        guard let data = try? JSONEncoder().encode(spot) else { return }
        defaults.set(data, forKey: key)
    }

    func clearSpot() {
        defaults.removeObject(forKey: key)
    }

    // MARK: - History

    func loadHistory() -> [ParkingSpot] {
        guard let data = defaults.data(forKey: historyKey) else { return [] }
        return (try? JSONDecoder().decode([ParkingSpot].self, from: data)) ?? []
    }

    func addToHistory(_ spot: ParkingSpot) {
        var history = loadHistory()
        history.removeAll { $0.id == spot.id }
        history.insert(spot, at: 0)
        if history.count > maxHistory { history = Array(history.prefix(maxHistory)) }
        guard let data = try? JSONEncoder().encode(history) else { return }
        defaults.set(data, forKey: historyKey)
    }

    func removeFromHistory(id: UUID) {
        var history = loadHistory()
        history.removeAll { $0.id == id }
        guard let data = try? JSONEncoder().encode(history) else { return }
        defaults.set(data, forKey: historyKey)
    }

    func clearHistory() {
        defaults.removeObject(forKey: historyKey)
    }
}
