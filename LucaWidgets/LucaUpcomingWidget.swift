import SwiftUI
import WidgetKit

struct LucaWidgetEntry: TimelineEntry {
    let date: Date
    let snapshot: LucaWidgetSnapshot?
    let quickAddURL: URL?
}

struct LucaWidgetProvider: TimelineProvider {
    func placeholder(in context: Context) -> LucaWidgetEntry {
        LucaWidgetEntry(
            date: Date(),
            snapshot: nil,
            quickAddURL: LucaWidgetSharedStore.createQuickAddURL()
        )
    }

    func getSnapshot(in context: Context, completion: @escaping (LucaWidgetEntry) -> Void) {
        completion(currentEntry())
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<LucaWidgetEntry>) -> Void) {
        let now = Date()
        let nextRefresh = Calendar.current.date(byAdding: .minute, value: 30, to: now) ?? now
        let timeline = Timeline(entries: [currentEntry()], policy: .after(nextRefresh))
        completion(timeline)
    }

    private func currentEntry() -> LucaWidgetEntry {
        let snapshot = LucaWidgetSharedStore.loadSnapshot()
        let quickAddURL = LucaWidgetSharedStore.createQuickAddURL()
        return LucaWidgetEntry(date: Date(), snapshot: snapshot, quickAddURL: quickAddURL)
    }
}

struct LucaUpcomingWidgetView: View {
    var entry: LucaWidgetProvider.Entry

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 6) {
                Image(systemName: "calendar.circle.fill")
                    .foregroundStyle(.secondary)
                Text("Hôm nay".uppercased())
                    .font(.headline.weight(.semibold))
                    .foregroundStyle(.secondary)
            }

            if let todayEventTitle = entry.snapshot?.todayEventTitle,
               !todayEventTitle.isEmpty {
                Text(todayEventTitle)
                    .font(.body.weight(.semibold))
                    .lineLimit(2)
            } else {
                Text("Không có sự kiện nào")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
                Spacer()
                if let quickAddURL = entry.quickAddURL {
                    Link(destination: quickAddURL) {
                        Text("Tạo sự kiện")
                            .font(.footnote.weight(.semibold))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 6)
                            .background(Color.accentColor.opacity(0.16))
                            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                    }
                    .buttonStyle(.plain)
                }
            }

            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .containerBackground(for: .widget) {
            ZStack {
                Color(.tertiarySystemFill)
                Image("WidgetBackgroundIcon")
                    .resizable()
                    .scaledToFill()
                    .opacity(0.12)
            }
        }
    }
}

struct LucaUpcomingWidget: Widget {
    let kind: String = "LucaUpcomingWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: LucaWidgetProvider()) { entry in
            LucaUpcomingWidgetView(entry: entry)
        }
        .configurationDisplayName("Luca Sắp tới")
        .description("Xem nhanh sự kiện sắp tới và tạo sự kiện mới.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}
