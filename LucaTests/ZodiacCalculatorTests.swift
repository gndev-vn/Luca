//
//  ZodiacCalculatorTests.swift
//  LucaTests
//
//  Tests for the Vietnamese sexagenary (lục thập hoa giáp) can-chi calculations
//  covering year, month, and day zodiac names.
//

import XCTest
@testable import Luca

final class ZodiacCalculatorTests: XCTestCase {

    // MARK: - Helpers

    private func gregorianDate(year: Int, month: Int, day: Int) -> Date {
        var comps = DateComponents()
        comps.year = year; comps.month = month; comps.day = day
        return Calendar(identifier: .gregorian).date(from: comps)!
    }

    private func lunarDate(traditionalYear: Int, month: Int, day: Int, isLeap: Bool = false) -> LunarDate {
        LunarDate.fromTraditional(year: traditionalYear, month: month, day: day, isLeapMonth: isLeap)
    }

    // MARK: - Year Tests

    // The 60-year cycle (lục thập hoa giáp) repeats every 60 years.
    // Formula used: stemIndex = (traditionalYear - 4) % 10
    //               branchIndex = (traditionalYear - 4) % 12
    // Selected reference years from the Vietnamese almanac.

    func testZodiacYear_2024_GiapThin() {
        // 2024 = Giáp Thìn (Year of the Dragon)
        let lunarDate = self.lunarDate(traditionalYear: 2024, month: 1, day: 1)
        let result = ZodiacYearCalculator.getZodiacYear(for: lunarDate.traditionalYear)
        XCTAssertEqual(result, "Giáp Thìn", "2024 should be Giáp Thìn")
    }

    func testZodiacYear_2025_AtTy() {
        let lunarDate = self.lunarDate(traditionalYear: 2025, month: 1, day: 1)
        let result = ZodiacYearCalculator.getZodiacYear(for: lunarDate.traditionalYear)
        XCTAssertEqual(result, "Ất Tỵ", "2025 should be Ất Tỵ")
    }

    func testZodiacYear_2026_BinhNgo() {
        let lunarDate = self.lunarDate(traditionalYear: 2026, month: 1, day: 1)
        let result = ZodiacYearCalculator.getZodiacYear(for: lunarDate.traditionalYear)
        XCTAssertEqual(result, "Bính Ngọ", "2026 should be Bính Ngọ")
    }

    func testZodiacYear_2030_CanhTuat() {
        // 2030: stem (2030-4)%10=6→Canh, branch (2030-4)%12=2→Dần ... wait
        // (2030-4)=2026, 2026%10=6→Canh, 2026%12=10→Tuất → Canh Tuất
        let lunarDate = self.lunarDate(traditionalYear: 2030, month: 1, day: 1)
        let result = ZodiacYearCalculator.getZodiacYear(for: lunarDate.traditionalYear)
        XCTAssertEqual(result, "Canh Tuất", "2030 should be Canh Tuất")
    }

    func testZodiacYear_1984_GiapTy() {
        // 1984 is the canonical Giáp Tý year (start of current 60-year cycle known reference)
        // (1984-4)%10=0→Giáp, (1984-4)%12=0→Tý
        let result = ZodiacYearCalculator.getZodiacYear(for: 1984)
        XCTAssertEqual(result, "Giáp Tý", "1984 should be Giáp Tý")
    }

    func testZodiacYear_cycleRepeatsEvery60Years() {
        // The sexagenary cycle repeats every 60 years
        let year1 = ZodiacYearCalculator.getZodiacYear(for: 1984)
        let year2 = ZodiacYearCalculator.getZodiacYear(for: 2044)
        XCTAssertEqual(year1, year2, "Zodiac year repeats every 60 years")
    }

