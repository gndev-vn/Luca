//
//  DataManager.swift
//  Luca
//
//  Created by Kiro on 16/12/25.
//

import Foundation
import CoreData
import SwiftUI

/// Protocol for managing data persistence operations
protocol DataManager {
    /// Save an event to persistent storage
    /// - Parameter event: The event to save
    /// - Throws: DataManagerError if the operation fails
    func saveEvent(_ event: Event) async throws
    
    /// Save multiple events in a single batch operation
    /// - Parameter events: The events to save
    /// - Throws: DataManagerError if the operation fails
    func saveEvents(_ events: [Event]) async throws
    
    /// Fetch events within a specific date range
    /// - Parameter dateRange: The date range to fetch events for
    /// - Returns: Array of events within the specified range
    /// - Throws: DataManagerError if the operation fails
    func fetchEvents(for dateRange: DateInterval) async throws -> [Event]
    
    /// Fetch all events
    /// - Returns: Array of all events
    /// - Throws: DataManagerError if the operation fails
    func fetchAllEvents() async throws -> [Event]
    
    /// Delete an event from persistent storage
    /// - Parameter event: The event to delete
    /// - Throws: DataManagerError if the operation fails
    func deleteEvent(_ event: Event) async throws
    
    /// Delete all events whose titles are in the given set
    /// - Parameter titles: Set of titles to delete
    /// - Throws: DataManagerError if the operation fails
    func deleteEvents(withTitles titles: Set<String>) async throws
    
    /// Update an existing event in persistent storage
    /// - Parameter event: The event to update
    /// - Throws: DataManagerError if the operation fails
    func updateEvent(_ event: Event) async throws
    
    /// Fetch events for a specific lunar date
    /// - Parameter lunarDate: The lunar date to fetch events for
    /// - Returns: Array of events for the specified lunar date
    /// - Throws: DataManagerError if the operation fails
    func fetchEvents(for lunarDate: LunarDate) async throws -> [Event]
    
    /// Get the total count of events
    /// - Returns: Total number of events
    func getEventCount() async -> Int
    
    /// Clear all events (for testing or reset purposes)
    /// - Throws: DataManagerError if the operation fails
    func clearAllEvents() async throws
}

// MARK: - Default Implementation

extension DataManager {
    func deleteEvents(withTitles titles: Set<String>) async throws {
        let allEvents = try await fetchAllEvents()
        for event in allEvents where titles.contains(event.title) {
            try await deleteEvent(event)
        }
    }
}

/// Errors that can occur during data management operations
enum DataManagerError: Error, LocalizedError {
    case saveError(String)
    case fetchError(String)
    case deleteError(String)
    case updateError(String)
    case notFound(String)
    case corruptedData(String)
    case storageUnavailable
    
    var errorDescription: String? {
        switch self {
        case .saveError(let message):
            return "Failed to save data: \(message)"
        case .fetchError(let message):
            return "Failed to fetch data: \(message)"
        case .deleteError(let message):
            return "Failed to delete data: \(message)"
        case .updateError(let message):
            return "Failed to update data: \(message)"
        case .notFound(let message):
            return "Data not found: \(message)"
        case .corruptedData(let message):
            return "Data is corrupted: \(message)"
        case .storageUnavailable:
            return "Storage is unavailable"
        }
    }
}

/// User settings management
protocol SettingsManager {
    /// Save user settings
    /// - Parameter settings: The settings to save
    func saveSettings(_ settings: UserSettings)
    
    /// Load user settings
    /// - Returns: The current user settings
    func loadSettings() -> UserSettings
    
    /// Reset settings to default values
    func resetToDefaults()
}

/// Core Data implementation of DataManager
@MainActor
class CoreDataManager: DataManager {
    private let coreDataStack: CoreDataStack
    
    init(coreDataStack: CoreDataStack? = nil) {
        self.coreDataStack = coreDataStack ?? CoreDataStack.shared
    }
    
    // MARK: - Event Management
    
    func saveEvent(_ event: Event) async throws {
        let context = coreDataStack.context
        
        do {
            // Check if event already exists
            let fetchRequest: NSFetchRequest<EventEntity> = EventEntity.fetchRequest()
            fetchRequest.predicate = NSPredicate(format: "id == %@", event.id as CVarArg)
            
            let existingEntities = try context.fetch(fetchRequest)
            
            let entity: EventEntity
            if let existingEntity = existingEntities.first {
                entity = existingEntity
            } else {
                entity = EventEntity(context: context)
            }
            
            // Update entity with event data
            event.updateEntity(entity)
            
            // Handle reminders
            try await updateReminders(for: entity, with: event.reminderSettings, in: context)
            
            // Save context
            try context.save()
            
        } catch {
            throw DataManagerError.saveError("Failed to save event '\(event.title)': \(error.localizedDescription)")
        }
    }
    
