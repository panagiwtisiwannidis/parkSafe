import Foundation
import UserNotifications

// MARK: - NotificationService
// Manages scheduling and cancelling of local notifications.
// No UI, no location logic, no persistence.

// HIGH FIX: NSObject + UNUserNotificationCenterDelegate so notifications
// show as banners even when the app is in the foreground.
final class NotificationService: NSObject, UNUserNotificationCenterDelegate {

    // MARK: - Constants
    private enum C {
        static let idPrefix   = "parksafe_reminder_"
        static let totalHours = 12
    }

    // MARK: - Init

    override init() {
        super.init()
        // Register as delegate so foreground notifications display correctly.
        UNUserNotificationCenter.current().delegate = self
    }

    // MARK: - UNUserNotificationCenterDelegate

    /// Show banner + play sound even when app is in foreground.
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler handler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        handler([.banner, .sound, .badge])
    }

    /// Clear badge when user taps the notification.
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
        UNUserNotificationCenter.current().getPendingNotificationRequests { requests in
            let active = requests.contains { $0.identifier.hasPrefix(C.idPrefix) }
            DispatchQueue.main.async { completion(active) }
        }
    }

    // MARK: - Badge Reset

    /// Call when app becomes active to clear the badge number.
    func resetBadge() {
        UNUserNotificationCenter.current().setBadgeCount(0) { _ in }
    }

    // MARK: - Schedule / Cancel

    /// Schedules hourly reminders for the next `totalHours` hours.
    func scheduleHourlyReminders() {
        cancelReminders()

        for hour in 1...C.totalHours {
            // Create a fresh content instance per request (defensive copy)
            let content = UNMutableNotificationContent()
            content.title = NSLocalizedString("notif.alert.title", comment: "")
            content.body  = NSLocalizedString("notif.alert.body",  comment: "")
            content.sound = .default
            content.badge = (hour) as NSNumber  // increments per hour

            let trigger = UNTimeIntervalNotificationTrigger(
                timeInterval: Double(hour) * 3600,
                repeats: false
            )
            let request = UNNotificationRequest(
                identifier: "\(C.idPrefix)\(hour)",
                content: content,
                trigger: trigger
            )
            // HIGH FIX: handle scheduling errors
            UNUserNotificationCenter.current().add(request) { error in
                if let error {
                    print("⚠️ ParkSafe: notification scheduling failed for hour \(hour): \(error.localizedDescription)")
                }
            }
        }
    }

    /// Removes all pending parking reminders.
    func cancelReminders() {
        let ids = (1...C.totalHours).map { "\(C.idPrefix)\($0)" }
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: ids)
    }
}