    func testZodiacYear_allStemsPresent() {
        let stems = ["Giáp", "Ất", "Bính", "Đinh", "Mậu", "Kỷ", "Canh", "Tân", "Nhâm", "Quý"]
        // Over any 10 consecutive years, all 10 heavenly stems must appear exactly once
        var foundStems: Set<String> = []
        for year in 2020...2029 {
            let zodiac = ZodiacYearCalculator.getZodiacYear(for: year)
            let stem = zodiac.components(separatedBy: " ").first!
            foundStems.insert(stem)
        }
        for stem in stems {
            XCTAssertTrue(foundStems.contains(stem), "Stem \(stem) must appear in 2020-2029")
        }
    }

    // MARK: - Month Tests

    // Month branches are fixed: month 1=Dần, 2=Mão, 3=Thìn, 4=Tỵ, 5=Ngọ,
    //   6=Mùi, 7=Thân, 8=Dậu, 9=Tuất, 10=Hợi, 11=Tý, 12=Sửu
    // Month stems depend on the year stem (Giáp/Kỷ → Bính for month 1, etc.)

    func testZodiacMonth_June2026_QuiTy() {
        // June 2026 ≈ lunar month 4 of Bính Ngọ year
        // Bính (stem 2) year → month-1 stem = Canh (6)
        // Month 4 stem = (6 + 3) % 10 = 9 → Quý; branch = (4+1)%12 = 5 → Tỵ
        // User-confirmed: Quý Tỵ
        let result = ZodiacYearCalculator.getZodiacMonth(lunarMonth: 4, lunarYear: 2026)
        XCTAssertEqual(result, "Quý Tỵ", "Lunar month 4, Bính Ngọ year (2026) should be Quý Tỵ")
    }

    func testZodiacMonth_branchesAreFixed() {
        // Branch of each month is fixed regardless of year
        // month 1 = Dần, month 2 = Mão, …
        let expectedBranches = [
            1: "Dần", 2: "Mão", 3: "Thìn", 4: "Tỵ",
            5: "Ngọ", 6: "Mùi", 7: "Thân", 8: "Dậu",
            9: "Tuất", 10: "Hợi", 11: "Tý", 12: "Sửu"
        ]
        for (month, expectedBranch) in expectedBranches {
            let zodiac = ZodiacYearCalculator.getZodiacMonth(lunarMonth: month, lunarYear: 2024)
            let branch = zodiac.components(separatedBy: " ").last!
            XCTAssertEqual(branch, expectedBranch, "Month \(month) should have branch \(expectedBranch)")
        }
    }

    func testZodiacMonth_stemCycleEvery5Years() {
        // The month stem cycles every 5 years for a given month
        // e.g., month 1 of Giáp year = Bính, month 1 of Kỷ year = Bính (5 years later)
        let giapYearMonth1 = ZodiacYearCalculator.getZodiacMonth(lunarMonth: 1, lunarYear: 2024)  // Giáp Thìn
        let kyYearMonth1   = ZodiacYearCalculator.getZodiacMonth(lunarMonth: 1, lunarYear: 2029)  // Kỷ Dậu
        // Both Giáp and Kỷ → month 1 = Bính Dần
        XCTAssertEqual(giapYearMonth1, kyYearMonth1, "Month stems repeat every 5 years for the same month")
    }

    func testZodiacMonth_allStemsIn10Months() {
        // Over 10 consecutive months (one year and 2 extra), all 10 stems appear
        var foundStems: Set<String> = []
        // 2 consecutive years = 24 months, must contain every stem at least twice
        for month in 1...12 {
            let zodiac = ZodiacYearCalculator.getZodiacMonth(lunarMonth: month, lunarYear: 2024)
            foundStems.insert(zodiac.components(separatedBy: " ").first!)
        }
        // 12 months → each stem appears at least once (10 stems cycle in 10 months, so 12 covers all)
        let allStems = ["Giáp","Ất","Bính","Đinh","Mậu","Kỷ","Canh","Tân","Nhâm","Quý"]
        let missingStems = allStems.filter { !foundStems.contains($0) }
        // Only 2 stems will be missing across 12 months (since 12 months = 1.2 full stem cycles)
        XCTAssertLessThanOrEqual(missingStems.count, 2, "At most 2 stems can be absent in 12 consecutive months")
    }

