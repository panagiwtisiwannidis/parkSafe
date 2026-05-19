import Foundation

// MARK: - PersistenceService
// Thin wrapper around UserDefaults for encoding/decoding ParkingSpot.
// No UI, no location, no notifications.

final class PersistenceService {

    private let spotsKey      = "parksafe_saved_spots"
    private let legacyKey     = "parksafe_saved_spot"
    private let historyKey    = "parksafe_spot_history"
    private let reminderKey   = "parksafe_reminder_date"
    private let maxHistory    = 20
    private let defaults: UserDefaults

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    // MARK: - Active Spots (multi-spot)

    func loadSpots() -> [ParkingSpot] {
        if let data = defaults.data(forKey: spotsKey),
           let spots = try? JSONDecoder().decode([ParkingSpot].self, from: data) {
            return spots
        }
        // migrate legacy single-spot
        if let data = defaults.data(forKey: legacyKey),
           let old = try? JSONDecoder().decode(ParkingSpot.self, from: data) {
            saveSpots([old])
            defaults.removeObject(forKey: legacyKey)
            return [old]
        }
        return []
    }

    func saveSpots(_ spots: [ParkingSpot]) {
        guard let data = try? JSONEncoder().encode(spots) else { return }
        defaults.set(data, forKey: spotsKey)
    }

    func upsertSpot(_ spot: ParkingSpot) {
        var spots = loadSpots()
        if let idx = spots.firstIndex(where: { $0.id == spot.id }) {
            spots[idx] = spot
        } else {
            spots.insert(spot, at: 0)
        }
        saveSpots(spots)
    }

    func removeSpot(id: UUID) {
        var spots = loadSpots()
        spots.removeAll { $0.id == id }
        saveSpots(spots)
    }

    // MARK: - Reminder Date

    func loadReminderDate() -> Date? {
        let t = defaults.double(forKey: reminderKey)
        guard t > 0 else { return nil }
        let date = Date(timeIntervalSince1970: t)
        return date > Date() ? date : nil
    }

    func saveReminderDate(_ date: Date?) {
        if let date {
            defaults.set(date.timeIntervalSince1970, forKey: reminderKey)
        } else {
            defaults.removeObject(forKey: reminderKey)
        }
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
