//
//  LunarDate.swift
//  Luca
//
//  Created by Kiro on 16/12/25.
//

import Foundation

/// Represents a date in the lunar calendar system
struct LunarDate: Equatable, Codable {
    let year: Int        // Lunar calendar year (41 = 2024 CE, 42 = 2025 CE, etc.)
    let month: Int       // Lunar month (1-12)
    let day: Int         // Lunar day (1-30)
    let isLeapMonth: Bool

    /// Initialize a new LunarDate
    /// - Parameters:
    ///   - year: The lunar calendar year (e.g., 41 for 2024 CE)
    ///   - month: The lunar month (1-12, or 1-13 in leap years)
    ///   - day: The lunar day (1-30, depending on month)
    ///   - isLeapMonth: Whether this is a leap month
    init(year: Int, month: Int, day: Int, isLeapMonth: Bool = false) {
        self.year = year
        self.month = month
        self.day = day
        self.isLeapMonth = isLeapMonth
    }
    
    /// Get the traditional year for display purposes
    var traditionalYear: Int {
        return year + 1983  // Convert from lunar calendar year to traditional year
    }
    
    /// Get the zodiac year name (sexagenary cycle) for the traditional year
    /// - Returns: The zodiac year name (e.g., "Giáp Thìn", "甲辰", "Wood Dragon")
    func zodiacYear() -> String {
        return ZodiacYearCalculator.getZodiacYear(for: traditionalYear)
    }
    
    /// Get both numeric and zodiac year display
    /// - Returns: Combined year display (e.g., "Year 41 (Giáp Thìn)", "Năm 41 (Giáp Thìn)")
    func fullYearDisplay() -> String {
        let zodiac = zodiacYear()
        let format = LocalizedStringService.shared.localizedString(for: .lunarFullYearFormat)
        return String(format: format, locale: Locale.current, String(traditionalYear), zodiac)
    }
    
    /// The corresponding Gregorian date for this lunar date
    /// This is a computed property that uses iOS native calendar conversion
    var gregorianEquivalent: Date {
        return toGregorian()
    }
    
    /// Convert this lunar date to Gregorian calendar using iOS native APIs
    /// - Returns: The corresponding Gregorian Date
    func toGregorian() -> Date {
        let chineseCalendar = Calendar(identifier: .chinese)
        
        // Create date components for the Chinese calendar (using iOS Chinese year directly)
        var components = DateComponents()
        components.calendar = chineseCalendar
        components.year = year
        components.month = month
        components.day = day
        components.isLeapMonth = isLeapMonth
        
        // Convert to Date using iOS native conversion
        return components.date ?? Date()
    }
    
    /// Create a LunarDate from a Gregorian date using iOS native APIs
    /// - Parameters:
    ///   - date: The Gregorian date to convert
    ///   - country: The country context for lunar calendar calculations (optional)
    /// - Returns: The corresponding LunarDate
    static func fromGregorian(_ date: Date) -> LunarDate {
        let chineseCalendar = Calendar(identifier: .chinese)
        
        // Extract Chinese calendar components from the Gregorian date
        let components = chineseCalendar.dateComponents([.year, .month, .day, .isLeapMonth], from: date)
        
        return LunarDate(
            year: components.year ?? 1,
            month: components.month ?? 1,
            day: components.day ?? 1,
            isLeapMonth: components.isLeapMonth ?? false
        )
    }
    
    /// Validates if this lunar date is valid
    /// - Returns: True if the date is valid, false otherwise
    func isValid() -> Bool {
        // Basic validation rules for lunar calendar
        guard year > 0 else { return false }
        guard month >= 1 && month <= 12 else { return false }
        guard day >= 1 && day <= 30 else { return false }
        
        // Additional validation for specific months
        // Some lunar months have only 29 days
        if month == 2 || month == 4 || month == 6 || month == 9 || month == 11 {
            if day > 29 {
                return false
            }
        }
        
        // Leap month validation
        if isLeapMonth {
            // Leap months typically occur every 2-3 years
            // This is a simplified check
            return month <= 12
        }
        
        return true
    }
    
}

/// Lunar Calendar Converter using iOS native Calendar APIs
class LunarCalendarConverter {
    
    private static let chineseCalendar = Calendar(identifier: .chinese)
    private static let gregorianCalendar = Calendar(identifier: .gregorian)
    
    // MARK: - Conversion Methods
    
