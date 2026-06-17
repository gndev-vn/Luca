//
//  NotificationManager.swift
//  Luca
//
//  Created by Kiro on 16/12/25.
//

import Foundation
import UserNotifications

/// Protocol for managing iOS notifications and reminders
protocol NotificationManager {
    /// Schedule a reminder notification for an event
    /// - Parameters:
    ///   - event: The event to schedule a reminder for
    ///   - reminderType: The type of reminder (same day, 1 day before, etc.)
    /// - Returns: True if the reminder was scheduled successfully, false otherwise
    func scheduleReminder(for event: Event, reminderType: ReminderType) async -> Bool
    
    /// Cancel a specific reminder for an event
    /// - Parameters:
    ///   - eventId: The ID of the event
    ///   - reminderType: The type of reminder to cancel
    func cancelReminder(for eventId: UUID, reminderType: ReminderType)
    
    /// Update all reminders for an event (cancel old ones and schedule new ones)
    /// - Parameter event: The event to update reminders for
    func updateReminders(for event: Event) async
    
    /// Request notification permissions from the user
    /// - Returns: True if permissions were granted, false otherwise
    func requestPermissions() async -> Bool
    
    /// Check if notification permissions are granted
    /// - Returns: True if permissions are granted, false otherwise
    func hasPermissions() async -> Bool
    
    /// Cancel all reminders for a specific event
    /// - Parameter eventId: The ID of the event
    func cancelAllReminders(for eventId: UUID)
    
    /// Get all pending notifications
    /// - Returns: Array of pending notification requests
    func getPendingNotifications() async -> [UNNotificationRequest]
    
    /// Handle notification response when user interacts with a notification
    /// - Parameter response: The notification response
    func handleNotificationResponse(_ response: UNNotificationResponse) async
}

/// Concrete implementation of NotificationManager for iOS
class DefaultNotificationManager: NotificationManager {
    
    // MARK: - Private Properties
    
    /// The notification center for managing notifications
    private let notificationCenter = UNUserNotificationCenter.current()
    
    /// Lunar calendar service for date conversions
    private let lunarCalendarService: LunarCalendarService
    
    // MARK: - Initialization
    
    init(lunarCalendarService: LunarCalendarService = DefaultLunarCalendarService()) {
        self.lunarCalendarService = lunarCalendarService
        setupNotificationCategories()
    }
    
    // MARK: - NotificationManager Implementation
    
    func scheduleReminder(for event: Event, reminderType: ReminderType) async -> Bool {
        // Check permissions first
        guard await hasPermissions() else {
            print("Notification permissions not granted")
            return false
        }
        
        // Calculate the notification date based on reminder type
        let notificationDate = calculateNotificationDate(for: event, reminderType: reminderType)
        
        // Don't schedule notifications for past dates
        guard notificationDate > Date() else {
            print("Cannot schedule notification for past date: \(notificationDate)")
            return false
        }
        
        // Create notification content
        let content = LunarNotificationContent.buildContent(for: event, reminderType: reminderType)
        
        // Create notification identifier
        let identifier = createNotificationIdentifier(eventId: event.id, reminderType: reminderType)
        
        // Create date trigger
        let calendar = Calendar.current
        let components = calendar.dateComponents([.year, .month, .day, .hour, .minute], from: notificationDate)
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
        
        // Create notification request
        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)
        
