import SwiftUI

extension Color {
    // MARK: - Brand Colors
    static let appAccent = Color.accentColor
    static let appRed = Color.red
    static let appOrange = Color.orange

    // MARK: - Category Colors
    static func categoryColor(_ category: EventCategory) -> Color {
        switch category {
        case .personal:  return .blue
        case .cultural:  return .purple
        case .religious: return .indigo
        }
    }

    // MARK: - Calendar Colors
    static let calendarTodayBackground = Color.accentColor
    static let calendarSelectedBackground = Color.accentColor.opacity(0.12)
    static let calendarHolidayText = Color.red
    static let calendarOutOfMonth = Color.secondary.opacity(0.25)

    // MARK: - Card / Chip Colors
    static func chipBackground(_ category: EventCategory?, isSelected: Bool) -> Color {
        let base = category.map { Color.categoryColor($0) } ?? .accentColor
        return isSelected ? base : base.opacity(0.12)
    }
}
