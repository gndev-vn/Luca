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
            var allEvents = try await dataManager.fetchAllEvents()
            allEvents.append(contentsOf: generateCeremonyEvents())
            events = allEvents
        } catch {
            errorMessage = error.localizedDescription
        }
        
        isLoading = false
    }
    
    /// Generate virtual events for ceremonies not stored in Core Data
    private func generateCeremonyEvents() -> [Event] {
        let today = Date()
        let lunar = LunarDate.fromGregorian(today)
        let vietnameseMonths = ["Giêng", "Hai", "Ba", "Tư", "Năm", "Sáu", "Bảy", "Tám", "Chín", "Mười", "Mười Một", "Chạp"]
        
        let ceremonyMonth = lunar.month
        let ceremonyLunar = LunarDate(year: lunar.year, month: ceremonyMonth, day: 1, isLeapMonth: lunar.isLeapMonth)
        
        let event = Event(
            id: UUID(uuidString: "00000000-0000-0000-0000-0000000000c1")!,
            title: "Cúng Mồng Một",
            description: "Cúng Mồng Một (ngày cuối tháng và mồng 1) — lễ cúng đầu tháng, diễn ra vào tối ngày cuối tháng và cả ngày mồng 1 mỗi tháng âm lịch.",
            lunarDate: ceremonyLunar,
            category: .cultural,
            isPublicHoliday: false,
            recurrence: .monthly,
            duration: 1
        )
        return [event]
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
            
            for reminderType in event.reminderSettings {
                let success = await notificationManager.scheduleReminder(for: event, reminderType: reminderType)
                if !success {
                    print("Warning: Failed to schedule \(reminderType.displayName) reminder for event: \(event.title)")
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
            
            for reminderType in event.reminderSettings {
                let success = await notificationManager.scheduleReminder(for: event, reminderType: reminderType)
                if !success {
                    print("Warning: Failed to schedule \(reminderType.displayName) reminder for updated event: \(event.title)")
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
        } catch {
            errorMessage = error.localizedDescription
        }
        
        isLoading = false
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