    /// Convert lunar date to Gregorian date using iOS native APIs
    /// - Parameters:
    ///   - year: iOS Chinese calendar year (e.g., 41 for 2024 CE)
    ///   - month: Lunar month (1-12)
    ///   - day: Lunar day (1-30)
    ///   - isLeapMonth: Whether this is a leap month
    /// - Returns: The corresponding Gregorian Date
    static func lunarToGregorian(year: Int, month: Int, day: Int, isLeapMonth: Bool) -> Date {
        var components = DateComponents()
        components.calendar = chineseCalendar
        components.year = year
        components.month = month
        components.day = day
        components.isLeapMonth = isLeapMonth
        
        return components.date ?? Date()
    }
    
    /// Convert Gregorian date to lunar date using iOS native APIs
    /// - Parameter date: The Gregorian date to convert
    /// - Returns: The corresponding LunarDate
    static func gregorianToLunar(date: Date) -> LunarDate {
        let components = chineseCalendar.dateComponents([.year, .month, .day, .isLeapMonth], from: date)
        
        return LunarDate(
            year: components.year ?? 1,  // Use iOS Chinese calendar year directly
            month: components.month ?? 1,
            day: components.day ?? 1,
            isLeapMonth: components.isLeapMonth ?? false
        )
    }
    
    // MARK: - Helper Methods
    
    /// Check if a lunar year has a leap month using iOS native APIs
    /// - Parameter year: The iOS Chinese calendar year to check (e.g., 41 for 2024 CE)
    /// - Returns: True if the year has a leap month
    static func hasLeapMonth(_ year: Int) -> Bool {
        // Create a date for the beginning of the lunar year
        var startComponents = DateComponents()
        startComponents.calendar = chineseCalendar
        startComponents.year = year  // Use iOS Chinese calendar year directly
        startComponents.month = 1
        startComponents.day = 1
        
        guard let startDate = startComponents.date else { return false }
        
        // Create a date for the beginning of the next lunar year
        var endComponents = DateComponents()
        endComponents.calendar = chineseCalendar
        endComponents.year = year + 1
        endComponents.month = 1
        endComponents.day = 1
        
        guard let endDate = endComponents.date else { return false }
        
        // Check each month in the year to see if any is a leap month
        var currentDate = startDate
        while currentDate < endDate {
            let components = chineseCalendar.dateComponents([.isLeapMonth], from: currentDate)
            if components.isLeapMonth == true {
                return true
            }
            
            // Move to next month
            guard let nextMonth = chineseCalendar.date(byAdding: .month, value: 1, to: currentDate) else {
                break
            }
            currentDate = nextMonth
        }
        
        return false
    }
    
    /// Get leap month information for a year using iOS native APIs
    /// - Parameter year: The iOS Chinese calendar year (e.g., 41 for 2024 CE)
    /// - Returns: Tuple containing leap month info (hasLeap, leapMonth, leapDays)
    static func getLeapMonthInfo(_ year: Int) -> (hasLeap: Bool, leapMonth: Int, leapDays: Int) {
        // Create a date for the beginning of the lunar year
        var startComponents = DateComponents()
        startComponents.calendar = chineseCalendar
        startComponents.year = year  // Use iOS Chinese calendar year directly
        startComponents.month = 1
        startComponents.day = 1
        
        guard let startDate = startComponents.date else {
            return (false, 0, 0)
        }
        
        // Create a date for the beginning of the next lunar year
        var endComponents = DateComponents()
        endComponents.calendar = chineseCalendar
        endComponents.year = year + 1
        endComponents.month = 1
        endComponents.day = 1
        
        guard let endDate = endComponents.date else {
            return (false, 0, 0)
        }
        
        // Check each month in the year to find the leap month
        var currentDate = startDate
        while currentDate < endDate {
            let components = chineseCalendar.dateComponents([.month, .isLeapMonth], from: currentDate)
            
            if components.isLeapMonth == true {
                // Found leap month, calculate its length
                guard let nextMonth = chineseCalendar.date(byAdding: .month, value: 1, to: currentDate) else {
                    return (true, components.month ?? 0, 29)
                }
                
                let daysDiff = chineseCalendar.dateComponents([.day], from: currentDate, to: nextMonth).day ?? 29
                return (true, components.month ?? 0, daysDiff)
            }
            
            // Move to next month
            guard let nextMonth = chineseCalendar.date(byAdding: .month, value: 1, to: currentDate) else {
                break
            }
            currentDate = nextMonth
        }
        
        return (false, 0, 0)
    }
    