    func saveEvents(_ events: [Event]) async throws {
        let context = coreDataStack.context
        
        do {
            for event in events {
                let fetchRequest: NSFetchRequest<EventEntity> = EventEntity.fetchRequest()
                fetchRequest.predicate = NSPredicate(format: "id == %@", event.id as CVarArg)
                
                let existingEntities = try context.fetch(fetchRequest)
                
                let entity: EventEntity
                if let existingEntity = existingEntities.first {
                    entity = existingEntity
                } else {
                    entity = EventEntity(context: context)
                }
                
                event.updateEntity(entity)
            }
            
            try context.save()
        } catch {
            throw DataManagerError.saveError("Failed to save \(events.count) events: \(error.localizedDescription)")
        }
    }
    
    func fetchEvents(for dateRange: DateInterval) async throws -> [Event] {
        let context = coreDataStack.context
        
        do {
            let fetchRequest: NSFetchRequest<EventEntity> = EventEntity.fetchRequest()
            fetchRequest.predicate = NSPredicate(
                format: "gregorianDate >= %@ AND gregorianDate <= %@",
                dateRange.start as NSDate,
                dateRange.end as NSDate
            )
            fetchRequest.sortDescriptors = [NSSortDescriptor(key: "gregorianDate", ascending: true)]
            
            let entities = try context.fetch(fetchRequest)
            return entities.map { Event.fromEntity($0) }
            
        } catch {
            throw DataManagerError.fetchError("Failed to fetch events for date range: \(error.localizedDescription)")
        }
    }
    
    func fetchAllEvents() async throws -> [Event] {
        let context = coreDataStack.context
        
        do {
            let fetchRequest: NSFetchRequest<EventEntity> = EventEntity.fetchRequest()
            fetchRequest.sortDescriptors = [NSSortDescriptor(key: "gregorianDate", ascending: true)]
            
            let entities = try context.fetch(fetchRequest)
            return entities.map { Event.fromEntity($0) }
            
        } catch {
            throw DataManagerError.fetchError("Failed to fetch all events: \(error.localizedDescription)")
        }
    }
    
    func deleteEvent(_ event: Event) async throws {
        let context = coreDataStack.context
        
        do {
            let fetchRequest: NSFetchRequest<EventEntity> = EventEntity.fetchRequest()
            fetchRequest.predicate = NSPredicate(format: "id == %@", event.id as CVarArg)
            
            let entities = try context.fetch(fetchRequest)
            
            guard let entity = entities.first else {
                throw DataManagerError.notFound("Event with ID \(event.id) not found")
            }
            
            context.delete(entity)
            try context.save()
            
        } catch let error as DataManagerError {
            throw error
        } catch {
            throw DataManagerError.deleteError("Failed to delete event '\(event.title)': \(error.localizedDescription)")
        }
    }
    
    func updateEvent(_ event: Event) async throws {
        try await saveEvent(event)
    }
    
    func fetchEvents(for lunarDate: LunarDate) async throws -> [Event] {
        let context = coreDataStack.context
        
        do {
            let fetchRequest: NSFetchRequest<EventEntity> = EventEntity.fetchRequest()
            fetchRequest.predicate = NSPredicate(
                format: "lunarYear == %d AND lunarMonth == %d AND lunarDay == %d AND isLeapMonth == %@",
                lunarDate.year,
                lunarDate.month,
                lunarDate.day,
                NSNumber(value: lunarDate.isLeapMonth)
            )
            fetchRequest.sortDescriptors = [NSSortDescriptor(key: "title", ascending: true)]
            
            let entities = try context.fetch(fetchRequest)
            return entities.map { Event.fromEntity($0) }
            
        } catch {
            throw DataManagerError.fetchError("Failed to fetch events for lunar date: \(error.localizedDescription)")
        }
    }
    
    func getEventCount() async -> Int {
        let context = coreDataStack.context
        
        do {
            let fetchRequest: NSFetchRequest<EventEntity> = EventEntity.fetchRequest()
            return try context.count(for: fetchRequest)
            
        } catch {
            return 0
        }
    }
    
    func clearAllEvents() async throws {
        let context = coreDataStack.context
        
        do {
            let fetchRequest: NSFetchRequest<NSFetchRequestResult> = EventEntity.fetchRequest()
            let deleteRequest = NSBatchDeleteRequest(fetchRequest: fetchRequest)
            
            try context.execute(deleteRequest)
            try context.save()
            
        } catch {
            throw DataManagerError.deleteError("Failed to clear all events: \(error.localizedDescription)")
        }
    }
    
    // MARK: - Private Helper Methods
    
