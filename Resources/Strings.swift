import Foundation

// MARK: - Strings
// Type-safe wrapper around NSLocalizedString.
// Views import this and use e.g. Strings.button.save instead of raw keys.
// iOS automatically picks the right .lproj based on device language.

enum Strings {

    // MARK: - Header
    enum Header {
        static var subtitleSaved: String { L("header.subtitle.saved") }
        static var subtitleEmpty: String { L("header.subtitle.empty") }
    }

    // MARK: - Empty State
    enum Empty {
        static var title:       String { L("empty.title") }
        static var description: String { L("empty.description") }
    }

    // MARK: - Buttons
    enum Button {
        static var save:  String { L("button.save") }
        static var saving: String { L("button.saving") }
        static var clear: String { L("button.clear") }
    }

    // MARK: - Navigation Card
    enum Nav {
        static var sectionTitle:   String { L("nav.section.title") }
        static var appleTitle:     String { L("nav.apple.title") }
        static var appleSubtitle:  String { L("nav.apple.subtitle") }
        static var googleTitle:    String { L("nav.google.title") }
        static var googleSubtitle: String { L("nav.google.subtitle") }
    }

    // MARK: - Notifications
    enum Notif {
        static var title:           String { L("notif.title") }
        static var subtitleActive:  String { L("notif.subtitle.active") }
        static var subtitleInactive: String { L("notif.subtitle.inactive") }
        static var alertTitle:      String { L("notif.alert.title") }
        static var alertBody:       String { L("notif.alert.body") }
    }

    // MARK: - Distance Chips
    enum Chip {
        static func metersAway(_ m: Double) -> String {
            String(format: L("chip.m_away %@"), m)
        }
        static func kmAway(_ km: Double) -> String {
            String(format: L("chip.km_away %@"), km)
        }
        static func distanceLabel(meters: Double) -> String {
            meters < 1000 ? metersAway(meters) : kmAway(meters / 1000)
        }
    }

    // MARK: - Clear Confirmation
    enum Clear {
        static var confirmTitle:   String { L("clear.confirm.title") }
        static var confirmMessage: String { L("clear.confirm.message") }
        static var action:         String { L("clear.confirm.action") }
        static var cancel:         String { L("clear.confirm.cancel") }
    }

    // MARK: - Location Errors & Alerts
    enum Location {
        static var deniedTitle:    String { L("location.denied.title") }
        static var deniedMessage:  String { L("location.denied.message") }
        static var deniedSettings: String { L("location.denied.settings") }
        static var deniedCancel:   String { L("location.denied.cancel") }
        static var errorNoLocation: String { L("location.error.no_location") }
        static var errorDenied:    String { L("location.error.denied") }
    }

    // MARK: - Onboarding
    enum Onboarding {
        static var skip: String { L("onboarding.skip") }

        struct Step {
            let title: String
            let body:  String
            let cta:   String
        }

        static let steps: [Step] = [
            Step(title: L("onboarding.step0.title"), body: L("onboarding.step0.body"), cta: L("onboarding.step0.cta")),
            Step(title: L("onboarding.step1.title"), body: L("onboarding.step1.body"), cta: L("onboarding.step1.cta")),
            Step(title: L("onboarding.step2.title"), body: L("onboarding.step2.body"), cta: L("onboarding.step2.cta")),
            Step(title: L("onboarding.step3.title"), body: L("onboarding.step3.body"), cta: L("onboarding.step3.cta")),
        ]
    }

    // MARK: - History
    enum History {
        static var title:                String { L("history.title") }
        static var empty:                String { L("history.empty") }
        static var clearAll:             String { L("history.clear_all") }
        static var clearConfirmTitle:    String { L("history.clear.confirm.title") }
        static var clearConfirmMessage:  String { L("history.clear.confirm.message") }
        static var clearConfirmAction:   String { L("history.clear.confirm.action") }
        static var restoreAction:        String { L("history.restore") }
    }

    // MARK: - Map Accessibility
    enum Map {
        static var pinLabel: String { L("map.pin.label") }
        static var pinHint:  String { L("map.pin.hint") }
    }

    // MARK: - Permission Badges
    enum Permission {
        static var locationTitle:       String { L("permission.location.title") }
        static var locationDescription: String { L("permission.location.description") }
        static var notifTitle:          String { L("permission.notif.title") }
        static var notifDescription:    String { L("permission.notif.description") }
    }
}

// MARK: - Private helper
private func L(_ key: String) -> String {
    NSLocalizedString(key, comment: "")
}
