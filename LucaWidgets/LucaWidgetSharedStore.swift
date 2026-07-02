import Foundation

struct LucaWidgetUpcomingEvent: Codable {
    let id: UUID
    let title: String
    let date: Date
}

struct LucaWidgetSnapshot: Codable {
    let generatedAt: Date
    let todayCount: Int
    let todayEventTitle: String?
    let upcoming: [LucaWidgetUpcomingEvent]
}

enum LucaWidgetSharedStore {
    static let appGroupIdentifier = "group.dev.gndev.luca"
    static let snapshotStorageKey = "widget.snapshot.v1"

    static func loadSnapshot() -> LucaWidgetSnapshot? {
        let defaults = UserDefaults(suiteName: appGroupIdentifier) ?? .standard
        guard let data = defaults.data(forKey: snapshotStorageKey) else { return nil }
        return try? JSONDecoder().decode(LucaWidgetSnapshot.self, from: data)
    }

    static func createQuickAddURL(for date: Date = Date()) -> URL? {
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
