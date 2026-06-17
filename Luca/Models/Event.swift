//
//  Event.swift
//  Luca
//
//  Created by Kiro on 16/12/25.
//

import Foundation
import SwiftUI
import Combine

/// Categories for events
enum EventCategory: String, CaseIterable, Codable {
    case personal = "personal"
    case cultural = "cultural"
    case religious = "religious"
    
    var displayName: String {
        switch self {
        case .personal: return String.localized(.categoryPersonal)
        case .cultural: return String.localized(.categoryCultural)
        case .religious: return String.localized(.categoryReligious)
        }
    }
}

/// Types of reminders for events
enum ReminderType: String, CaseIterable, Codable {
    case onDay = "on_day"
    case oneDayBefore = "one_day_before"
    case twoDaysBefore = "two_days_before"
    case threeDaysBefore = "three_days_before"
    
    var displayName: String {
        switch self {
        case .onDay: return String.localized(.reminderOnDay)
        case .oneDayBefore: return String.localized(.reminderOneDayBefore)
        case .twoDaysBefore: return String.localized(.reminderTwoDaysBefore)
        case .threeDaysBefore: return String.localized(.reminderThreeDaysBefore)
        }
    }
    
    var daysOffset: Int {
        switch self {
        case .onDay: return 0
        case .oneDayBefore: return -1
        case .twoDaysBefore: return -2
        case .threeDaysBefore: return -3
        }
    }
}

/// How often an event repeats
enum RecurrenceType: String, CaseIterable, Codable {
    case none = "none"
    case daily = "daily"
    case weekly = "weekly"
    case monthly = "monthly"
    case yearly = "yearly"
    
    var displayName: String {
        switch self {
        case .none: return String.localized(.recurrenceNone)
        case .daily: return String.localized(.recurrenceDaily)
        case .weekly: return String.localized(.recurrenceWeekly)
        case .monthly: return String.localized(.recurrenceMonthly)
        case .yearly: return String.localized(.recurrenceYearly)
        }
    }
    
    var isRepeating: Bool { self != .none }
}

/// Represents an event in the lunar calendar
class Event: ObservableObject, Identifiable, Codable {
    let id: UUID
    @Published var title: String
    @Published var description: String
    @Published var tags: [String]
    @Published var lunarDate: LunarDate
    @Published var gregorianDate: Date
    @Published var category: EventCategory
    @Published var isPublicHoliday: Bool
    @Published var recurrence: RecurrenceType
    @Published var reminderSettings: [ReminderType]
    @Published var soundEnabled: Bool
    @Published var vibrationEnabled: Bool
    @Published var notificationTime: Date
    @Published var notificationSoundName: String?
    @Published var duration: Int
    
    /// For ceremony events that span month boundaries (e.g., Cúng Mồng Một).
    /// When non-nil, the event displays on the last day of (ceremonyMonth - 1)
    /// AND the first day of ceremonyMonth.
    @Published var ceremonyMonth: Int?
    
    /// Human-readable recurrence description for display in event lists
    var recurrenceDescription: String {
        switch recurrence {
        case .none:
            return ""
        case .daily:
            return String.localized(.recurrenceDaily)
        case .weekly:
            let dayName = LocalizedStringService.shared.localizedWeekdayFull(lunarDate.day)
            return String(format: String.localized(.recurrenceWeeklyFormat), dayName)
        case .monthly:
            let format = String.localized(.recurrenceMonthlyFormat)
            return String(format: format, lunarDate.day)
        case .yearly:
            let format = String.localized(.recurrenceYearlyFormat)
            return String(format: format, lunarDate.day, lunarDate.month)
        }
    }
    
    /// Computed property to check if the event is valid
    var isValid: Bool {
        return !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && lunarDate.isValid()
    }
    
