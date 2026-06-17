//
//  MockServices.swift
//  LucaTests
//
//  Created by Kiro on 16/12/25.
//

import Foundation
@testable import Luca

/// Mock implementation of LunarCalendarService for testing
class MockLunarCalendarService: LunarCalendarService {
    var convertToLunarResult: LunarDate?
    var convertToGregorianResult: Date?
    var publicHolidays: [Event] = []
    var validateResult: Bool = true

    func convertToLunar(gregorian: Date) -> LunarDate {
        return convertToLunarResult ?? LunarDate(year: 2024, month: 1, day: 1, isLeapMonth: false)
    }

    func convertToGregorian(lunar: LunarDate) -> Date {
        return convertToGregorianResult ?? Date()
    }

    func getPublicHolidays(year: Int) -> [Event] {
        return publicHolidays
    }

    func validateLunarDate(_ date: LunarDate) -> Bool {
        return validateResult
    }

    func getCurrentLunarDate() -> LunarDate {
        return convertToLunarResult ?? LunarDate(year: 2024, month: 1, day: 1, isLeapMonth: false)
    }
}

/// Mock implementation of DataManager for testing
class MockDataManager: DataManager {
    var events: [Event] = []
    var shouldThrowError = false
    var errorToThrow: DataManagerError = .saveError("Mock error")

    func saveEvent(_ event: Event) async throws {
        if shouldThrowError {
            throw errorToThrow
        }
        events.append(event)
    }

    func saveEvents(_ events: [Event]) async throws {
        if shouldThrowError {
            throw errorToThrow
        }
        self.events.append(contentsOf: events)
    }

    func fetchEvents(for dateRange: DateInterval) async throws -> [Event] {
        if shouldThrowError {
            throw errorToThrow
        }
        return events.filter { event in
            return true
        }
    }

    func fetchAllEvents() async throws -> [Event] {
        if shouldThrowError {
            throw errorToThrow
        }
        return events
    }

    func deleteEvent(_ event: Event) async throws {
        if shouldThrowError {
            throw errorToThrow
        }
        events.removeAll { $0.id == event.id }
    }

    func updateEvent(_ event: Event) async throws {
        if shouldThrowError {
            throw errorToThrow
        }
        if let index = events.firstIndex(where: { $0.id == event.id }) {
            events[index] = event
        }
    }

    func fetchEvents(for lunarDate: LunarDate) async throws -> [Event] {
        if shouldThrowError {
            throw errorToThrow
        }
        return events.filter { $0.lunarDate == lunarDate }
    }

    func getEventCount() async -> Int {
        return events.count
    }

    func clearAllEvents() async throws {
        if shouldThrowError {
            throw errorToThrow
        }
        events.removeAll()
    }
}

/// Mock implementation of NotificationManager for testing
class MockNotificationManager: NotificationManager {
    var scheduledReminders: [(Event, ReminderType)] = []
    var cancelledReminders: [(UUID, ReminderType)] = []
    var hasPermissionsResult = true
    var requestPermissionsResult = true

    func scheduleReminder(for event: Event, reminderType: ReminderType) async -> Bool {
        scheduledReminders.append((event, reminderType))
        return true
    }

    func cancelReminder(for eventId: UUID, reminderType: ReminderType) {
        cancelledReminders.append((eventId, reminderType))
    }

    func updateReminders(for event: Event) async {
        cancelAllReminders(for: event.id)
        for reminderType in event.reminderSettings {
            await scheduleReminder(for: event, reminderType: reminderType)
        }
    }

    func requestPermissions() async -> Bool {
        return requestPermissionsResult
    }

    func hasPermissions() async -> Bool {
        return hasPermissionsResult
    }

    func cancelAllReminders(for eventId: UUID) {
        cancelledReminders.append(contentsOf: ReminderType.allCases.map { (eventId, $0) })
    }

    func getPendingNotifications() async -> [UNNotificationRequest] {
        return []
    }

    func handleNotificationResponse(_ response: UNNotificationResponse) async {
    }
}

/// Mock implementation of SettingsManager for testing
class MockSettingsManager: SettingsManager {
    var settings = UserSettings.default

    func saveSettings(_ settings: UserSettings) {
        self.settings = settings
    }

    func loadSettings() -> UserSettings {
        return settings
    }

    func resetToDefaults() {
        settings = UserSettings.default
    }
}
