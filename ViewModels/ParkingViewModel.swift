import Foundation
import CoreLocation
import Combine

// MARK: - ParkingViewModel
// The single ViewModel for the app.
// Owns all services, exposes @Published state, handles all user intents.
// Views never touch services directly.

@MainActor
final class ParkingViewModel: ObservableObject {

    // MARK: - Published State (Views read these)

    @Published var savedSpots: [ParkingSpot] = []
    @Published var spotHistory: [ParkingSpot] = []
    @Published var reminderDate: Date?
    @Published var isLocating: Bool = false
    @Published var errorMessage: String?

    // Forwarded from LocationService
    @Published var locationAuthStatus: CLAuthorizationStatus = .notDetermined
    @Published var currentLocation: CLLocation?

    // MARK: - Services (injected, testable — private to enforce ViewModel-as-boundary)

    private let locationService: LocationService
    private let notificationService: NotificationService
    private let navigationService: NavigationService
    private let persistenceService: PersistenceService

    // MARK: - Combine
    private var cancellables = Set<AnyCancellable>()

    // MARK: - Init

    init(
        locationService: LocationService         = LocationService(),
        notificationService: NotificationService = NotificationService(),
        navigationService: NavigationService     = NavigationService(),
        persistenceService: PersistenceService   = PersistenceService()
    ) {
        self.locationService     = locationService
        self.notificationService = notificationService
        self.navigationService   = navigationService
        self.persistenceService  = persistenceService

        bindLocationService()
        savedSpots   = persistenceService.loadSpots()
        spotHistory  = persistenceService.loadHistory()
        reminderDate = persistenceService.loadReminderDate()
    }

    // MARK: - Bind LocationService → ViewModel

    private func bindLocationService() {
        locationService.$authorizationStatus
            .receive(on: RunLoop.main)
            .assign(to: &$locationAuthStatus)

        locationService.$currentLocation
            .receive(on: RunLoop.main)
            .sink { [weak self] location in
                self?.currentLocation = location
                if self?.isLocating == true { self?.isLocating = false }
            }
            .store(in: &cancellables)

        locationService.$error
            .receive(on: RunLoop.main)
            .compactMap { $0?.errorDescription }
            .sink { [weak self] msg in
                self?.errorMessage = msg
                self?.isLocating = false
            }
            .store(in: &cancellables)
    }

    // MARK: - Intents (Views call these)

    func requestLocationPermission() {
        locationService.requestPermission()
    }

    func requestNotificationPermission(completion: @escaping (Bool) -> Void) {
        notificationService.requestPermission(completion: completion)
    }

    func locateUser() {
        guard !locationService.isDenied else { return }
        locationService.requestOneTimeLocation()
    }

    /// Locate the user then immediately save as parking spot.
    func locateAndSave() {
        guard !locationService.isDenied else {
            errorMessage = Strings.Location.errorDenied
            return
        }
        isLocating = true
        errorMessage = nil

        locationService.$currentLocation
            .compactMap { $0 }
            .filter { $0.horizontalAccuracy >= 0 && $0.horizontalAccuracy < 100 }
            .first()
            .setFailureType(to: LocationError.self)
            .timeout(.seconds(15), scheduler: RunLoop.main) { LocationError.noLocationAvailable }
            .receive(on: RunLoop.main)
            .sink(
                receiveCompletion: { [weak self] completion in
                    if case .failure = completion {
                        self?.isLocating = false
                        self?.errorMessage = Strings.Location.errorNoLocation
                    }
                },
                receiveValue: { [weak self] location in
                    self?.isLocating = false
                    self?.commitSave(location: location)
                }
            )
            .store(in: &cancellables)

        locationService.requestOneTimeLocation()
    }

    // MARK: - Private save helper

    private func commitSave(location: CLLocation) {
        var spot = ParkingSpot(coordinate: location.coordinate)
        persistenceService.upsertSpot(spot)
        savedSpots = persistenceService.loadSpots()
        persistenceService.addToHistory(spot)
        spotHistory = persistenceService.loadHistory()
        errorMessage = nil

        reverseGeocode(location: location) { [weak self] address in
            spot.address = address
            self?.persistenceService.upsertSpot(spot)
            self?.persistenceService.addToHistory(spot)
            self?.savedSpots = self?.persistenceService.loadSpots() ?? []
            self?.spotHistory = self?.persistenceService.loadHistory() ?? []
        }
    }

    // MARK: - Spot Intents

    func clearSpot(id: UUID) {
        persistenceService.removeSpot(id: id)
        savedSpots = persistenceService.loadSpots()
        if savedSpots.isEmpty { cancelReminder() }
    }

    func updateSpotNote(id: UUID, note: String?) {
        guard let idx = savedSpots.firstIndex(where: { $0.id == id }) else { return }
        var spot = savedSpots[idx]
        spot.note = note
        persistenceService.upsertSpot(spot)
        savedSpots = persistenceService.loadSpots()
    }

    // MARK: - History Intents

    func deleteFromHistory(at offsets: IndexSet) {
        let ids = offsets.map { spotHistory[$0].id }
        ids.forEach {
            persistenceService.removeFromHistory(id: $0)
            persistenceService.removeSpot(id: $0)
        }
        spotHistory = persistenceService.loadHistory()
        savedSpots  = persistenceService.loadSpots()
        if savedSpots.isEmpty { cancelReminder() }
    }

    func clearHistory() {
        persistenceService.clearHistory()
        spotHistory = []
    }

    // MARK: - Navigation Intents

    func navigateWithAppleMaps(spot: ParkingSpot) {
        navigationService.openAppleMaps(to: spot.coordinate)
    }

    func navigateWithGoogleMaps(spot: ParkingSpot) {
        navigationService.openGoogleMaps(to: spot.coordinate)
    }

    // MARK: - Reminder Intents

    func setReminder(at date: Date) {
        notificationService.scheduleReminder(at: date)
        reminderDate = date
        persistenceService.saveReminderDate(date)
    }

    func cancelReminder() {
        notificationService.cancelReminders()
        reminderDate = nil
        persistenceService.saveReminderDate(nil)
    }

    /// Re-sync reminder state from the system (call on appear).
    func refreshNotificationStatus() {
        notificationService.checkPendingStatus { [weak self] active in
            if !active {
                self?.reminderDate = nil
                self?.persistenceService.saveReminderDate(nil)
            }
        }
    }

    func resetBadge() {
        notificationService.resetBadge()
    }

    // MARK: - Computed Helpers (Views use these)

    func distance(to spot: ParkingSpot) -> String? {
        guard let current = currentLocation else { return nil }
        return spot.formattedDistance(from: current)
    }

    var locationIsDenied: Bool { locationService.isDenied }

    // MARK: - Private Helpers

    private func reverseGeocode(location: CLLocation, completion: @escaping (String?) -> Void) {
        let geocoder = CLGeocoder()
        geocoder.reverseGeocodeLocation(location) { placemarks, _ in
            guard let p = placemarks?.first else { completion(nil); return }
            var parts: [String] = []
            if let name = p.name          { parts.append(name) }
            else if let road = p.thoroughfare { parts.append(road) }
            if let city = p.locality      { parts.append(city) }
            completion(parts.isEmpty ? nil : parts.joined(separator: ", "))
        }
    }
}