    /// Validate a lunar date using iOS native APIs
    /// - Parameters:
    ///   - year: iOS Chinese calendar year (e.g., 41 for 2024 CE)
    ///   - month: Lunar month
    ///   - day: Lunar day
    ///   - isLeapMonth: Whether this is a leap month
    /// - Returns: True if the date is valid
    static func validateLunarDate(year: Int, month: Int, day: Int, isLeapMonth: Bool) -> Bool {
        var components = DateComponents()
        components.calendar = chineseCalendar
        components.year = year
        components.month = month
        components.day = day
        components.isLeapMonth = isLeapMonth
        
        // If we can create a valid date, the lunar date is valid
        return components.date != nil
    }
    
    /// Get the number of days in a specific lunar month using iOS native APIs
    /// - Parameters:
    ///   - year: iOS Chinese calendar year (e.g., 41 for 2024 CE)
    ///   - month: Lunar month
    ///   - isLeapMonth: Whether this is a leap month
    /// - Returns: Number of days in the month
    static func daysInLunarMonth(year: Int, month: Int, isLeapMonth: Bool) -> Int {
        var components = DateComponents()
        components.calendar = chineseCalendar
        components.year = year
        components.month = month
        components.day = 1
        components.isLeapMonth = isLeapMonth
        
        guard let startDate = components.date else { return 29 }
        
        // Get the next month
        guard let nextMonth = chineseCalendar.date(byAdding: .month, value: 1, to: startDate) else {
            return 29
        }
        
        // Calculate the difference
        let daysDiff = chineseCalendar.dateComponents([.day], from: startDate, to: nextMonth).day ?? 29
        return daysDiff
    }
}

/// Calculator for Vietnamese zodiac years (sexagenary cycle)
class ZodiacYearCalculator {
    
    private static let stems   = ["Giáp", "Ất", "Bính", "Đinh", "Mậu", "Kỷ", "Canh", "Tân", "Nhâm", "Quý"]
    private static let branches = ["Tý", "Sửu", "Dần", "Mão", "Thìn", "Tỵ", "Ngọ", "Mùi", "Thân", "Dậu", "Tuất", "Hợi"]

    // MARK: - Year

    static func getZodiacYear(for year: Int) -> String {
        let stemIndex   = (year - 4) % 10
        let branchIndex = (year - 4) % 12
        return "\(stems[stemIndex]) \(branches[branchIndex])"
    }

    // MARK: - Month
    // Month branches are fixed: month 1 = Dần (index 2), cycling forward.
    // Month stems depend on the year stem via the rule:
    //   year stem 0,5 (Giáp/Kỷ)  → month-1 stem = Bính (2)
    //   year stem 1,6 (Ất/Canh)  → month-1 stem = Mậu  (4)
    //   year stem 2,7 (Bính/Tân) → month-1 stem = Canh  (6)
    //   year stem 3,8 (Đinh/Nhâm)→ month-1 stem = Nhâm  (8)
    //   year stem 4,9 (Mậu/Quý)  → month-1 stem = Giáp  (0)

    static func getZodiacMonth(lunarMonth: Int, lunarYear: Int) -> String {
        let yearStem    = ((lunarYear - 4) % 10 + 10) % 10
        let month1Stem  = (2 + (yearStem % 5) * 2) % 10
        let stemIndex   = (month1Stem + lunarMonth - 1) % 10
        let branchIndex = (lunarMonth + 1) % 12   // month 1→Dần(2), …, month 12→Sửu(1)
        return "\(stems[stemIndex]) \(branches[branchIndex])"
    }

    // MARK: - Day
    // Uses the Julian Day Number (JDN). Reference: JDN 2451545 (2000-01-01)
    // was Mậu Thìn day (position 4 in the 60-cycle), so position = (JDN - 1) % 60.

    static func getZodiacDay(for date: Date) -> String {
        let jdn = julianDayNumber(for: date)
        // Reference: JDN 2461201 (2026-06-09) = Giáp Dần (position 50)
        // So: pos = (jdn + 49) % 60
        let pos = ((jdn + 49) % 60 + 60) % 60
        return "\(stems[pos % 10]) \(branches[pos % 12])"
    }

    private static func julianDayNumber(for date: Date) -> Int {
        let cal  = Calendar(identifier: .gregorian)
        let comp = cal.dateComponents([.year, .month, .day], from: date)
        let y = comp.year!, m = comp.month!, d = comp.day!
        let a  = (14 - m) / 12
        let ya = y + 4800 - a
        let ma = m + 12 * a - 3
        return d + (153 * ma + 2) / 5 + 365 * ya + ya / 4 - ya / 100 + ya / 400 - 32045
    }
}
