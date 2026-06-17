//
//  EventManagementIntegrationTests.swift
//  LucaTests
//
//  Created by Kiro on 18/12/25.
//

import XCTest
@testable import Luca

/// Integration tests for event management interface
class EventManagementIntegrationTests: XCTestCase {
    
    var eventViewModel: EventViewModel!
    var mockDataManager: MockDataManager!
    var mockNotificationManager: MockNotificationManager!
    
    override func setUp() {
        super.setUp()
        mockDataManager = MockDataManager()
        mockNotificationManager = MockNotificationManager()
        eventViewModel = EventViewModel(
            dataManager: mockDataManager,
            notificationManager: mockNotificationManager
        )
    }
    
    override func tearDown() {
        eventViewModel = nil
        mockDataManager = nil
        mockNotificationManager = nil
        super.tearDown()
    }
    
    // MARK: - Event Creation Tests
    
    func testEventCreation() async {
        // Given
        let lunarDate = LunarDate(year: 41, month: 1, day: 15)
        let event = Event(
            title: "Test Event",
            description: "Test Description",
            lunarDate: lunarDate,
            category: .personal,
            reminderSettings: [.sameDay]
        )
        
        // When
        await eventViewModel.createEvent(event)
        
        // Then
        XCTAssertTrue(mockDataManager.saveEventCalled)
        XCTAssertTrue(mockNotificationManager.scheduleReminderCalled)
        XCTAssertEqual(mockDataManager.savedEvent?.title, "Test Event")
    }
    
    func testEventUpdate() async {
        // Given
        let originalEvent = Event(
            title: "Original Title",
            description: "Original Description",
            lunarDate: LunarDate(year: 41, month: 1, day: 15),
            category: .personal
        )
        
        // Simulate existing event
        mockDataManager.events = [originalEvent]
        await eventViewModel.loadEvents()
        
        // Update the event
        originalEvent.title = "Updated Title"
        originalEvent.description = "Updated Description"
        
        // When
        await eventViewModel.updateEvent(originalEvent)
        
        // Then
        XCTAssertTrue(mockDataManager.updateEventCalled)
        XCTAssertTrue(mockNotificationManager.cancelAllRemindersCalled)
    }
    
    func testEventDeletion() async {
        // Given
        let event = Event(
            title: "Event to Delete",
            lunarDate: LunarDate(year: 41, month: 1, day: 15),
            category: .personal
        )
        
        // When
        await eventViewModel.deleteEvent(event)
        
        // Then
        XCTAssertTrue(mockDataManager.deleteEventCalled)
        XCTAssertTrue(mockNotificationManager.cancelAllRemindersCalled)
    }
    
    // MARK: - Event Validation Tests
    
    func testEventValidation() {
        // Test valid event
        let validEvent = Event(
            title: "Valid Event",
            lunarDate: LunarDate(year: 41, month: 1, day: 15),
            category: .personal
        )
        
        let validationErrors = eventViewModel.validateEvent(validEvent)
        XCTAssertTrue(validationErrors.isEmpty)
        
        // Test invalid event (empty title)
        let invalidEvent = Event(
            title: "",
            lunarDate: LunarDate(year: 41, month: 1, day: 15),
            category: .personal
        )
        
        let invalidValidationErrors = eventViewModel.validateEvent(invalidEvent)
        XCTAssertFalse(invalidValidationErrors.isEmpty)
        XCTAssertTrue(invalidValidationErrors.contains("Event title is required"))
    }
    
    // MARK: - Lunar Date Validation Tests
    
    func testLunarDateValidation() {
        // Test valid lunar date
        let validDate = LunarDate(year: 41, month: 6, day: 15)
        XCTAssertTrue(validDate.isValid())
        
        // Test invalid lunar date (invalid month)
        let invalidDate = LunarDate(year: 41, month: 13, day: 15)
        XCTAssertFalse(invalidDate.isValid())
        
        // Test invalid lunar date (invalid day)
        let invalidDayDate = LunarDate(year: 41, month: 6, day: 31)
        XCTAssertFalse(invalidDayDate.isValid())
    }
    

}

// MARK: - Mock Classes

class MockDataManager: DataManager {
    var events: [Event] = []
    var saveEventCalled = false
    var updateEventCalled = false
    var deleteEventCalled = false
    var savedEvent: Event?
    
    func saveEvent(_ event: Event) async throws {
        saveEventCalled = true
        savedEvent = event
        events.append(event)
    }

    func saveEvents(_ events: [Event]) async throws {
        self.events.append(contentsOf: events)
    }
    
    func fetchEvents(for dateRange: DateInterval) async throws -> [Event] {
        return events.filter { event in
            event.gregorianDate >= dateRange.start && event.gregorianDate <= dateRange.end
        }
    }
    
    func fetchAllEvents() async throws -> [Event] {
        return events
    }
    
    func deleteEvent(_ event: Event) async throws {
        deleteEventCalled = true
        events.removeAll { $0.id == event.id }
    }
    
    func updateEvent(_ event: Event) async throws {
        updateEventCalled = true
        if let index = events.firstIndex(where: { $0.id == event.id }) {
            events[index] = event
        }
    }
    
    func fetchEvents(for lunarDate: LunarDate) async throws -> [Event] {
        return events.filter { $0.lunarDate == lunarDate }
    }
    
    func getEventCount() async -> Int {
        return events.count
    }
    
    func clearAllEvents() async throws {
        events.removeAll()
    }
}

class MockNotificationManager: NotificationManager {
    var scheduleReminderCalled = false
    var cancelAllRemindersCalled = false
    
    func scheduleReminder(for event: Event, reminderType: ReminderType) async -> Bool {
        scheduleReminderCalled = true
        return true
    }
    
    func cancelReminder(for eventId: UUID, reminderType: ReminderType) {
        // Mock implementation
    }
    
    func updateReminders(for event: Event) async {
        // Mock implementation
    }
    
    func requestPermissions() async -> Bool {
        return true
    }
    
    func cancelAllReminders(for eventId: UUID) {
        cancelAllRemindersCalled = true
    }
}