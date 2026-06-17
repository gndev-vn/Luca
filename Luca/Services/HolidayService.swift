//
//  HolidayService.swift
//  Luca
//
//  Created by Kiro on 17/12/25.
//

import Foundation

/// Service for loading and managing public holidays from JSON configuration
class HolidayService {
    
    // MARK: - Private Properties
    /// Cache for Vietnamese holiday data organized by year
    private var holidayCache: [String: [Event]] = [:]
    
    /// Queue for thread-safe cache operations
    private let cacheQueue = DispatchQueue(label: "com.luca.holiday.cache", attributes: .concurrent)
    
    /// Buddhist-related holiday names that should be categorized as religious
    private static let buddhistHolidayNames: Set<String> = [
        "Lễ Phật Đản",
        "Lễ Vu Lan",
        "Lễ Quan Âm",
        "Lễ Quan Âm Thành Đạo",
        "Lễ Quan Âm Xuất Gia"
    ]
    
    /// Only Tết Nguyên Đán is considered a public holiday
    private static let publicHolidayNames: Set<String> = [
        "Tết Nguyên Đán"
    ]
    
    /// Monthly ceremony names (Cúng Rằm)
    private static let monthlyCeremonyNames: Set<String> = [
        "Cúng Rằm"
    ]
    
    /// Names of all events seeded from templates (for cleanup on reseed).
    /// Legacy month-suffixed titles kept for cleaning up old seeded data.
    static var preseededEventNames: Set<String> {
        let vietnameseMonths = ["Giêng", "Hai", "Ba", "Tư", "Năm", "Sáu", "Bảy", "Tám", "Chín", "Mười", "Mười Một", "Chạp"]
        let legacyMongMotTitles = (1...12).map { "Cúng Mồng Một Tháng \(vietnameseMonths[$0 - 1])" }
        let legacyRamTitles = (1...12).map { "Cúng Rằm Tháng \(vietnameseMonths[$0 - 1])" }
        return Set(legacyMongMotTitles + legacyRamTitles + ["Cúng Mồng Một", "Cúng Rằm", "Cúng Rằm Tháng Nhuận", "Cúng Mồng Một Tháng Nhuận"])
            .union(VietnameseCalendar.publicHolidayTemplates.map(\.name))
    }
    
    private static func category(for holidayName: String) -> EventCategory {
        buddhistHolidayNames.contains(holidayName) ? .religious : .cultural
    }
    
    private static func isPublicHoliday(_ holidayName: String) -> Bool {
        publicHolidayNames.contains(holidayName)
    }
    
    /// Load public holidays for a specific Vietnamese lunar year
    func loadPublicHolidays(year: Int) -> [Event] {
        let cacheKey = "\(year)"
        
        return cacheQueue.sync {
            if let cachedHolidays = holidayCache[cacheKey] {
                return cachedHolidays
            }
            
            let holidays = generateHolidays(year: year)
            
            cacheQueue.async(flags: .barrier) {
                self.holidayCache[cacheKey] = holidays
            }
            
            return holidays
        }
    }
    
    /// Clear holiday cache
    func clearCache() {
        cacheQueue.async(flags: .barrier) {
            self.holidayCache.removeAll()
        }
    }
    
    /// Seed public holidays to Core Data — one event per template as yearly recurring.
    /// Cúng Mồng Một is NOT seeded; it is generated dynamically by the calendar view model.
    func seedPublicHolidays(to dataManager: DataManager, from fromYear: Int, to toYear: Int) async throws {
        try await dataManager.deleteEvents(withTitles: Self.preseededEventNames)
        
        let templates = VietnameseCalendar.publicHolidayTemplates
        let now = Date()
        let templateEvents: [Event] = templates.map { holiday in
            let bestYear = nearestYearWithOccurrence(
                for: holiday,
                targetDate: now,
                fromYear: fromYear,
                toYear: toYear
            )
            let lunarDate = LunarDate(
                year: bestYear,
                month: holiday.lunarMonth,
                day: holiday.lunarDay,
                isLeapMonth: holiday.isLeapMonth
            )
            return Event(
                title: holiday.name,
                description: holiday.description,
                lunarDate: lunarDate,
                category: Self.category(for: holiday.name),
                isPublicHoliday: Self.isPublicHoliday(holiday.name),
                recurrence: .yearly,
                reminderSettings: [],
                duration: holiday.duration
            )
        }

        try await dataManager.saveEvents(templateEvents)
    }
    
    /// Pick the lunar year whose Gregorian occurrence is closest to (and preferably after) `targetDate`.
    private func nearestYearWithOccurrence(for holiday: PublicHoliday,
                                           targetDate: Date,
                                           fromYear: Int,
                                           toYear: Int) -> Int {
        var bestYear = fromYear
        var smallestDiff = TimeInterval.greatestFiniteMagnitude

        for year in fromYear...toYear {
            let ld = LunarDate(year: year, month: holiday.lunarMonth,
                               day: holiday.lunarDay, isLeapMonth: holiday.isLeapMonth)
            let occurrenceDate = ld.toGregorian()
            let diff = occurrenceDate.timeIntervalSince(targetDate)
            if diff >= 0 {
                let absDiff = abs(diff)
                if absDiff < smallestDiff {
                    smallestDiff = absDiff
                    bestYear = year
                }
            }
        }

        return bestYear
    }
    
    /// Generate Vietnamese holiday events for a specific year
    private func generateHolidays(year: Int) -> [Event] {
        VietnameseCalendar.publicHolidayTemplates.map { holiday in
            let lunarDate = LunarDate(
                year: year,
                month: holiday.lunarMonth,
                day: holiday.lunarDay,
                isLeapMonth: holiday.isLeapMonth
            )
            
            return Event(
                title: holiday.name,
                description: holiday.description,
                lunarDate: lunarDate,
                category: Self.category(for: holiday.name),
                isPublicHoliday: Self.isPublicHoliday(holiday.name),
                recurrence: .yearly,
                duration: holiday.duration
            )
        }
    }
}

/// Calculate Vietnamese holidays that vary by year (leap month ceremonies)
extension HolidayService {
    func calculateVariableHolidays(year: Int) -> [Event] {
        var holidays: [Event] = []
        let leapInfo = LunarCalendarConverter.getLeapMonthInfo(year)

        guard leapInfo.hasLeap else { return holidays }

        let leapMonth = leapInfo.leapMonth

        holidays.append(Event(
            title: "Cúng Mồng Một",
            description: "Lễ cúng đặc biệt cho tháng nhuận - được xem là đặc biệt may mắn",
            lunarDate: LunarDate(year: year, month: leapMonth, day: 1, isLeapMonth: true),
            category: .cultural,
            isPublicHoliday: false,
            duration: 1,
            ceremonyMonth: leapMonth
        ))

        holidays.append(Event(

            title: "Cúng Rằm",
            description: "Lễ cúng rằm đặc biệt cho tháng nhuận - cầu nguyện thêm cho sự thịnh vượng",
            lunarDate: LunarDate(year: year, month: leapMonth, day: 15, isLeapMonth: true),
            category: .religious,
            isPublicHoliday: false,
            duration: 2
        ))

        return holidays
    }
}
