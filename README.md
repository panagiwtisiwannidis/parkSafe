# ParkSafe — MVVM Edition

A SwiftUI parking reminder app refactored to a clean **MVVM + Services** architecture.

---

## Architecture Overview

```
┌─────────────────────────────────────────────────────┐
│                      VIEWS                          │
│  (SwiftUI — read @Published state, call intents)    │
│                                                     │
│  Onboarding/          Main/           Components/   │
│  OnboardingView       ContentView     ParkingPinView│
│                       MainView        InfoChip      │
│                       HeaderView      PermissionBadge│
│                       SavedSpotCard   SectionLabel  │
│                       NavigationCard  cardStyle()   │
│                       NotifToggleCard               │
│                       ActionViews                   │
└────────────────────┬────────────────────────────────┘
                     │ @EnvironmentObject
                     ▼
┌─────────────────────────────────────────────────────┐
│                   VIEW MODEL                        │
│  ParkingViewModel  (@MainActor ObservableObject)    │
│                                                     │
│  @Published state:  savedSpot, isLocating,          │
│                     notificationsEnabled,           │
│                     locationAuthStatus, etc.        │
│                                                     │
│  Intents (called by Views):                         │
│    locateUser()        saveParkingSpot()            │
│    clearParkingSpot()  toggleNotifications()        │
│    navigateWithAppleMaps / GoogleMaps               │
│    requestLocationPermission()                      │
│    requestNotificationPermission()                  │
│    refreshNotificationStatus()                      │
└──┬──────────────┬──────────────┬────────────────────┘
   │              │              │
   ▼              ▼              ▼
┌────────┐  ┌──────────┐  ┌──────────────┐  ┌───────────────┐
│Location│  │Notif     │  │Navigation    │  │Persistence    │
│Service │  │Service   │  │Service       │  │Service        │
│        │  │          │  │              │  │               │
│CLLocation│ │UNUser    │  │Apple Maps /  │  │UserDefaults   │
│Manager │  │Notif     │  │Google Maps   │  │JSON encode/   │
│        │  │Center    │  │deep links    │  │decode         │
└────────┘  └──────────┘  └──────────────┘  └───────────────┘
                     │
                     ▼
┌─────────────────────────────────────────────────────┐
│                     MODEL                           │
│  ParkingSpot  (Codable, pure data)                  │
│  coordinate, timestamp, address, note               │
│  Computed: relativeTime, formattedDistance()        │
└─────────────────────────────────────────────────────┘
```

---

## MVVM Responsibilities

| Layer | Files | Responsibility |
|---|---|---|
| **Model** | `ParkingSpot.swift` | Pure data + Codable. No UI, no logic. |
| **ViewModel** | `ParkingViewModel.swift` | All business logic. Owns services. Exposes `@Published` state and intent methods. |
| **Services** | `LocationService` `NotificationService` `NavigationService` `PersistenceService` | Each does one thing. Injected into ViewModel. Independently testable. |
| **Views** | All SwiftUI files | Read state. Call intents. Zero business logic. |

### Key MVVM rules enforced
- Views **never** access Services directly — only through the ViewModel
- Services are `private` on the ViewModel
- The Model has **no** knowledge of UI or services
- The ViewModel is `@MainActor` so all `@Published` mutations are thread-safe
- Services are **injected** via init, making them swappable for mocks in tests

---

## Project Structure

```
ParkSafe/
├── App/
│   ├── ParkingApp.swift          # @main, injects ViewModel
│   └── Info.plist                # Permissions
│
├── Models/
│   └── ParkingSpot.swift         # Pure data model
│
├── ViewModels/
│   └── ParkingViewModel.swift    # Single ViewModel, all intents
│
├── Services/
│   ├── LocationService.swift     # CLLocationManager wrapper
│   ├── NotificationService.swift # UNUserNotificationCenter wrapper
│   ├── NavigationService.swift   # Apple/Google Maps deep links
│   └── PersistenceService.swift  # UserDefaults read/write
│
└── Views/
    ├── Onboarding/
    │   └── OnboardingView.swift  # 4-step permission onboarding
    ├── Main/
    │   ├── ContentView.swift     # Router (onboarding vs main)
    │   ├── MainView.swift        # Root screen + AppBackground
    │   ├── HeaderView.swift
    │   ├── SavedSpotCard.swift   # Map + address + distance
    │   ├── NavigationCard.swift  # Apple/Google nav buttons
    │   ├── NotificationToggleCard.swift
    │   └── ActionViews.swift     # EmptyState, SaveButton, ClearButton
    └── Components/
        └── Components.swift      # ParkingPinView, InfoChip,
                                  # PermissionBadgeView, SectionLabel,
                                  # cardStyle() modifier
```

---

## Setup in Xcode

1. **New project** → iOS App → SwiftUI → Swift, min iOS 16
2. Create the folder groups above and add all files
3. **Merge `Info.plist`** keys (location + Google Maps URL scheme)
4. **Add color assets** in `Assets.xcassets`:
   - `BGTop` → `#0D1B2A`
   - `BGBottom` → `#1A2E45`
   - `AccentColor` → `#3B82F6`
5. **Signing & Capabilities** → add *Location When In Use* + *Push Notifications*
6. Build & run on a **real device** (GPS simulator is unreliable)

---

## Testing Services in Isolation

Because services are injected, you can write unit tests like:

```swift
// Example: inject mock persistence
let mock = MockPersistenceService()
let vm = ParkingViewModel(persistenceService: mock)
vm.saveParkingSpot()
XCTAssertNotNil(mock.savedSpot)
```

Each service has a minimal surface area, making mocking straightforward.
