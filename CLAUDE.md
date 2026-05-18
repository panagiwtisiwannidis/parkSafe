# ParkSafe — Claude Code Guide

iOS parking reminder app built with SwiftUI + MVVM + Services.

---

## Architecture

**MVVM + Services pattern.** One ViewModel owns all business logic and injects all services. Views are purely declarative — they read `@Published` state and call intent methods.

```
Views → ParkingViewModel → Services → System APIs
                 ↓
           ParkingSpot (Model)
```

### Layer responsibilities

| Layer | Files | Rule |
|---|---|---|
| Model | `Models/ParkingSpot.swift` | Pure `Codable` data struct. No UI, no logic. |
| ViewModel | `ViewModels/ParkingViewModel.swift` | Single source of truth. `@MainActor`. Owns all services privately. |
| Services | `Services/*.swift` | Each does exactly one thing. Injected via init, independently testable. |
| Views | `Views/**/*.swift` | Read state, call intents. Zero business logic. Never access services directly. |

### Key invariants

- Views **never** import or instantiate services — only the ViewModel does.
- The ViewModel is `@MainActor` — all `@Published` mutations are thread-safe.
- Services are injected via `init(...)`, making them mockable in tests.
- `ParkingApp` injects the ViewModel as `@EnvironmentObject` at the root.

---

## Folder Structure

```
ParkSafe/
├── App/
│   ├── ParkingApp.swift          # @main entry point, injects ViewModel
│   ├── Info.plist                # Location + URL scheme permissions
│   └── PrivacyInfo.xcprivacy
│
├── Models/
│   └── ParkingSpot.swift         # Codable struct: coordinate, timestamp, address, note
│
├── ViewModels/
│   └── ParkingViewModel.swift    # All intents + @Published state + Combine bindings
│
├── Services/
│   ├── LocationService.swift     # CLLocationManager → Combine publisher
│   ├── NotificationService.swift # UNUserNotificationCenter, hourly reminders, badge reset
│   ├── NavigationService.swift   # Deep links → Apple Maps / Google Maps
│   └── PersistenceService.swift  # UserDefaults JSON encode/decode
│
├── Views/
│   ├── Onboarding/
│   │   └── OnboardingView.swift  # 4-step permission onboarding flow
│   ├── Main/
│   │   ├── ContentView.swift     # Router: onboarding vs main screen
│   │   ├── MainView.swift        # Root screen + AppBackground gradient
│   │   ├── HeaderView.swift
│   │   ├── SavedSpotCard.swift   # Map annotation + address + distance chip
│   │   ├── NavigationCard.swift  # Apple Maps / Google Maps buttons
│   │   ├── NotificationToggleCard.swift
│   │   └── ActionViews.swift     # EmptyStateView, SaveSpotButton, ClearSpotButton
│   └── Components/
│       └── Components.swift      # ParkingPinView, InfoChip, PermissionBadgeView,
│                                 # SectionLabel, cardStyle() modifier
│
└── Resources/
    ├── Strings.swift             # Type-safe NSLocalizedString wrappers (enum Strings)
    ├── en.lproj/Localizable.strings
    ├── de.lproj/Localizable.strings
    ├── el.lproj/Localizable.strings
    ├── es.lproj/Localizable.strings
    └── fr.lproj/Localizable.strings
```

---

## Localization

All user-facing strings go through `Strings.swift` — never use raw string literals in views.

```swift
// Correct
Text(Strings.Button.save)

// Wrong
Text("Save Parking Spot")
```

`Strings.swift` wraps `NSLocalizedString` with a private helper `L(_:)`. iOS automatically resolves the active `.lproj` at runtime. Supported locales: **en, de, el, es, fr**.

---

## Xcode Setup (new project)

1. iOS App → SwiftUI interface → Swift language → minimum iOS 16
2. Recreate the folder groups above and add all files
3. Merge `App/Info.plist` keys:
   - `NSLocationWhenInUseUsageDescription`
   - `LSApplicationQueriesSchemes` → `["comgooglemaps"]`
4. Add color assets in `Assets.xcassets`:
   - `BGTop` → `#0D1B2A`
   - `BGBottom` → `#1A2E45`
   - `AccentColor` → `#3B82F6`
5. Signing & Capabilities → enable **Location When In Use**
6. Build on a **real device** — GPS is unreliable in Simulator

---

## Services Quick Reference

| Service | System API | Key methods |
|---|---|---|
| `LocationService` | `CLLocationManager` | `requestPermission()`, `requestOneTimeLocation()` |
| `NotificationService` | `UNUserNotificationCenter` | `scheduleHourlyReminders()`, `cancelReminders()`, `resetBadge()` |
| `NavigationService` | `UIApplication.open(_:)` | `openAppleMaps(to:)`, `openGoogleMaps(to:)` |
| `PersistenceService` | `UserDefaults` | `saveSpot(_:)`, `loadSpot()`, `clearSpot()` |

---

## Testing

Services are injected — pass mocks at the ViewModel init:

```swift
let vm = ParkingViewModel(
    locationService: MockLocationService(),
    persistenceService: MockPersistenceService()
)
```

No UI tests currently exist. Unit tests should target ViewModel intents and Service methods in isolation.

---

## Coding Conventions

- `@MainActor` on the ViewModel; no explicit `DispatchQueue.main` in views.
- Combine `sink` subscriptions stored in `cancellables: Set<AnyCancellable>`.
- Error messages surface through `ParkingViewModel.errorMessage: String?` — views observe this via `@Published`.
- Badge management: `resetBadge()` called in `ParkingApp.onChange(scenePhase:)` when app becomes `.active`.
- Notifications are scheduled for 12 hourly slots (`parksafe_reminder_1` … `parksafe_reminder_12`).
