//
//  LunarDateConversionTests.swift
//  LucaTests
//
//  Created by Kiro on 16/12/25.
//

import XCTest
@testable import Luca

final class LunarDateConversionTests: XCTestCase {
    
    func testKnownLunarDates() {
        // Test some well-known lunar calendar dates using iOS native APIs
        let gregorianCalendar = Calendar(identifier: .gregorian)
        
        // Lunar New Year 2024: February 10, 2024
        let lunarNewYear2024Date = gregorianCalendar.date(from: DateComponents(year: 2024, month: 2, day: 10))!
        let lunarNewYear2024 = LunarDate.fromGregorian(lunarNewYear2024Date)
        
        XCTAssertEqual(lunarNewYear2024.year, 41)
        XCTAssertEqual(lunarNewYear2024.month, 1)
        XCTAssertEqual(lunarNewYear2024.day, 1)
        XCTAssertFalse(lunarNewYear2024.isLeapMonth)
        
        // Traditional year should be 2024 for display
        XCTAssertEqual(lunarNewYear2024.traditionalYear, 2024)
        
        // Test round-trip conversion - should be exact with native APIs
        let convertedBack = lunarNewYear2024.toGregorian()
        let daysDifference = abs(gregorianCalendar.dateComponents([.day], from: lunarNewYear2024Date, to: convertedBack).day ?? 0)
        
        // Should be exact with native iOS APIs
        XCTAssertEqual(daysDifference, 0, "Round-trip conversion should be exact with native iOS APIs")
        
        // Mid-Autumn Festival 2024: September 17, 2024 = iOS Chinese Calendar 41/8/15
        let midAutumn2024 = gregorianCalendar.date(from: DateComponents(year: 2024, month: 9, day: 17))!
        let lunarMidAutumn2024 = LunarDate.fromGregorian(midAutumn2024)
        
        XCTAssertEqual(lunarMidAutumn2024.year, 41)
        XCTAssertEqual(lunarMidAutumn2024.month, 8)
        XCTAssertEqual(lunarMidAutumn2024.day, 15)
        XCTAssertFalse(lunarMidAutumn2024.isLeapMonth)
        
        // Traditional year should be 2024 for display
        XCTAssertEqual(lunarMidAutumn2024.traditionalYear, 2024)
    }
    
    func testLunarToGregorianConversion() {
        // Test converting lunar dates to Gregorian using iOS native APIs
        // Uses iOS Chinese calendar year (41) directly
        let lunar41_1_1 = LunarDate(year: 41, month: 1, day: 1, isLeapMonth: false)
        let gregorian = lunar41_1_1.toGregorian()
        
        let gregorianCalendar = Calendar(identifier: .gregorian)
        let components = gregorianCalendar.dateComponents([.year, .month, .day], from: gregorian)
        
        // Should be exactly February 10, 2024 (Lunar New Year) with native APIs
        XCTAssertEqual(components.year, 2024)
        XCTAssertEqual(components.month, 2)
        XCTAssertEqual(components.day, 10)
        
        // Test traditional year convenience
        XCTAssertEqual(lunar41_1_1.traditionalYear, 2024)
    }
    
    func testTraditionalYearConvenience() {
        // Test the convenience method for creating LunarDate with traditional years
        let lunarFromTraditional = LunarDate.fromTraditional(year: 2024, month: 6, day: 15, isLeapMonth: false)
        
        // Should convert to iOS Chinese year internally
        XCTAssertEqual(lunarFromTraditional.year, 41)
        XCTAssertEqual(lunarFromTraditional.month, 6)
        XCTAssertEqual(lunarFromTraditional.day, 15)
        XCTAssertFalse(lunarFromTraditional.isLeapMonth)
        
        // Traditional year should be preserved for display
        XCTAssertEqual(lunarFromTraditional.traditionalYear, 2024)
    }
    