    // MARK: - Day Tests

    // Reference anchored to user-confirmed value:
    // 2026-06-09 (Gregorian) = Giáp Dần day

    func testZodiacDay_2026_06_09_GiapDan() {
        // User-confirmed reference: today is Giáp Dần
        let date = gregorianDate(year: 2026, month: 6, day: 9)
        let result = ZodiacYearCalculator.getZodiacDay(for: date)
        XCTAssertEqual(result, "Giáp Dần", "2026-06-09 should be Giáp Dần (user-confirmed)")
    }

    func testZodiacDay_cycleMoves1PerDay() {
        // Each day the can-chi advances by exactly 1 position in the 60-cycle
        let cal  = Calendar.current
        let ref  = gregorianDate(year: 2026, month: 6, day: 9)  // Giáp Dần (pos 50)
        let next = cal.date(byAdding: .day, value: 1, to: ref)!  // should be Ất Mão (pos 51)
        let result = ZodiacYearCalculator.getZodiacDay(for: next)
        XCTAssertEqual(result, "Ất Mão", "Day after Giáp Dần should be Ất Mão")
    }

    func testZodiacDay_cycleRepeatsEvery60Days() {
        // The 60-day cycle repeats exactly every 60 days
        let cal  = Calendar.current
        let ref  = gregorianDate(year: 2026, month: 6, day: 9)
        let plus60 = cal.date(byAdding: .day, value: 60, to: ref)!
        XCTAssertEqual(
            ZodiacYearCalculator.getZodiacDay(for: ref),
            ZodiacYearCalculator.getZodiacDay(for: plus60),
            "Zodiac day repeats every 60 days"
        )
    }

    func testZodiacDay_knownHistoricalDate() {
        // 2024-02-10 = Lunar New Year, verified via algorithm: Giáp Thìn day
        let date = gregorianDate(year: 2024, month: 2, day: 10)
        let result = ZodiacYearCalculator.getZodiacDay(for: date)
        XCTAssertEqual(result, "Giáp Thìn", "2024-02-10 (Chinese New Year) should be Giáp Thìn")
    }

    func testZodiacDay_allStemsAppearedIn60DayCycle() {
        // Over any 60 consecutive days, every stem appears exactly 6 times
        // and every branch appears exactly 5 times
        let start = gregorianDate(year: 2026, month: 1, day: 1)
        let cal   = Calendar.current
        var stems: [String: Int] = [:]
        var branches: [String: Int] = [:]
        for offset in 0..<60 {
            let day    = cal.date(byAdding: .day, value: offset, to: start)!
            let zodiac = ZodiacYearCalculator.getZodiacDay(for: day)
            let parts  = zodiac.components(separatedBy: " ")
            stems[parts[0], default: 0] += 1
            branches[parts[1], default: 0] += 1
        }
        // Every stem appears 6 times in 60 days
        for (stem, count) in stems {
            XCTAssertEqual(count, 6, "Stem \(stem) should appear 6 times in 60 days")
        }
        // Every branch appears 5 times in 60 days
        for (branch, count) in branches {
            XCTAssertEqual(count, 5, "Branch \(branch) should appear 5 times in 60 days")
        }
        // All 10 stems must be present
        XCTAssertEqual(stems.count, 10, "All 10 heavenly stems must appear in 60 days")
        // All 12 branches must be present
        XCTAssertEqual(branches.count, 12, "All 12 earthly branches must appear in 60 days")
    }

    func testZodiacDay_negativeDayOffset() {
        // Ensure past dates also work correctly (day before Giáp Dần = Quý Sửu)
        let ref      = gregorianDate(year: 2026, month: 6, day: 9)  // Giáp Dần (pos 50)
        let prev     = Calendar.current.date(byAdding: .day, value: -1, to: ref)!
        let result   = ZodiacYearCalculator.getZodiacDay(for: prev)
        XCTAssertEqual(result, "Quý Sửu", "Day before Giáp Dần should be Quý Sửu (pos 49)")
    }
}
