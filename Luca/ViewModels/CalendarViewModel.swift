//
//  CalendarViewModel.swift
//  Luca
//
//  Created by Kiro on 16/12/25.
//

import Foundation
import SwiftUI
import Combine

/// ViewModel for managing calendar state and operations
@MainActor
class CalendarViewModel: ObservableObject {
    @Published var currentDate = Date()
    @Published var selectedDate: Date?
    @Published var events: [Event] = []
    @Published var publicHolidays: [Event] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var hasInitiallyLoaded = false

    private let lunarCalendarService: LunarCalendarService
    private let dataManager: DataManager
    private var loadingTask: Task<Void, Never>?
    private let calendar = Calendar.current

    private var allEvents: [Event] = []
    private var customEventsByDay: [Date: [Event]] = [:]
    private var holidayEventsByDay: [Date: [Event]] = [:]
    private var combinedEventsByDay: [Date: [Event]] = [:]

    /// Current lunar date for the displayed month
    var currentLunarDate: LunarDate? {
        return lunarCalendarService.convertToLunar(gregorian: currentDate)
    }

    init(lunarCalendarService: LunarCalendarService, dataManager: DataManager) {
        self.lunarCalendarService = lunarCalendarService
        self.dataManager = dataManager
        let today = lunarCalendarService.convertToLunar(gregorian: Date())
        let firstOfMonth = LunarDate(year: today.year, month: today.month, day: 1, isLeapMonth: today.isLeapMonth)
        self.currentDate = lunarCalendarService.convertToGregorian(lunar: firstOfMonth)
    }

    /// Load all events into memory — calendar grid computes occurrences dynamically
    func loadEvents() async {
        loadingTask?.cancel()

        loadingTask = Task { [weak self] in
            guard let self else { return }

            setLoading(true)

            do {
                let fetched = try await dataManager.fetchAllEvents()
                allEvents = fetched
                applyEvents(allEvents: fetched)
            } catch {
                await MainActor.run { self.errorMessage = error.localizedDescription }
            }

            setLoading(false)
        }

        await loadingTask?.value
    }

    // MARK: - Private Helpers

    @MainActor
    private func setLoading(_ loading: Bool) {
        isLoading = loading
        if loading { errorMessage = nil }
        if !loading { hasInitiallyLoaded = true }
    }

    @MainActor
    private func applyEvents(allEvents: [Event]) {
        publicHolidays = allEvents.filter { $0.isPublicHoliday && $0.isEnabled }
        events = allEvents.filter { !$0.isPublicHoliday && $0.isEnabled }
        clearOccurrenceCache()
    }

    private func clearOccurrenceCache() {
        customEventsByDay.removeAll(keepingCapacity: true)
        holidayEventsByDay.removeAll(keepingCapacity: true)
        combinedEventsByDay.removeAll(keepingCapacity: true)
    }

    private func dayKey(for date: Date) -> Date {
        calendar.startOfDay(for: date)
    }

    /// Navigate to the next month
    func nextMonth() {
        guard let currentLunar = currentLunarDate else { return }
        let nextLunar: LunarDate
        if currentLunar.month == 12 {
            nextLunar = LunarDate(year: currentLunar.year + 1, month: 1, day: 1, isLeapMonth: false)
        } else {
            nextLunar = LunarDate(year: currentLunar.year, month: currentLunar.month + 1, day: 1, isLeapMonth: false)
        }
        currentDate = lunarCalendarService.convertToGregorian(lunar: nextLunar)
    }

    /// Navigate to the previous month
    func previousMonth() {
        guard let currentLunar = currentLunarDate else { return }
        let prevLunar: LunarDate
        if currentLunar.month == 1 {
            prevLunar = LunarDate(year: currentLunar.year - 1, month: 12, day: 1, isLeapMonth: false)
        } else {
            prevLunar = LunarDate(year: currentLunar.year, month: currentLunar.month - 1, day: 1, isLeapMonth: false)
        }
        currentDate = lunarCalendarService.convertToGregorian(lunar: prevLunar)
    }

    /// Select a specific date — navigates to its lunar month if needed
    func selectDate(_ date: Date) {
        selectedDate = date

        let dateLunar = lunarCalendarService.convertToLunar(gregorian: date)
        guard let currentLunar = currentLunarDate else { return }

        if dateLunar.month != currentLunar.month || dateLunar.year != currentLunar.year || dateLunar.isLeapMonth != currentLunar.isLeapMonth {
            let firstOfMonth = LunarDate(year: dateLunar.year, month: dateLunar.month, day: 1, isLeapMonth: dateLunar.isLeapMonth)
            currentDate = lunarCalendarService.convertToGregorian(lunar: firstOfMonth)
        }
    }

    /// Get events for a specific date (custom events and holidays)
    func events(for date: Date) -> [Event] {
        let key = dayKey(for: date)
        if let cached = combinedEventsByDay[key] {
            return cached
        }

        let combined = customEvents(for: date) + holidayEvents(for: date)
        combinedEventsByDay[key] = combined
        return combined
    }

    /// Get custom events for a specific date
    func customEvents(for date: Date) -> [Event] {
        let key = dayKey(for: date)
        if let cached = customEventsByDay[key] {
            return cached
        }

        let matched = events.filter { $0.occurs(on: key) }
        customEventsByDay[key] = matched
        return matched
    }

    /// Get holidays for a specific date
    func holidayEvents(for date: Date) -> [Event] {
        let key = dayKey(for: date)
        if let cached = holidayEventsByDay[key] {
            return cached
        }

        let matched = publicHolidays.filter { $0.occurs(on: key) }
        holidayEventsByDay[key] = matched
        return matched
    }

    /// Get lunar date for a Gregorian date
    func lunarDate(for gregorianDate: Date) -> LunarDate {
        return lunarCalendarService.convertToLunar(gregorian: gregorianDate)
    }
}
