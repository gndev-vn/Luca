import SwiftUI

/// Filter mode for the event list
enum EventFilter: Hashable {
    case upcoming
    case today
    case category(EventCategory)
}

/// View for displaying and managing a list of events with search functionality
struct EventListView: View {
    @ObservedObject var viewModel: EventViewModel
    @Environment(\.accessibilityManager) private var accessibilityManager
    @State private var searchText = ""
    @State private var eventFilter: EventFilter = .today
    @State private var activeSheet: EventListSheet?
    
    private let lunarCalendarService: LunarCalendarService
    
    init(viewModel: EventViewModel,
         lunarCalendarService: LunarCalendarService) {
        self.viewModel = viewModel
        self.lunarCalendarService = lunarCalendarService
    }
    
    
    var body: some View {
        VStack(spacing: 0) {
            // Search Bar
            VStack(spacing: 12) {
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.secondary)
                    
                    TextField(String.localized(.searchEvents), text: $searchText)
                        .textFieldStyle(PlainTextFieldStyle())
                        .accessibilityLabel("Search events")
                        .accessibilityHint("Enter text to search through your events")
                    
                    if !searchText.isEmpty {
                        Button(action: { searchText = "" }) {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(.secondary)
                        }
                    }
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(Color(.systemGray6))
                .cornerRadius(10)
                
                // Filter tabs
                ScrollViewReader { proxy in
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 6) {
                            let filters: [EventFilter] = [.today, .upcoming, .category(.personal), .category(.cultural), .category(.religious)]
                            ForEach(filters, id: \.self) { filter in
                                Button {
                                    withAnimation { eventFilter = filter }
                                } label: {
                                    HStack(spacing: 4) {
                                        Image(systemName: filterIcon(for: filter))
                                            .font(.caption2)
                                        Text(filterLabel(for: filter))
                                            .font(.caption)
                                            .fontWeight(.semibold)
                                    }
                                    .foregroundColor(eventFilter == filter ? .white : filterColor(for: filter))
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 6)
                                    .background(
                                        eventFilter == filter
                                            ? AnyView(filterColor(for: filter))
                                            : AnyView(filterColor(for: filter).opacity(0.12))
                                    )
                                    .cornerRadius(14)
                                }
                                .buttonStyle(.plain)
                                .id(filter)
                            }
                        }
                    }
                    .onChange(of: eventFilter) { _, newFilter in
                        withAnimation { proxy.scrollTo(newFilter, anchor: .center) }
                    }
                }
                .simultaneousGesture(
                    DragGesture(minimumDistance: 30)
                        .onEnded { value in
                            let threshold: CGFloat = 50
                            guard abs(value.translation.width) > threshold else { return }
                            let filters: [EventFilter] = [.today, .upcoming, .category(.personal), .category(.cultural), .category(.religious)]
                            guard let currentIndex = filters.firstIndex(of: eventFilter) else { return }
                            if value.translation.width < 0, currentIndex < filters.count - 1 {
                                withAnimation { eventFilter = filters[currentIndex + 1] }
                            } else if value.translation.width > 0, currentIndex > 0 {
                                withAnimation { eventFilter = filters[currentIndex - 1] }
                            }
                        }
                )
            }
            .padding()
            .background(Color(.systemBackground))
            
            Divider()
            
            // Page content
            eventsPage(for: eventFilter)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .navigationTitle(String.localized(.events))
        .navigationBarTitleDisplayMode(.large)
        .refreshable {
            let impactFeedback = UIImpactFeedbackGenerator(style: .light)
            impactFeedback.impactOccurred()
            
            await viewModel.loadEvents()
        }
        .task {
            await viewModel.loadEvents()
        }
        .sheet(item: $activeSheet) { sheet in
            switch sheet {
            case .createForm:
                EventFormView(
                    viewModel: viewModel,
                    lunarCalendarService: lunarCalendarService
                )
            case .editForm(let event):
                EventFormView(
                    viewModel: viewModel,
                    event: event,
                    lunarCalendarService: lunarCalendarService
                )
            case .deleteConfirmation(let event):
                ConfirmationBottomSheet(
                    title: String.localized(.deleteEventConfirmation),
                    message: String(format: String.localized(.deleteEventMessage), event.title),
                    buttonTitle: String.localized(.delete),
                    buttonRole: .destructive,
                    isPresented: Binding(
                        get: { activeSheet != nil },
                        set: { if !$0 { activeSheet = nil } }
                    )
                ) {
                    Task {
                        await viewModel.deleteEvent(event)
                    }
                }
            }
        }
    }
    
    // MARK: - Swipeable Pages
    
    private func eventsPage(for filter: EventFilter) -> some View {
        let events = filteredEvents(for: filter)
        
        return Group {
            if viewModel.isLoading {
                ProgressView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if events.isEmpty {
                EmptyEventsView(
                    hasEvents: !viewModel.events.isEmpty,
                    searchText: searchText,
                    eventFilter: filter,
                    onCreateEvent: { activeSheet = .createForm }
                )
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                List {
                    ForEach(events) { event in
                        EventRowView(
                            event: event,
                            onTap: { editEvent(event) },
                            onDelete: { deleteEvent(event) }
                        )
                        .listRowInsets(EdgeInsets(top: 6, leading: 12, bottom: 6, trailing: 12))
                        .listRowSeparator(.hidden)
                        .listRowBackground(Color.clear)
                        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                            Button(role: .destructive) {
                                let impactFeedback = UIImpactFeedbackGenerator(style: .heavy)
                                impactFeedback.impactOccurred()
                                deleteEvent(event)
                            } label: {
                                Label(String.localized(.delete), systemImage: "trash")
                            }
                            .tint(.red)
                            
                            Button {
                                let impactFeedback = UIImpactFeedbackGenerator(style: .light)
                                impactFeedback.impactOccurred()
                                editEvent(event)
                            } label: {
                                Label(String.localized(.edit), systemImage: "pencil")
                            }
                            .tint(.blue)
                        }
                        .swipeActions(edge: .leading, allowsFullSwipe: false) {
                            if !event.reminderSettings.isEmpty {
                                Button {
                                    let impactFeedback = UIImpactFeedbackGenerator(style: .light)
                                    impactFeedback.impactOccurred()
                                    Task {
                                        await viewModel.toggleReminders(for: event)
                                    }
                                } label: {
                                    Label(String.localized(.reminders), systemImage: "bell.slash")
                                }
                                .tint(.orange)
                            } else {
                                Button {
                                    let impactFeedback = UIImpactFeedbackGenerator(style: .light)
                                    impactFeedback.impactOccurred()
                                    Task {
                                        await viewModel.toggleReminders(for: event)
                                    }
                                } label: {
                                    Label(String.localized(.reminders), systemImage: "bell")
                                }
                                .tint(.orange)
                            }
                        }
                    }
                }
                .listStyle(PlainListStyle()).padding(.top, 6)
            }
        }
    }
    
    /// Filter events for a specific filter
    private func filteredEvents(for filter: EventFilter) -> [Event] {
        var events = viewModel.events
        let now = Calendar.current.startOfDay(for: Date())
        
        switch filter {
        case .today:
            events = events.filter { event in
                event.occurs(on: now)
            }
        case .upcoming:
            events = events.filter { event in
                for dayOffset in 1..<8 {
                    if let date = Calendar.current.date(byAdding: .day, value: dayOffset, to: now),
                       event.occurs(on: date) {
                        return true
                    }
                }
                return false
            }
        case .category(let category):
            events = events.filter { event in
                event.category == category
            }
        }
        
        // Filter by search text
        if !searchText.isEmpty {
            let query = searchText.lowercased()
            events = events.filter { event in
                let matchesTitleDescription = event.title.localizedCaseInsensitiveContains(query) ||
                    event.description.localizedCaseInsensitiveContains(query)
                let matchesTags = event.tags.contains { $0.localizedCaseInsensitiveContains(query) }
                let matchesLunarDate = String(format: String.localized(.lunarDateSearchFormat), event.lunarDate.day, event.lunarDate.month, event.lunarDate.traditionalYear).localizedCaseInsensitiveContains(query)
                let matchesGregorian = SharedDateFormatters.mediumDateVi.string(from: event.gregorianDate).localizedCaseInsensitiveContains(query)
                return matchesTitleDescription || matchesTags || matchesLunarDate || matchesGregorian
            }
        }
        
        // Deduplicate recurring events — show only one entry per ceremony base name
        var seenRecurring: Set<String> = []
        var deduplicated: [Event] = []
        let sorted = events.sorted { $0.gregorianDate < $1.gregorianDate }
        
        for event in sorted {
            let key: String
            if event.recurrence.isRepeating {
                key = "\(ceremonyBaseName(event.title))-\(event.recurrence.rawValue)"
            } else if event.ceremonyMonth != nil {
                key = ceremonyBaseName(event.title)
            } else {
                key = event.id.uuidString
            }
            if seenRecurring.contains(key) {
                continue
            }
            seenRecurring.insert(key)
            deduplicated.append(event)
        }
        
        return deduplicated.sorted { $0.gregorianDate < $1.gregorianDate }
    }
    
    // MARK: - Filter Display Helpers
    
    private func filterIcon(for filter: EventFilter) -> String {
        switch filter {
        case .today: return "sun.max.fill"
        case .upcoming: return "clock.fill"
        case .category(.personal): return "person.fill"
        case .category(.cultural): return "star.fill"
        case .category(.religious): return "book.fill"
        }
    }
    
    private func filterColor(for filter: EventFilter) -> Color {
        switch filter {
        case .today: return .orange
        case .upcoming: return .accentColor
        case .category(.personal): return .blue
        case .category(.cultural): return .purple
        case .category(.religious): return .indigo
        }
    }
    
    private func filterLabel(for filter: EventFilter) -> String {
        switch filter {
        case .today: return String.localized(.today)
        case .upcoming: return String.localized(.upcomingEvents)
        case .category(let category): return category.displayName
        }
    }
    
    // MARK: - Helper Methods
    
    private func editEvent(_ event: Event) {
        activeSheet = .editForm(event)
    }
    
    private func deleteEvent(_ event: Event) {
        activeSheet = .deleteConfirmation(event)
    }
    
    /// Strip month suffix from ceremony event titles so all monthly variants collapse to one entry
    private func ceremonyBaseName(_ title: String) -> String {
        let ceremonyPrefixes = ["Cúng Mồng Một", "Cúng Rằm"]
        for prefix in ceremonyPrefixes {
            if title.hasPrefix(prefix) {
                return prefix
            }
        }
        return title
    }
}

