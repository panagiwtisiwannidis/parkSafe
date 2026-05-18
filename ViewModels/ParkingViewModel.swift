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
    @Published var isLocating: Bool = false
    @Published var notificationsEnabled: Bool = false
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
        locationService: LocationService       = LocationService(),
        notificationService: NotificationService = NotificationService(),
        navigationService: NavigationService   = NavigationService(),
        persistenceService: PersistenceService = PersistenceService()
    ) {
        self.locationService     = locationService
        self.notificationService = notificationService
        self.navigationService   = navigationService
        self.persistenceService  = persistenceService

        bindLocationService()
        savedSpots = persistenceService.loadSpots()
        spotHistory = persistenceService.loadHistory()
        notificationService.checkPendingStatus { [weak self] active in
            self?.notificationsEnabled = active
        }
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
                if self?.isLocating == true {
                    self?.isLocating = false
                }
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

    /// Step 1 of onboarding — request location permission.
    func requestLocationPermission() {
        locationService.requestPermission()
    }

    /// Step 2 of onboarding — request notification permission.
    func requestNotificationPermission(completion: @escaping (Bool) -> Void) {
        notificationService.requestPermission(completion: completion)
    }

    /// Refresh user location for distance display (non-blocking).
    func locateUser() {
        guard !locationService.isDenied else { return }
        locationService.requestOneTimeLocation()
    }

    /// Locate the user then immediately save as parking spot.
    /// Reacts to the first valid GPS fix via Combine.
    /// Times out after 15s so isLocating never stays true forever.
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
            .timeout(.seconds(15), scheduler: RunLoop.main) {
                LocationError.noLocationAvailable
            }
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
        scheduleNotifications()
        errorMessage = nil

        reverseGeocode(location: location) { [weak self] address in
            spot.address = address
            self?.persistenceService.upsertSpot(spot)
            self?.persistenceService.addToHistory(spot)
            self?.savedSpots = self?.persistenceService.loadSpots() ?? []
            self?.spotHistory = self?.persistenceService.loadHistory() ?? []
        }
    }

    /// Remove a specific parking spot by ID.
    func clearSpot(id: UUID) {
        persistenceService.removeSpot(id: id)
        savedSpots = persistenceService.loadSpots()
        if savedSpots.isEmpty { cancelNotifications() }
    }

    // MARK: - History Intents

    func deleteFromHistory(at offsets: IndexSet) {
        offsets.forEach { persistenceService.removeFromHistory(id: spotHistory[$0].id) }
        spotHistory = persistenceService.loadHistory()
    }

    func clearHistory() {
        persistenceService.clearHistory()
        spotHistory = []
    }

    func navigateWithAppleMaps(spot: ParkingSpot) {
        navigationService.openAppleMaps(to: spot.coordinate)
    }

    func navigateWithGoogleMaps(spot: ParkingSpot) {
        navigationService.openGoogleMaps(to: spot.coordinate)
    }

    /// Toggle hourly reminders on or off.
    func toggleNotifications() {
        notificationsEnabled ? cancelNotifications() : scheduleNotifications()
    }

    /// Re-sync notification status from the system (call on appear).
    func refreshNotificationStatus() {
        notificationService.checkPendingStatus { [weak self] active in
            self?.notificationsEnabled = active
        }
    }

    /// HIGH FIX: Clear the app badge (call when app becomes active).
    func resetBadge() {
        notificationService.resetBadge()
    }

    // MARK: - Computed Helpers (Views use these)

    func distance(to spot: ParkingSpot) -> String? {
        guard let current = currentLocation else { return nil }
        return spot.formattedDistance(from: current)
    }

    var locationIsDenied: Bool {
        locationService.isDenied
    }

    // MARK: - Private Helpers

    private func scheduleNotifications() {
        notificationService.scheduleHourlyReminders()
        notificationsEnabled = true
    }

    private func cancelNotifications() {
        notificationService.cancelReminders()
        notificationsEnabled = false
    }

    private func reverseGeocode(location: CLLocation, completion: @escaping (String?) -> Void) {
        let geocoder = CLGeocoder()
        geocoder.reverseGeocodeLocation(location) { placemarks, _ in
            guard let p = placemarks?.first else {
                completion(nil)
                return
            }
            var parts: [String] = []
            if let name = p.name { parts.append(name) }
            else if let road = p.thoroughfare { parts.append(road) }
            if let city = p.locality { parts.append(city) }
            completion(parts.isEmpty ? nil : parts.joined(separator: ", "))
        }
    }
}
