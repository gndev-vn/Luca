//
//  LunarDateTests.swift
//  LucaTests
//
//  Created by Kiro on 16/12/25.
//

import XCTest
import SwiftCheck
@testable import Luca

/// Property-based tests for LunarDate functionality
final class LunarDateTests: XCTestCase {
    
    /// Test that lunar date validation works correctly
    func testLunarDateValidation() {
        // Unit test for basic validation
        let validDate = LunarDate(year: 2024, month: 6, day: 15, isLeapMonth: false)
        XCTAssertTrue(validDate.isValid())
        
        let invalidDate = LunarDate(year: -1, month: 13, day: 32, isLeapMonth: false)
        XCTAssertFalse(invalidDate.isValid())
    }
    
    /// Property test for lunar date validation
    func testLunarDateValidationProperty() {
        property("Valid lunar dates should pass validation") <- forAll { (year: Positive<Int>, month: Int, day: Int) in
            let constrainedMonth = (month % 12) + 1  // 1-12
            let constrainedDay = (day % 30) + 1      // 1-30
            
            let lunarDate = LunarDate(
                year: year.getPositive,
                month: constrainedMonth,
                day: constrainedDay,
                isLeapMonth: false
            )
            
            return lunarDate.isValid()
        }
    }
    
    /// Property test for lunar date equality
    func testLunarDateEquality() {
        property("Lunar dates with same components should be equal") <- forAll { (year: Int, month: Int, day: Int, isLeap: Bool) in
            let date1 = LunarDate(year: year, month: month, day: day, isLeapMonth: isLeap)
            let date2 = LunarDate(year: year, month: month, day: day, isLeapMonth: isLeap)
            
            return date1 == date2
        }
    }
    
    // MARK: - Property-Based Tests for Requirements
    
    /// Property 18: Date Conversion Accuracy
    /// Validates: Requirements 6.1
    /// Tests that lunar date conversion to Gregorian and back maintains accuracy within acceptable bounds
    func testDateConversionAccuracy() {
        property("Lunar to Gregorian conversion should be accurate") <- forAll { (lunarDate: LunarDate) in
            // Only test with valid lunar dates to avoid iOS calendar API edge cases
            guard lunarDate.isValid() else { return Discard() }
            
            // Convert lunar to Gregorian using iOS native APIs
            let gregorianDate = lunarDate.toGregorian()
            
            // Convert back to lunar
            let convertedBack = LunarDate.fromGregorian(gregorianDate)
            
            // With direct iOS API usage, conversion should be perfect
            let yearMatch = lunarDate.year == convertedBack.year
            let monthMatch = lunarDate.month == convertedBack.month
            let dayMatch = lunarDate.day == convertedBack.day
            let leapMatch = lunarDate.isLeapMonth == convertedBack.isLeapMonth
            
            // All components should match exactly with direct API usage
            return yearMatch && monthMatch && dayMatch && leapMatch
        }
    }
    
    /// Property 19: Conversion Consistency
    /// Validates: Requirements 6.2
    /// Tests that multiple conversions of the same date produce consistent results
    func testConversionConsistency() {
        property("Multiple conversions should be consistent") <- forAll { (lunarDate: LunarDate) in
            // Only test with valid lunar dates
            guard lunarDate.isValid() else { return Discard() }
            
            // Convert to Gregorian multiple times
            let gregorian1 = lunarDate.toGregorian()
            let gregorian2 = lunarDate.toGregorian()
            let gregorian3 = lunarDate.toGregorian()
            
            // All conversions should produce identical results
            let gregorianConsistent = gregorian1 == gregorian2 && gregorian2 == gregorian3
            
            // Convert back to lunar multiple times
            let lunar1 = LunarDate.fromGregorian(gregorian1)
            let lunar2 = LunarDate.fromGregorian(gregorian1)
            let lunar3 = LunarDate.fromGregorian(gregorian1)
            
            // All reverse conversions should produce identical results
            let lunarConsistent = lunar1 == lunar2 && lunar2 == lunar3
            
            return gregorianConsistent && lunarConsistent
        }
    }
}

/// Custom generators for SwiftCheck
extension LunarDate: Arbitrary {
    public static var arbitrary: Gen<LunarDate> {
        return Gen.compose { c in
            return LunarDate(
                year: c.generate(using: Gen.choose((1, 100))),  // iOS Chinese years: 1-100 (covers ~1984-2083 CE)
                month: c.generate(using: Gen.choose((1, 12))),
                day: c.generate(using: Gen.choose((1, 30))),
                isLeapMonth: c.generate()
            )
        }
    }
}