enum EventListSheet: Identifiable {
    case createForm
    case editForm(Event)
    case deleteConfirmation(Event)
    
    var id: String {
        switch self {
        case .createForm: return "createForm"
        case .editForm(let event): return "editForm-\(event.id)"
        case .deleteConfirmation(let event): return "deleteConfirmation-\(event.id)"
        }
    }
}

/// Individual event row with context menu
struct EventRowView: View {
    let event: Event
    let onTap: () -> Void
    let onDelete: () -> Void

    var body: some View {
        Button(action: {
            let impactFeedback = UIImpactFeedbackGenerator(style: .light)
            impactFeedback.impactOccurred()
            onTap()
        }) {
            HStack(spacing: 0) {
                VStack(alignment: .leading, spacing: 8) {
                    HStack(alignment: .top) {
                        VStack(alignment: .leading, spacing: 4) {
                            HStack(spacing: 6) {
                                Text(event.title)
                                    .font(.headline)
                                    .foregroundColor(.primary)
                                    .lineLimit(1)

                                if event.isPublicHoliday {
                                    Image(systemName: "star.fill")
                                        .font(.caption2)
                                        .foregroundColor(.red)
                                }

                                if !event.reminderSettings.isEmpty {
                                    Image(systemName: "bell.fill")
                                        .font(.caption2)
                                        .foregroundColor(.orange)
                                }
                            }

                            if !event.description.isEmpty {
                                Text(event.description)
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                    .lineLimit(2)
                                    .multilineTextAlignment(.leading)
                            }
                        }

                        Spacer()
                    }

                    HStack(spacing: 6) {
                        Text(event.category.displayName)
                            .font(.caption2)
                            .fontWeight(.medium)
                            .foregroundColor(categoryColor)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(categoryColor.opacity(0.12))
                            .cornerRadius(4)

                        if event.recurrence.isRepeating {
                            HStack(spacing: 3) {
                                Image(systemName: "repeat")
                                    .font(.caption2)
                                Text(event.recurrence.displayName)
                                    .font(.caption2)
                                    .fontWeight(.medium)
                            }
                            .foregroundColor(.accentColor)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.accentColor.opacity(0.1))
                            .cornerRadius(4)
                        }

                        Spacer()

                        Text(lunarDateString)
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }
                .padding(.leading, 12)
            }
            .padding(.trailing, 16)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color(.systemBackground))
            )
            .clipShape(RoundedRectangle(cornerRadius: 10))
            .shadow(color: .black.opacity(0.08), radius: 3, x: 0, y: 1)
        }
        .buttonStyle(InteractiveButtonStyle())
        .contextMenu {
            Button(action: {
                let impactFeedback = UIImpactFeedbackGenerator(style: .light)
                impactFeedback.impactOccurred()
                onTap()
            }) {
                Label(String.localized(.edit), systemImage: "pencil")
            }

            Button(role: .destructive, action: {
                let impactFeedback = UIImpactFeedbackGenerator(style: .heavy)
                impactFeedback.impactOccurred()
                onDelete()
            }) {
                Label(String.localized(.delete), systemImage: "trash")
            }
        }
    }

    private var categoryColor: Color {
        if event.isPublicHoliday { return .red }
        switch event.category {
        case .cultural: return .purple
        case .religious: return .indigo
        case .personal: return .accentColor
        }
    }

    private var lunarDateString: String {
        let lunar = event.lunarDate
        var text = "\(lunar.day)/\(lunar.month)"
        if lunar.isLeapMonth { text += " (nhuận)" }
        return text
    }
}

