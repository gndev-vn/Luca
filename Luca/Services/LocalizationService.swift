//
//  LocalizationService.swift
//  Luca
//
//  Created by Kiro on 19/12/25.
//

import Foundation

/// Service for handling lunar calendar localization from Localizable.strings
class LocalizationService {
    private static func localized(_ key: String) -> String {
        NSLocalizedString(key, bundle: LocalizedStringService.shared.localizationBundle, comment: "")
    }
    
    /// Get localized Vietnamese lunar month names
    /// - Returns: Array of 12 month names in the appropriate language
    static func lunarMonthNames() -> [String] {
        return (1...12).map { localized("lunar_month_\($0)") }
    }
    
    /// Get localized lunar date display text
    /// - Parameters:
    ///   - lunarDate: The lunar date to format
    /// - Returns: Formatted lunar date string in the appropriate language
    static func lunarDateDisplayText(_ lunarDate: LunarDate) -> String {
        let format = localized("lunar_date_display_format")
        return String(
            format: format,
            locale: Locale.current,
            String(lunarDate.traditionalYear),
            lunarDate.month,
            lunarDate.day
        )
    }
    
    /// Get localized leap month indicator
    /// - Returns: Leap month indicator text in the appropriate language
    static func leapMonthIndicator() -> String {
        return localized("lunar_leap_month_indicator")
    }
    
    /// Get localized month name for a specific month number
    /// - Parameters:
    ///   - month: Month number (1-12)
    /// - Returns: Localized month name
    static func monthName(_ month: Int) -> String {
        let monthNames = lunarMonthNames()
        return monthNames[safe: month - 1] ?? monthNames[0]
    }
    
    /// Get accessibility label for lunar date
    /// - Parameters:
    ///   - lunarDate: The lunar date
    /// - Returns: Accessibility-friendly description in English
    static func lunarDateAccessibilityLabel(_ lunarDate: LunarDate) -> String {
        let monthName = localized("lunar_accessibility_month_\(lunarDate.month)")
        let leapText = lunarDate.isLeapMonth ? localized("lunar_accessibility_leap_prefix") : ""
        let calendarType = String.localized(.vietnameseLunarCalendar)
        let format = localized("lunar_accessibility_format")

        return String(
            format: format,
            locale: Locale.current,
            calendarType,
            leapText,
            monthName,
            lunarDate.traditionalYear,
            lunarDate.day
        )
    }
}
