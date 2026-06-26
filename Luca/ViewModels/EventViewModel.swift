//
//  EventViewModel.swift
//  Luca
//
//  Created by Kiro on 16/12/25.
//

import Foundation
import SwiftUI
import Combine

/// ViewModel for managing event operations
@MainActor
class EventViewModel: ObservableObject {
    @Published var events: [Event] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private let dataManager: DataManager
    private let notificationManager: NotificationManager
    
    init(dataManager: DataManager, notificationManager: NotificationManager) {
        self.dataManager = dataManager
        self.notificationManager = notificationManager
    }
    
    /// Load all events
    func loadEvents() async {
        isLoading = true
        errorMessage = nil
        
        do {
            let allEvents = try await dataManager.fetchAllEvents()
            events = allEvents
        } catch {
            errorMessage = error.localizedDescription
        }
        
        isLoading = false
    }
    
    private func postEventsChangedNotification() {
        NotificationCenter.default.post(name: .eventsDidChange, object: nil)
    }
    
    /// Create a new event
    func createEvent(_ event: Event) async {
        errorMessage = nil
        
        do {
            let errors = validateEvent(event)
            if !errors.isEmpty {
                errorMessage = errors.joined(separator: "\n")
                return
            }
            
            try await dataManager.saveEvent(event)
            
            if event.isEnabled {
                for reminderType in event.reminderSettings {
                    let success = await notificationManager.scheduleReminder(for: event, reminderType: reminderType)
                    if !success {
                        print("Warning: Failed to schedule \(reminderType.displayName) reminder for event: \(event.title)")
                    }
                }
            }
            
            await loadEvents()
        } catch {
            errorMessage = error.localizedDescription
        }
    }
    
    /// Update an existing event
    func updateEvent(_ event: Event) async {
        errorMessage = nil
        
        do {
            let errors = validateEvent(event)
            if !errors.isEmpty {
                errorMessage = errors.joined(separator: "\n")
                return
            }
            
            notificationManager.cancelAllReminders(for: event.id)
            try await dataManager.updateEvent(event)
            
            if event.isEnabled {
                let settings = UserDefaultsSettingsManager().loadSettings()
                let categoryAllowed: Bool = {
                    switch event.category {
                    case .cultural: return settings.culturalNotificationsEnabled
                    case .religious: return settings.religiousNotificationsEnabled
                    case .personal: return true
                    }
                }()
                
                for reminderType in event.reminderSettings where categoryAllowed {
                    let success = await notificationManager.scheduleReminder(for: event, reminderType: reminderType)
                    if !success {
                        print("Warning: Failed to schedule \(reminderType.displayName) reminder for updated event: \(event.title)")
                    }
                }
            }
            
            await loadEvents()
        } catch {
            errorMessage = error.localizedDescription
        }
    }
    
    /// Delete an event
    func deleteEvent(_ event: Event) async {
        isLoading = true
        errorMessage = nil
        
        do {
            notificationManager.cancelAllReminders(for: event.id)
            try await dataManager.deleteEvent(event)
            await loadEvents()
            postEventsChangedNotification()
        } catch {
            errorMessage = error.localizedDescription
        }
        
        isLoading = false
    }
    
    /// Disable an event (hide from calendar, disable notifications)
    func disableEvent(_ event: Event) async {
        isLoading = true
        errorMessage = nil
        
        do {
            let updatedEvent = event
            updatedEvent.isEnabled = false
            notificationManager.cancelAllReminders(for: updatedEvent.id)
            try await dataManager.updateEvent(updatedEvent)
            await loadEvents()
            postEventsChangedNotification()
        } catch {
            errorMessage = error.localizedDescription
        }
        
        isLoading = false
    }
    
    /// Enable a disabled event
    func enableEvent(_ event: Event) async {
        isLoading = true
        errorMessage = nil
        
        do {
            let updatedEvent = event
            updatedEvent.isEnabled = true
            try await dataManager.updateEvent(updatedEvent)
            
            let settings = UserDefaultsSettingsManager().loadSettings()
            let categoryAllowed: Bool = {
                switch updatedEvent.category {
                case .cultural: return settings.culturalNotificationsEnabled
                case .religious: return settings.religiousNotificationsEnabled
                case .personal: return true
                }
            }()
            
            for reminderType in updatedEvent.reminderSettings where categoryAllowed {
                let _ = await notificationManager.scheduleReminder(for: updatedEvent, reminderType: reminderType)
            }
            
            await loadEvents()
            postEventsChangedNotification()
        } catch {
            errorMessage = error.localizedDescription
        }
        
        isLoading = false
    }
    
    /// Toggle reminders for an event (quick on/off)
    func toggleReminders(for event: Event) async {
        errorMessage = nil
        
        do {
            // Create a copy with toggled reminders
            let updatedEvent = event
            if updatedEvent.reminderSettings.isEmpty {
                // Add default reminder
                updatedEvent.reminderSettings = [.oneDayBefore]
            } else {
                // Remove all reminders
                updatedEvent.reminderSettings = []
            }
            
            notificationManager.cancelAllReminders(for: updatedEvent.id)
            try await dataManager.updateEvent(updatedEvent)
            
            // Re-schedule if enabled
            if updatedEvent.isEnabled && !updatedEvent.reminderSettings.isEmpty {
                for reminderType in updatedEvent.reminderSettings {
                    let _ = await notificationManager.scheduleReminder(for: updatedEvent, reminderType: reminderType)
                }
            }
            
            await loadEvents()
        } catch {
            errorMessage = error.localizedDescription
        }
    }
    
    /// Validate event data
    func validateEvent(_ event: Event) -> [String] {
        var errors: [String] = []
        
        let trimmedTitle = event.title.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmedTitle.isEmpty {
            errors.append("Event title is required")
        } else if trimmedTitle.count > 100 {
            errors.append("Event title must be 100 characters or less")
        }
        
        if event.description.count > 500 {
            errors.append("Event description must be 500 characters or less")
        }
        
        if !event.lunarDate.isValid() {
            errors.append("Invalid lunar date")
        }
        
        let tenYearsAgo = Calendar.current.date(byAdding: .year, value: -10, to: Date()) ?? Date()
        if event.gregorianDate < tenYearsAgo {
            errors.append("Event date cannot be more than 10 years in the past")
        }
        
        let fiftyYearsFromNow = Calendar.current.date(byAdding: .year, value: 50, to: Date()) ?? Date()
        if event.gregorianDate > fiftyYearsFromNow {
            errors.append("Event date cannot be more than 50 years in the future")
        }
        
        return errors
    }
}