/// Filter chip
/// Empty state view
struct EmptyEventsView: View {
    let hasEvents: Bool
    let searchText: String
    let eventFilter: EventFilter
    let onCreateEvent: () -> Void
    
    var body: some View {
        VStack(spacing: 20) {
            Spacer()
            
            Image(systemName: hasEvents ? "magnifyingglass" : "calendar.badge.plus")
                .font(.system(size: 60))
                .foregroundColor(.secondary)
            
            VStack(spacing: 8) {
                Text(emptyStateTitle)
                    .font(.title2)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                
                Text(emptyStateMessage)
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
            }
            
            if !hasEvents {
                Button(action: onCreateEvent) {
                    HStack {
                        Image(systemName: "plus")
                        Text(localized: .createFirstEvent)
                    }
                    .font(.headline)
                    .foregroundColor(.white)
                    .padding()
                    .background(Color.accentColor)
                    .cornerRadius(12)
                }
                .padding(.top, 10)
            }
            
            Spacer()
        }
    }
    
    private var emptyStateTitle: String {
        if !searchText.isEmpty {
            return String.localized(.noResultsFound)
        }
        switch eventFilter {
        case .today:
            return String.localized(.noEventsToday)
        case .upcoming:
            return String.localized(.noEventsUpcoming)
        case .category:
            return String.localized(.noEventsInCategory)
        }
    }
    
