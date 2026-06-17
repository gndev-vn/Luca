//
//  LunarCalendarService.swift
//  Luca
//
//  Created by Kiro on 16/12/25.
//

import Foundation

/// Protocol for lunar calendar conversion and calculation services
protocol LunarCalendarService {
    /// Convert a Gregorian date to lunar calendar date
    /// - Parameters:
    ///   - gregorian: The Gregorian date to convert
    /// - Returns: The corresponding LunarDate
    func convertToLunar(gregorian: Date) -> LunarDate
    
    /// Convert a lunar date to Gregorian calendar date
    /// - Parameters:
    ///   - lunar: The lunar date to convert
    /// - Returns: The corresponding Gregorian Date
    func convertToGregorian(lunar: LunarDate) -> Date
    
    /// Get public holidays for a specific country and year
    /// - Parameters:
    ///   - year: The lunar year
    /// - Returns: Array of events representing public holidays
    func getPublicHolidays(year: Int) -> [Event]
    
    /// Validate if a lunar date is valid
    /// - Parameter date: The lunar date to validate
    /// - Returns: True if the date is valid, false otherwise
    func validateLunarDate(_ date: LunarDate) -> Bool
    
    /// Get the current lunar date
    /// - Returns: Current lunar date
    func getCurrentLunarDate() -> LunarDate
}

/// Concrete implementation of LunarCalendarService using iOS native Calendar APIs
class DefaultLunarCalendarService: LunarCalendarService {
    
    // MARK: - Private Properties
    
    /// Chinese calendar instance for conversions
    private let chineseCalendar = Calendar(identifier: .chinese)
    
    /// Gregorian calendar instance for reference
    private let gregorianCalendar = Calendar(identifier: .gregorian)
    
    /// Holiday service for loading public holidays
    private let holidayService: HolidayService
    
    // MARK: - Initialization
    init(holidayService: HolidayService = HolidayService()) {
        self.holidayService = holidayService
    }
    
    // MARK: - LunarCalendarService Implementation
    func convertToLunar(gregorian: Date) -> LunarDate {
        // Use iOS native calendar conversion regardless of country type
        return LunarDate.fromGregorian(gregorian)
    }
    
    func convertToGregorian(lunar: LunarDate) -> Date {
        // Use iOS native calendar conversion regardless of country type
        // The underlying astronomical calculations are the same
        return lunar.toGregorian()
    }
    
    func getPublicHolidays(year: Int) -> [Event] {
        // Use the holiday service to load holidays with caching and validation
        let standardHolidays = holidayService.loadPublicHolidays(year: year)
        let variableHolidays = holidayService.calculateVariableHolidays(year: year)
        
        return standardHolidays + variableHolidays
    }
    
    func validateLunarDate(_ date: LunarDate) -> Bool {
        // Use the built-in validation from LunarDate
        return date.isValid()
    }

    func getCurrentLunarDate() -> LunarDate {
        return convertToLunar(gregorian: Date())
    }
    
    // MARK: - Private Helper Methods
    
}