    /// Check if the event occurs on a given date (respects recurrence + duration + ceremony month)
    func occurs(on date: Date) -> Bool {
        let calendar = Calendar.current
        let target = calendar.startOfDay(for: date)
        
        // Ceremony events span month boundaries — check ceremony month first
        if let ceremonyMonth {
            let targetLunar = LunarDate.fromGregorian(date)
            let prevMonth = ceremonyMonth == 1 ? 12 : ceremonyMonth - 1
            let prevMonthDays = LunarCalendarConverter.daysInLunarMonth(
                year: targetLunar.year,
                month: prevMonth,
                isLeapMonth: false
            )
            // Show on last day of previous month (ceremony start) — prev month is always regular
            if !targetLunar.isLeapMonth && targetLunar.day == prevMonthDays && targetLunar.month == prevMonth {
                return true
            }
            // Show on first day of ceremony month — matches the event's leap status
            if targetLunar.day == 1 && targetLunar.month == ceremonyMonth && targetLunar.isLeapMonth == lunarDate.isLeapMonth {
                return true
            }
            return false
        }

        switch recurrence {
        case .none:
            let start = calendar.startOfDay(for: gregorianDate)
            guard let end = calendar.date(byAdding: .day, value: duration, to: start) else {
                return calendar.isDate(gregorianDate, inSameDayAs: date)
            }
            return target >= start && target < end

        case .daily:
            return true

        case .weekly:
            return calendar.component(.weekday, from: date) == lunarDate.day

        case .monthly:
            let targetLunar = LunarDate.fromGregorian(date)
            return lunarDate.day == targetLunar.day

        case .yearly:
            let targetLunar = LunarDate.fromGregorian(date)
            let eventLunar = lunarDate

            let daysInEventYear = LunarCalendarConverter.daysInLunarMonth(
                year: eventLunar.year,
                month: eventLunar.month,
                isLeapMonth: eventLunar.isLeapMonth
            )
            let daysInTargetYear = LunarCalendarConverter.daysInLunarMonth(
                year: targetLunar.year,
                month: eventLunar.month,
                isLeapMonth: eventLunar.isLeapMonth
            )

            // If the event was on the last day of its month in the event year,
            // use the last day of the target year too (handles variable month lengths)
            let projectedDay: Int
            if eventLunar.day == daysInEventYear {
                projectedDay = daysInTargetYear
            } else if eventLunar.day > daysInTargetYear {
                projectedDay = daysInTargetYear
            } else {
                projectedDay = eventLunar.day
            }

            let projected = LunarDate(
                year: targetLunar.year,
                month: eventLunar.month,
                day: projectedDay,
                isLeapMonth: eventLunar.isLeapMonth
            )
            guard LunarCalendarConverter.validateLunarDate(
                year: projected.year,
                month: projected.month,
                day: projected.day,
                isLeapMonth: projected.isLeapMonth
            ) else { return false }
            let projectedGregorian = projected.toGregorian()
            let start = calendar.startOfDay(for: projectedGregorian)
            guard let end = calendar.date(byAdding: .day, value: duration, to: start) else {
                return calendar.isDate(projectedGregorian, inSameDayAs: date)
            }
            return target >= start && target < end
        }
    }
    
    init(
        id: UUID = UUID(),
        title: String,
        description: String = "",
        tags: [String] = [],
        lunarDate: LunarDate,
        gregorianDate: Date? = nil,
        category: EventCategory = .personal,
        isPublicHoliday: Bool = false,
        recurrence: RecurrenceType = .none,
        reminderSettings: [ReminderType] = [],
        soundEnabled: Bool = true,
        vibrationEnabled: Bool = true,
        notificationTime: Date? = nil,
        notificationSoundName: String? = nil,
        duration: Int = 1,
        ceremonyMonth: Int? = nil
    ) {
        self.id = id
        self.title = title
        self.description = description
        self.tags = tags
        self.lunarDate = lunarDate
        self.gregorianDate = gregorianDate ?? lunarDate.toGregorian()
        self.category = category
        self.isPublicHoliday = isPublicHoliday
        self.recurrence = recurrence
        self.reminderSettings = reminderSettings
        self.soundEnabled = soundEnabled
        self.vibrationEnabled = vibrationEnabled
        self.notificationTime = notificationTime ?? Self.defaultNotificationTime
        self.notificationSoundName = notificationSoundName
        self.duration = duration
        self.ceremonyMonth = ceremonyMonth
    }
    
    static var defaultNotificationTime: Date {
        var components = Calendar.current.dateComponents([.year, .month, .day], from: Date())
        components.hour = 6
        components.minute = 0
        return Calendar.current.date(from: components) ?? Date()
    }
    
    /// Create an Event from Core Data EventEntity
    /// - Parameter entity: The Core Data entity
    /// - Returns: Event instance
    static func fromEntity(_ entity: EventEntity) -> Event {
        let lunarDate = LunarDate(
            year: Int(entity.lunarYear),
            month: Int(entity.lunarMonth),
            day: Int(entity.lunarDay),
            isLeapMonth: entity.isLeapMonth
        )
        
        let category = EventCategory(rawValue: entity.category ?? "personal") ?? .personal
        let reminderTypes: [ReminderType] = entity.reminders?.compactMap { reminder in
            guard let reminderEntity = reminder as? ReminderEntity,
                  let typeString = reminderEntity.type else { return nil }
            return ReminderType(rawValue: typeString)
        } ?? []
        
        return Event(
            id: entity.id ?? UUID(),
            title: entity.title ?? "",
            description: entity.eventDescription ?? "",
            lunarDate: lunarDate,
            gregorianDate: entity.gregorianDate,
            category: category,
            isPublicHoliday: entity.isPublicHoliday,
            recurrence: entity.isRecurring ? .yearly : .none,
            reminderSettings: reminderTypes,
            soundEnabled: entity.soundEnabled,
            vibrationEnabled: entity.vibrationEnabled,
            notificationTime: entity.notificationTime,
            notificationSoundName: entity.notificationSoundName,
            duration: Int(entity.duration),
            ceremonyMonth: nil
        )
    }
    