    private var emptyStateMessage: String {
        if !searchText.isEmpty {
            return String.localized(.noResultsMessage)
        }
        switch eventFilter {
        case .today:
            if hasEvents {
                return String.localized(.noEventsFilterMessage)
            } else {
                return String.localized(.createFirstEventMessage)
            }
        case .upcoming:
            if hasEvents {
                return String.localized(.noEventsFilterMessage)
            } else {
                return String.localized(.createFirstEventMessage)
            }
        case .category(let category):
            if hasEvents {
                return String(format: String.localized(.noEventsInCategoryMessage), category.displayName)
            } else {
                return String.localized(.createFirstEventMessage)
            }
        }
    }
}

#Preview("Event List") {
    let viewModel = EventViewModel(
        dataManager: MockDataManager(),
        notificationManager: MockNotificationManager()
    )
    
    // Add some sample events
    viewModel.events = [
        Event(
            title: "Chinese New Year",
            description: "Spring Festival celebration with family",
            lunarDate: LunarDate(year: 41, month: 1, day: 1),
            category: .cultural,
            isPublicHoliday: true,
            reminderSettings: [.onDay, .oneDayBefore]
        ),
        Event(
            title: "Mid-Autumn Festival",
            description: "Moon viewing and mooncakes",
            lunarDate: LunarDate(year: 41, month: 8, day: 15),
            category: .cultural,
            isPublicHoliday: true
        )
    ]
    
    return EventListView(
        viewModel: viewModel,
        lunarCalendarService: MockLunarCalendarService()
    )
}

#Preview("Empty Event List") {
    return EventListView(
        viewModel: EventViewModel(
            dataManager: MockDataManager(),
            notificationManager: MockNotificationManager()
        ),
        lunarCalendarService: MockLunarCalendarService()
    )
}

/// Interactive button style with visual feedback
struct InteractiveButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
            .opacity(configuration.isPressed ? 0.8 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}