        do {
            try await notificationCenter.add(request)
            print("Successfully scheduled notification for event: \(event.title) at \(notificationDate)")
            return true
        } catch {
            print("Failed to schedule notification: \(error)")
            return false
        }
    }
    
    func cancelReminder(for eventId: UUID, reminderType: ReminderType) {
        let identifier = createNotificationIdentifier(eventId: eventId, reminderType: reminderType)
        notificationCenter.removePendingNotificationRequests(withIdentifiers: [identifier])
        print("Cancelled notification with identifier: \(identifier)")
    }
    
    func updateReminders(for event: Event) async {
        // Cancel all existing reminders for this event
        cancelAllReminders(for: event.id)
        
        // Schedule new reminders based on current settings
        for reminderType in event.reminderSettings {
            let success = await scheduleReminder(for: event, reminderType: reminderType)
            if !success {
                print("Failed to schedule \(reminderType.displayName) reminder for event: \(event.title)")
            }
        }
    }
    
    func requestPermissions() async -> Bool {
        do {
            let granted = try await notificationCenter.requestAuthorization(options: [.alert, .sound, .badge])
            print("Notification permissions granted: \(granted)")
            return granted
        } catch {
            print("Failed to request notification permissions: \(error)")
            return false
        }
    }
    
    func hasPermissions() async -> Bool {
        let settings = await notificationCenter.notificationSettings()
        return settings.authorizationStatus == .authorized
    }
    
    func cancelAllReminders(for eventId: UUID) {
        let identifiers = ReminderType.allCases.map { reminderType in
            createNotificationIdentifier(eventId: eventId, reminderType: reminderType)
        }
        notificationCenter.removePendingNotificationRequests(withIdentifiers: identifiers)
        print("Cancelled all reminders for event: \(eventId)")
    }
    
    func getPendingNotifications() async -> [UNNotificationRequest] {
        return await notificationCenter.pendingNotificationRequests()
    }
    
    func handleNotificationResponse(_ response: UNNotificationResponse) async {
        let userInfo = response.notification.request.content.userInfo
        
        guard let eventIdString = userInfo["eventId"] as? String,
              let eventId = UUID(uuidString: eventIdString),
              let reminderTypeString = userInfo["reminderType"] as? String,
              let reminderType = ReminderType(rawValue: reminderTypeString) else {
            print("Invalid notification response data")
            return
        }
        
        print("Handled notification response for event: \(eventId), reminder type: \(reminderType.displayName)")
        
        // Handle different action identifiers
        switch response.actionIdentifier {
        case UNNotificationDefaultActionIdentifier:
            // User tapped the notification
            print("User tapped notification for event: \(eventId)")
        case UNNotificationDismissActionIdentifier:
            // User dismissed the notification
            print("User dismissed notification for event: \(eventId)")
        case "VIEW_EVENT":
            // Custom action to view event details
            print("User wants to view event details: \(eventId)")
        case "SNOOZE":
            // Custom action to snooze reminder
            await snoozeReminder(eventId: eventId, reminderType: reminderType)
        default:
            print("Unknown notification action: \(response.actionIdentifier)")
        }
    }
    
    // MARK: - Private Helper Methods
    
    /// Calculate the notification date based on event date and reminder type
    /// - Parameters:
    ///   - event: The event to calculate notification date for
    ///   - reminderType: The type of reminder
    /// - Returns: The date when the notification should be triggered
    private func calculateNotificationDate(for event: Event, reminderType: ReminderType) -> Date {
        let eventDate = event.gregorianDate
        let calendar = Calendar.current
        
        guard let targetDate = calendar.date(byAdding: .day, value: reminderType.daysOffset, to: eventDate) else {
            return eventDate
        }
        var components = calendar.dateComponents([.year, .month, .day], from: targetDate)
        let timeComponents = calendar.dateComponents([.hour, .minute], from: event.notificationTime)
        components.hour = timeComponents.hour ?? 6
        components.minute = timeComponents.minute ?? 0
        return calendar.date(from: components) ?? targetDate
    }
    
    /// Create a unique notification identifier for an event and reminder type
    /// - Parameters:
    ///   - eventId: The event ID
    ///   - reminderType: The reminder type
    /// - Returns: Unique notification identifier
    private func createNotificationIdentifier(eventId: UUID, reminderType: ReminderType) -> String {
        return "lunar_event_\(eventId.uuidString)_\(reminderType.rawValue)"
    }
    
    /// Set up notification categories and actions
    private func setupNotificationCategories() {
        // Define custom actions
        let viewAction = UNNotificationAction(
            identifier: "VIEW_EVENT",
            title: "View Event",
            options: [.foreground]
        )
        
        let snoozeAction = UNNotificationAction(
            identifier: "SNOOZE",
            title: "Snooze 1 Hour",
            options: []
        )
        
        // Create category with actions
        let category = UNNotificationCategory(
            identifier: "LUNAR_EVENT",
            actions: [viewAction, snoozeAction],
            intentIdentifiers: [],
            options: [.customDismissAction]
        )
        
        // Register the category
        notificationCenter.setNotificationCategories([category])
    }
    
    /// Snooze a reminder by scheduling it again in 1 hour
    /// - Parameters:
    ///   - eventId: The event ID
    ///   - reminderType: The reminder type to snooze
    private func snoozeReminder(eventId: UUID, reminderType: ReminderType) async {
        // Calculate snooze time (1 hour from now)
        let snoozeDate = Calendar.current.date(byAdding: .hour, value: 1, to: Date()) ?? Date()
        
        // Create snooze notification content
        let content = UNMutableNotificationContent()
        content.title = "Snoozed Lunar Event Reminder"
        content.body = "This is your snoozed reminder"
        content.sound = .default
        content.categoryIdentifier = "LUNAR_EVENT"
        content.userInfo = [
            "eventId": eventId.uuidString,
            "reminderType": reminderType.rawValue,
            "isSnoozed": true
        ]
        
        // Create identifier for snoozed notification
        let identifier = "snoozed_\(createNotificationIdentifier(eventId: eventId, reminderType: reminderType))"
        
        // Create trigger for snooze time
        let calendar = Calendar.current
        let components = calendar.dateComponents([.year, .month, .day, .hour, .minute], from: snoozeDate)
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
        
        // Create and schedule the snoozed notification
        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)
        
        do {
            try await notificationCenter.add(request)
            print("Snoozed notification scheduled for: \(snoozeDate)")
        } catch {
            print("Failed to schedule snoozed notification: \(error)")
        }
    }
}