    /// Convert this Event to Core Data EventEntity properties
    /// - Parameter entity: The Core Data entity to update
    func updateEntity(_ entity: EventEntity) {
        entity.id = self.id
        entity.title = self.title
        entity.eventDescription = self.description
        entity.lunarYear = Int32(self.lunarDate.year)
        entity.lunarMonth = Int32(self.lunarDate.month)
        entity.lunarDay = Int32(self.lunarDate.day)
        entity.isLeapMonth = self.lunarDate.isLeapMonth
        entity.gregorianDate = self.gregorianDate
        entity.category = self.category.rawValue
        entity.isPublicHoliday = self.isPublicHoliday
        entity.isRecurring = self.recurrence.isRepeating
        entity.soundEnabled = self.soundEnabled
        entity.vibrationEnabled = self.vibrationEnabled
        entity.notificationTime = self.notificationTime
        entity.notificationSoundName = self.notificationSoundName
        entity.duration = Int32(self.duration)
        entity.updatedAt = Date()
        
        if entity.createdAt == nil {
            entity.createdAt = Date()
        }
    }
    
    // MARK: - Codable Implementation
    enum CodingKeys: String, CodingKey {
        case id, title, description, tags, lunarDate, gregorianDate, category, isPublicHoliday, recurrence, reminderSettings, soundEnabled, vibrationEnabled, notificationTime, notificationSoundName, duration, ceremonyMonth
        case oldIsRecurring = "isRecurring"
    }

    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        title = try container.decode(String.self, forKey: .title)
        description = try container.decode(String.self, forKey: .description)
        tags = try container.decodeIfPresent([String].self, forKey: .tags) ?? []
        let decodedLunarDate = try container.decode(LunarDate.self, forKey: .lunarDate)
        lunarDate = decodedLunarDate
        let decodedGregorian = try container.decodeIfPresent(Date.self, forKey: .gregorianDate)
        gregorianDate = decodedGregorian ?? decodedLunarDate.toGregorian()
        category = try container.decode(EventCategory.self, forKey: .category)
        isPublicHoliday = try container.decode(Bool.self, forKey: .isPublicHoliday)
        if let rec = try container.decodeIfPresent(RecurrenceType.self, forKey: .recurrence) {
            recurrence = rec
        } else if let oldVal = try container.decodeIfPresent(Bool.self, forKey: .oldIsRecurring) {
            recurrence = oldVal ? .yearly : .none
        } else {
            recurrence = .none
        }
        reminderSettings = try container.decode([ReminderType].self, forKey: .reminderSettings)
        soundEnabled = try container.decodeIfPresent(Bool.self, forKey: .soundEnabled) ?? true
        vibrationEnabled = try container.decodeIfPresent(Bool.self, forKey: .vibrationEnabled) ?? true
        notificationTime = try container.decodeIfPresent(Date.self, forKey: .notificationTime) ?? Self.defaultNotificationTime
        notificationSoundName = try container.decodeIfPresent(String.self, forKey: .notificationSoundName)
        duration = try container.decodeIfPresent(Int.self, forKey: .duration) ?? 1
        ceremonyMonth = try container.decodeIfPresent(Int.self, forKey: .ceremonyMonth)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(title, forKey: .title)
        try container.encode(description, forKey: .description)
        try container.encode(tags, forKey: .tags)
        try container.encode(lunarDate, forKey: .lunarDate)
        try container.encode(gregorianDate, forKey: .gregorianDate)
        try container.encode(category, forKey: .category)
        try container.encode(isPublicHoliday, forKey: .isPublicHoliday)
        try container.encode(recurrence, forKey: .recurrence)
        try container.encode(reminderSettings, forKey: .reminderSettings)
        try container.encode(soundEnabled, forKey: .soundEnabled)
        try container.encode(vibrationEnabled, forKey: .vibrationEnabled)
        try container.encode(notificationTime, forKey: .notificationTime)
        try container.encodeIfPresent(notificationSoundName, forKey: .notificationSoundName)
        try container.encode(duration, forKey: .duration)
        try container.encodeIfPresent(ceremonyMonth, forKey: .ceremonyMonth)
    }
}
