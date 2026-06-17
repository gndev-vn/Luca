import Foundation
import UserNotifications

// MARK: - Mock Services for SwiftUI Previews

class MockNotificationManager: NotificationManager {
    func hasPermissions() async -> Bool { return true }
    func getPendingNotifications() async -> [UNNotificationRequest] { return [] }
    func handleNotificationResponse(_ response: UNNotificationResponse) async {}
    func scheduleReminder(for event: Event, reminderType: ReminderType) async -> Bool { return true }
    func cancelReminder(for eventId: UUID, reminderType: ReminderType) {}
    func updateReminders(for event: Event) async {}
    func requestPermissions() async -> Bool { return true }
    func cancelAllReminders(for eventId: UUID) {}
}