/// Notification content builder for lunar events
struct LunarNotificationContent {
    static func buildContent(for event: Event, reminderType: ReminderType) -> UNMutableNotificationContent {
        let content = UNMutableNotificationContent()
        
        // Format lunar date for display
        let lunarDateString = formatLunarDate(event.lunarDate)
        let gregorianDateString = formatGregorianDate(event.gregorianDate)
        
        // Build title and body based on reminder type and event type
        let daysText: String
        switch reminderType {
        case .onDay:
            daysText = "Today"
        case .oneDayBefore:
            daysText = "Tomorrow"
        case .twoDaysBefore:
            daysText = "in 2 days"
        case .threeDaysBefore:
            daysText = "in 3 days"
        }
        
        if event.isPublicHoliday {
            content.title = "🎉 Holiday \(daysText)"
            content.body = "\(event.title) (\(lunarDateString))"
        } else {
            content.title = "🌙 Event \(daysText)"
            content.body = "\(event.title) (\(lunarDateString))"
        }
        
        // Add subtitle with Gregorian date for reference
        content.subtitle = "Gregorian: \(gregorianDateString)"
        
        // Add event description if available
        if !event.description.isEmpty {
            content.body += "\n\(event.description)"
        }
        
        if event.soundEnabled {
            if let soundName = event.notificationSoundName, !soundName.isEmpty, soundName != "default" {
                content.sound = UNNotificationSound(named: UNNotificationSoundName(soundName))
            } else {
                content.sound = .default
            }
        } else {
            content.sound = nil
        }
        content.categoryIdentifier = "LUNAR_EVENT"
        content.badge = 1
        
        // Add custom data for handling notification responses
        content.userInfo = [
            "eventId": event.id.uuidString,
            "reminderType": reminderType.rawValue,
            "eventTitle": event.title,
            "isPublicHoliday": event.isPublicHoliday,
            "lunarDate": lunarDateString,
            "gregorianDate": gregorianDateString,
            "category": event.category.rawValue
        ]
        
        return content
    }
    
    /// Format lunar date for display in notifications
    /// - Parameter lunarDate: The lunar date to format
    /// - Returns: Formatted lunar date string
    private static func formatLunarDate(_ lunarDate: LunarDate) -> String {
        let leapIndicator = lunarDate.isLeapMonth ? "Nhuận " : ""
        return "Lunar \(lunarDate.traditionalYear)/\(leapIndicator)\(lunarDate.month)/\(lunarDate.day)"
    }
    
    /// Format Gregorian date for display in notifications
    /// - Parameter gregorianDate: The Gregorian date to format
    /// - Returns: Formatted Gregorian date string
    private static func formatGregorianDate(_ gregorianDate: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter.string(from: gregorianDate)
    }
}