import Foundation
import UserNotifications

// MARK: - NotificationService
// Single scheduled reminder at a user-chosen time.

final class NotificationService: NSObject, UNUserNotificationCenterDelegate {

    private let reminderID = "parksafe_reminder"

    override init() {
        super.init()
        UNUserNotificationCenter.current().delegate = self
    }

    // MARK: - Delegate

    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler handler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        handler([.banner, .sound, .badge])
    }

    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler handler: @escaping () -> Void
    ) {
        UNUserNotificationCenter.current().setBadgeCount(0) { _ in }
        handler()
    }

    // MARK: - Permission

    func requestPermission(completion: @escaping (Bool) -> Void) {
        UNUserNotificationCenter.current()
            .requestAuthorization(options: [.alert, .sound, .badge]) { granted, _ in
                DispatchQueue.main.async { completion(granted) }
            }
    }

    func checkPendingStatus(completion: @escaping (Bool) -> Void) {
        UNUserNotificationCenter.current().getPendingNotificationRequests { [self] requests in
            let active = requests.contains { $0.identifier == self.reminderID }
            DispatchQueue.main.async { completion(active) }
        }
    }

    // MARK: - Badge

    func resetBadge() {
        UNUserNotificationCenter.current().setBadgeCount(0) { _ in }
    }

    // MARK: - Schedule / Cancel

    func scheduleReminder(at date: Date) {
        cancelReminders()
        let interval = max(1, date.timeIntervalSinceNow)

        let content       = UNMutableNotificationContent()
        content.title     = NSLocalizedString("notif.alert.title", comment: "")
        content.body      = NSLocalizedString("notif.alert.body",  comment: "")
        content.sound     = .default
        content.badge     = 1

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: interval, repeats: false)
        let request  = UNNotificationRequest(identifier: reminderID, content: content, trigger: trigger)
        UNUserNotificationCenter.current().add(request) { error in
            if let error { print("⚠️ ParkSafe reminder scheduling failed: \(error)") }
        }
    }

    func cancelReminders() {
        UNUserNotificationCenter.current()
            .removePendingNotificationRequests(withIdentifiers: [reminderID])
    }
}
