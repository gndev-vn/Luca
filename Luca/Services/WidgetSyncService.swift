import Foundation

#if canImport(WidgetKit)
import WidgetKit
#endif

struct WidgetUpcomingEvent: Codable {
    let id: UUID
    let title: String
    let date: Date
}

struct WidgetSnapshot: Codable {
    let generatedAt: Date
    let todayCount: Int
    let todayEventTitle: String?
    let upcoming: [WidgetUpcomingEvent]
}

enum WidgetDeepLinkBuilder {
    static func createEventURL(for date: Date = Date()) -> URL? {
        var components = URLComponents()
        components.scheme = "luca"
        components.host = ""
        components.path = "/create"
        components.queryItems = [
            URLQueryItem(name: "date", value: String(date.timeIntervalSince1970))
        ]
        return components.url
    }
}

@MainActor
final class WidgetSyncService {
    static let shared = WidgetSyncService()
    static let appGroupIdentifier = "group.dev.gndev.luca"
    static let snapshotStorageKey = "widget.snapshot.v1"

    private let calendar = Calendar.current
    private let encoder = JSONEncoder()

    private init() {}

    func updateSnapshot(with events: [Event]) {
        let now = Date()
        let today = calendar.startOfDay(for: now)
        let upcomingWindowEnd = calendar.date(byAdding: .day, value: 30, to: today) ?? today
        let activeEvents = events.filter(\.isEnabled)

        let todayCount = activeEvents.filter { $0.occurs(on: today) }.count
        let todayEventTitle = activeEvents
            .filter { $0.occurs(on: today) }
            .sorted { $0.title.localizedCaseInsensitiveCompare($1.title) == .orderedAscending }
            .first?
            .title

        let upcomingEvents = activeEvents
            .compactMap { event -> WidgetUpcomingEvent? in
                guard let date = firstOccurrenceDate(for: event, from: today, to: upcomingWindowEnd) else {
                    return nil
                }
                return WidgetUpcomingEvent(id: event.id, title: event.title, date: date)
            }
            .sorted { $0.date < $1.date }

        let snapshot = WidgetSnapshot(
            generatedAt: now,
            todayCount: todayCount,
            todayEventTitle: todayEventTitle,
            upcoming: Array(upcomingEvents.prefix(5))
        )

        guard let data = try? encoder.encode(snapshot) else { return }
        let sharedDefaults = UserDefaults(suiteName: Self.appGroupIdentifier) ?? .standard
        sharedDefaults.set(data, forKey: Self.snapshotStorageKey)

        #if canImport(WidgetKit)
        WidgetCenter.shared.reloadAllTimelines()
        #endif
    }

    private func firstOccurrenceDate(for event: Event, from start: Date, to end: Date) -> Date? {
        let totalDays = calendar.dateComponents([.day], from: start, to: end).day ?? 0
        guard totalDays >= 0 else { return nil }

        for offset in 0...totalDays {
            guard let candidate = calendar.date(byAdding: .day, value: offset, to: start) else { continue }
            if event.occurs(on: candidate) {
                return candidate
            }
        }
        return nil
    }
}