    private func updateReminders(for eventEntity: EventEntity, with reminderTypes: [ReminderType], in context: NSManagedObjectContext) async throws {
        // Remove existing reminders
        if let existingReminders = eventEntity.reminders {
            for reminder in existingReminders {
                context.delete(reminder as! NSManagedObject)
            }
        }
        
        // Add new reminders
        for reminderType in reminderTypes {
            let reminderEntity = ReminderEntity(context: context)
            reminderEntity.id = UUID()
            reminderEntity.type = reminderType.rawValue
            reminderEntity.isActive = true
            reminderEntity.event = eventEntity
            
            // Calculate scheduled date based on reminder type and event's Gregorian date
            let gregorianDate = eventEntity.gregorianDate ?? Date()
            switch reminderType {
            case .onDay:
                reminderEntity.scheduledDate = gregorianDate
            case .oneDayBefore:
                reminderEntity.scheduledDate = Calendar.current.date(byAdding: .day, value: -1, to: gregorianDate)
            case .twoDaysBefore:
                reminderEntity.scheduledDate = Calendar.current.date(byAdding: .day, value: -2, to: gregorianDate)
            case .threeDaysBefore:
                reminderEntity.scheduledDate = Calendar.current.date(byAdding: .day, value: -3, to: gregorianDate)
            }
        }
    }
}

/// UserDefaults implementation of SettingsManager
class UserDefaultsSettingsManager: SettingsManager {
    private let userDefaults: UserDefaults
    private let settingsKey = "LucaUserSettings"
    
    init(userDefaults: UserDefaults = .standard) {
        self.userDefaults = userDefaults
    }
    
    func saveSettings(_ settings: UserSettings) {
        do {
            let data = try JSONEncoder().encode(settings)
            userDefaults.set(data, forKey: settingsKey)
        } catch {
            print("Failed to save settings: \(error)")
        }
    }
    
    func loadSettings() -> UserSettings {
        guard let data = userDefaults.data(forKey: settingsKey) else {
            return UserSettings.default
        }
        
        do {
            return try JSONDecoder().decode(UserSettings.self, from: data)
        } catch {
            print("Failed to load settings: \(error)")
            return UserSettings.default
        }
    }
    
    func resetToDefaults() {
        userDefaults.removeObject(forKey: settingsKey)
    }
}

/// User settings structure
struct UserSettings: Codable {
    var preferredTheme: Theme
    var notificationsEnabled: Bool
    var culturalNotificationsEnabled: Bool
    var religiousNotificationsEnabled: Bool
    var firstLaunch: Bool
    var hasCompletedOnboarding: Bool
    var hasSeededPublicHolidays: Bool

    enum CodingKeys: String, CodingKey {
        case preferredTheme
        case notificationsEnabled
        case culturalNotificationsEnabled
        case religiousNotificationsEnabled
        case firstLaunch
        case hasCompletedOnboarding
        case hasSeededPublicHolidays
    }
    
    enum Theme: String, CaseIterable, Codable {
        case system = "system"
        case light = "light"
        case dark = "dark"
    }

    init(
        preferredTheme: Theme,
        notificationsEnabled: Bool,
        culturalNotificationsEnabled: Bool = true,
        religiousNotificationsEnabled: Bool = true,
        firstLaunch: Bool,
        hasCompletedOnboarding: Bool,
        hasSeededPublicHolidays: Bool = false
    ) {
        self.preferredTheme = preferredTheme
        self.notificationsEnabled = notificationsEnabled
        self.culturalNotificationsEnabled = culturalNotificationsEnabled
        self.religiousNotificationsEnabled = religiousNotificationsEnabled
        self.firstLaunch = firstLaunch
        self.hasCompletedOnboarding = hasCompletedOnboarding
        self.hasSeededPublicHolidays = hasSeededPublicHolidays
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        preferredTheme = try container.decodeIfPresent(Theme.self, forKey: .preferredTheme) ?? .system
        notificationsEnabled = try container.decodeIfPresent(Bool.self, forKey: .notificationsEnabled) ?? true
        culturalNotificationsEnabled = try container.decodeIfPresent(Bool.self, forKey: .culturalNotificationsEnabled) ?? true
        religiousNotificationsEnabled = try container.decodeIfPresent(Bool.self, forKey: .religiousNotificationsEnabled) ?? true
        firstLaunch = try container.decodeIfPresent(Bool.self, forKey: .firstLaunch) ?? true
        hasCompletedOnboarding = try container.decodeIfPresent(Bool.self, forKey: .hasCompletedOnboarding) ?? false
        hasSeededPublicHolidays = try container.decodeIfPresent(Bool.self, forKey: .hasSeededPublicHolidays) ?? false
    }
    
    static let `default` = UserSettings(
        preferredTheme: .system,
        notificationsEnabled: true,
        firstLaunch: true,
        hasCompletedOnboarding: false,
        hasSeededPublicHolidays: false
    )
}

/// Default implementation of DataManager using Core Data
typealias DefaultDataManager = CoreDataManager

// MARK: - Theme Extensions

extension UserSettings.Theme {
    var localizedDisplayName: String {
        switch self {
        case .system: return String.localized(.themeSystem)
        case .light: return String.localized(.themeLight)
        case .dark: return String.localized(.themeDark)
        }
    }

    var iconName: String {
        switch self {
        case .system: return "gear"
        case .light: return "sun.max"
        case .dark: return "moon"
        }
    }

    var color: Color {
        switch self {
        case .system: return .blue
        case .light: return .orange
        case .dark: return .purple
        }
    }
}