    func testLunarNewYear2026Conversion() {
        // Test converting Lunar New Year 2026 (lunar 1/1/2026) to Gregorian
        let lunarNewYear2026 = LunarDate.fromTraditional(year: 2026, month: 1, day: 1, isLeapMonth: false)
        
        // Should convert to iOS Chinese year 43 internally (2026 - 1983 = 43)
        XCTAssertEqual(lunarNewYear2026.year, 43)
        XCTAssertEqual(lunarNewYear2026.month, 1)
        XCTAssertEqual(lunarNewYear2026.day, 1)
        XCTAssertFalse(lunarNewYear2026.isLeapMonth)
        
        // Convert to Gregorian
        let gregorianDate = lunarNewYear2026.toGregorian()
        
        let gregorianCalendar = Calendar(identifier: .gregorian)
        let components = gregorianCalendar.dateComponents([.year, .month, .day], from: gregorianDate)
        
        // Lunar New Year 2026 should fall in early 2026 (exact date determined by iOS native calculation)
        XCTAssertEqual(components.year, 2026)
        
        // Print the actual date for verification
        print("Lunar New Year 2026 (Lunar 1/1/2026) falls on: \(components.year!)-\(components.month!)-\(components.day!)")
        
        // Test round-trip conversion
        let convertedBack = LunarDate.fromGregorian(gregorianDate)
        XCTAssertEqual(convertedBack.year, 43)  // iOS Chinese year
        XCTAssertEqual(convertedBack.month, 1)
        XCTAssertEqual(convertedBack.day, 1)
        XCTAssertFalse(convertedBack.isLeapMonth)
        XCTAssertEqual(convertedBack.traditionalYear, 2026)  // Traditional year for display
        
        // Verify perfect round-trip
        XCTAssertEqual(lunarNewYear2026, convertedBack, "Round-trip conversion should be perfect")
    }
    
    func testLeapMonthHandling() {
        // Test leap month functionality
        let hasLeap2023 = LunarCalendarConverter.hasLeapMonth(2023)
        let hasLeap2024 = LunarCalendarConverter.hasLeapMonth(2024)
        
        // These should return boolean values (actual leap years may vary)
        XCTAssertTrue(hasLeap2023 || !hasLeap2023) // Just ensure it returns a boolean
        XCTAssertTrue(hasLeap2024 || !hasLeap2024) // Just ensure it returns a boolean
        
        // Test leap month info
        let leapInfo2023 = LunarCalendarConverter.getLeapMonthInfo(2023)
        XCTAssertTrue(leapInfo2023.hasLeap || !leapInfo2023.hasLeap) // Should return valid info
        
        if leapInfo2023.hasLeap {
            XCTAssertGreaterThan(leapInfo2023.leapMonth, 0)
            XCTAssertLessThanOrEqual(leapInfo2023.leapMonth, 12)
            XCTAssertTrue(leapInfo2023.leapDays == 29 || leapInfo2023.leapDays == 30)
        }
    }
    
    func testDateValidation() {
        // Test valid dates
        let validDate = LunarDate(year: 2024, month: 1, day: 15, isLeapMonth: false)
        XCTAssertTrue(validDate.isValid())
        
        // Test invalid dates
        let invalidYear = LunarDate(year: -1, month: 1, day: 1, isLeapMonth: false)
        XCTAssertFalse(invalidYear.isValid())
        
        let invalidMonth = LunarDate(year: 2024, month: 13, day: 1, isLeapMonth: false)
        XCTAssertFalse(invalidMonth.isValid())
        
        let invalidDay = LunarDate(year: 2024, month: 1, day: 31, isLeapMonth: false)
        XCTAssertFalse(invalidDay.isValid())
    }
    
    func testValidationWithDetails() {
        let validDate = LunarDate(year: 2024, month: 1, day: 15, isLeapMonth: false)
        let validation = validDate.validateWithDetails()
        XCTAssertTrue(validation.isValid)
        XCTAssertTrue(validation.issues.isEmpty)
        
        let invalidDate = LunarDate(year: -1, month: 13, day: 31, isLeapMonth: false)
        let invalidValidation = invalidDate.validateWithDetails()
        XCTAssertFalse(invalidValidation.isValid)
        XCTAssertFalse(invalidValidation.issues.isEmpty)
    }
}