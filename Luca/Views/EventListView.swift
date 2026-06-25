import SwiftUI

/// Filter mode for the event list
enum EventFilter: Equatable {
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
    @State private var showingEventForm = false
    @State private var eventToEdit: Event?
    @State private var showingDeleteConfirmation = false
    @State private var eventToDelete: Event?
    
    private let lunarCalendarService: LunarCalendarService
    
    init(viewModel: EventViewModel,
         lunarCalendarService: LunarCalendarService) {
        self.viewModel = viewModel
        self.lunarCalendarService = lunarCalendarService
    }
    
    private var isUpcomingSelected: Bool {
        if case .upcoming = eventFilter { return true }
        return false
    }
    
    var filteredEvents: [Event] {
        var events = viewModel.events
        let now = Calendar.current.startOfDay(for: Date())
        
        switch eventFilter {
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
    
    var body: some View {
        VStack(spacing: 0) {
                // Search and Filter Section
                VStack(spacing: 12) {
                    // Search Bar
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
                    
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 6) {
                            FilterChip(
                                filter: .today,
                                isSelected: eventFilter == .today,
                                action: { eventFilter = .today }
                            )
                            
                            FilterChip(
                                filter: .upcoming,
                                isSelected: eventFilter == .upcoming,
                                action: { eventFilter = .upcoming }
                            )
                            
                            ForEach(EventCategory.allCases, id: \.self) { category in
                                FilterChip(
                                    filter: .category(category),
                                    isSelected: eventFilter == .category(category),
                                    action: {
                                        eventFilter = eventFilter == .category(category) ? .upcoming : .category(category)
                                    }
                                )
                            }
                        }
                    }
         
                }
                .padding()
                .background(Color(.systemBackground))
                
                Divider()
                
                // Events List
                if viewModel.isLoading {
                    ProgressView()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if filteredEvents.isEmpty {
                    EmptyEventsView(
                        hasEvents: !viewModel.events.isEmpty,
                        searchText: searchText,
                        eventFilter: eventFilter,
                        onCreateEvent: { showingEventForm = true }
                    )
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                List {
                    ForEach(filteredEvents) { event in
                        EventRowView(
                            event: event,
                            onTap: { editEvent(event) },
                            onDelete: { deleteEvent(event) }
                        )
                        .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                        .listRowSeparator(.hidden)
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
                .listStyle(PlainListStyle())
                }
            }
            .navigationTitle(String.localized(.events))
            .navigationBarTitleDisplayMode(.large)
            .refreshable {
                // Haptic feedback for refresh
                let impactFeedback = UIImpactFeedbackGenerator(style: .light)
                impactFeedback.impactOccurred()
                
                await viewModel.loadEvents()
            }
            .task {
                await viewModel.loadEvents()
            }
            .sheet(isPresented: $showingEventForm) {
                EventFormView(
                    viewModel: viewModel,
                    lunarCalendarService: lunarCalendarService
                )
            }
            .sheet(item: $eventToEdit) { event in
                EventFormView(
                    viewModel: viewModel,
                    event: event,
                    lunarCalendarService: lunarCalendarService
                )
            }
            .alert(String.localized(.deleteEventConfirmation), isPresented: $showingDeleteConfirmation) {
                Button(String.localized(.cancel), role: .cancel) { }
                Button(String.localized(.delete), role: .destructive) {
                    if let event = eventToDelete {
                        Task {
                            await viewModel.deleteEvent(event)
                        }
                    }
                }
            } message: {
                if let event = eventToDelete {
                    Text(String(format: String.localized(.deleteEventMessage), event.title))
                }
            }
    }
    
    // MARK: - Helper Methods
    
    private func editEvent(_ event: Event) {
        eventToEdit = event
    }
    
    private func deleteEvent(_ event: Event) {
        eventToDelete = event
        showingDeleteConfirmation = true
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
            VStack(alignment: .leading, spacing: 8) {
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(event.title)
                            .font(.headline)
                            .foregroundColor(.primary)
                            .multilineTextAlignment(.leading)

                        if !event.description.isEmpty {
                            Text(event.description)
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                                .lineLimit(2)
                                .multilineTextAlignment(.leading)
                        }
                    }

                    Spacer()

                    if !event.reminderSettings.isEmpty {
                        Image(systemName: "bell.fill")
                            .font(.caption)
                            .foregroundColor(.orange)
                    }
                }

                if event.recurrence.isRepeating {
                    // Recurring event description
                    HStack(spacing: 6) {
                        Image(systemName: "repeat")
                            .font(.caption)
                            .foregroundColor(.secondary)

                        Text(event.recurrenceDescription)
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundColor(.primary)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                } else {
                    HStack(spacing: 16) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(localized: .lunarDate)
                                .font(.caption2)
                                .foregroundColor(.secondary)

                            HStack(spacing: 4) {
                                let lunarText = String(format: String.localized(.lunarDateLine1Format), event.lunarDate.day, event.lunarDate.month, event.lunarDate.traditionalYear)
                                Text(verbatim: lunarText)
                                    .font(.caption)
                                    .fontWeight(.medium)
                                    .foregroundColor(.primary)

                                if event.lunarDate.isLeapMonth {
                                    Text(String.localized(.leapMonth))
                                        .font(.caption2)
                                        .fontWeight(.medium)
                                        .foregroundColor(.orange)
                                        .padding(.horizontal, 3)
                                        .background(Color.orange.opacity(0.2))
                                        .cornerRadius(3)
                                }
                            }
                        }

                        Spacer()

                        VStack(alignment: .trailing, spacing: 2) {
                            Text(localized: .gregorianDate)
                                .font(.caption2)
                                .foregroundColor(.secondary)

                            Text(SharedDateFormatters.mediumDateVi.string(from: event.gregorianDate))
                                .font(.caption)
                                .fontWeight(.medium)
                                .foregroundColor(.primary)
                        }
                    }
                }
            }
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(12)
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
}

/// Filter chip
struct FilterChip: View {
    let filter: EventFilter
    let isSelected: Bool
    let action: () -> Void
    
    private var iconName: String {
        switch filter {
        case .today: return "sun.max.fill"
        case .upcoming: return "clock.fill"
        case .category(let category):
            switch category {
            case .personal: return "person.fill"
            case .cultural: return "star.fill"
            case .religious: return "book.fill"
            }
        }
    }
    
    private var chipColor: Color {
        switch filter {
        case .today: return .orange
        case .upcoming: return .accentColor
        case .category(let category):
            switch category {
            case .personal: return .blue
            case .cultural: return .purple
            case .religious: return .indigo
            }
        }
    }
    
    private var label: String {
        switch filter {
        case .today: return String.localized(.today)
        case .upcoming: return String.localized(.upcomingEvents)
        case .category(let category): return category.displayName
        }
    }
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 4) {
                Image(systemName: iconName)
                    .font(.caption2)
                Text(label)
                    .font(.caption)
                    .fontWeight(.semibold)
            }
            .foregroundColor(isSelected ? .white : chipColor)
            .padding(.horizontal, 8)
            .padding(.vertical, 6)
            .background(
                isSelected
                    ? AnyView(chipColor)
                    : AnyView(chipColor.opacity(0.12))
            )
            .cornerRadius(14)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

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
