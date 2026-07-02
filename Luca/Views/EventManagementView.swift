//
//  EventManagementView.swift
//  Luca
//
//  Created by Kiro on 18/12/25.
//

import SwiftUI

/// Main event management interface with selection and context menus
struct EventManagementView: View {
    @StateObject private var eventViewModel: EventViewModel
    @State private var showingEventForm = false
    @State private var createEventInitialDate: Date?
    
    private let lunarCalendarService: LunarCalendarService
    
    init(lunarCalendarService: LunarCalendarService,
         dataManager: DataManager,
         notificationManager: NotificationManager) {
        self.lunarCalendarService = lunarCalendarService
        
        self._eventViewModel = StateObject(wrappedValue: EventViewModel(
            dataManager: dataManager,
            notificationManager: notificationManager
        ))
    }
    
    var body: some View {
        EventListView(
            viewModel: eventViewModel,
            lunarCalendarService: lunarCalendarService
        )
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: {
                    createEventInitialDate = nil
                    showingEventForm = true
                }) {
                    Image(systemName: "plus.circle")
                        .font(.title2)
                }
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .openCreateEventForm)) { notification in
            createEventInitialDate = notification.userInfo?["initialDate"] as? Date
            showingEventForm = true
        }
        .sheet(isPresented: $showingEventForm) {
            EventFormView(
                viewModel: eventViewModel,
                lunarCalendarService: lunarCalendarService,
                initialDate: createEventInitialDate
            )
        }
    }
}
/// Event detail view with edit and delete options
struct EventDetailView: View {
    let event: Event
    @ObservedObject var viewModel: EventViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var activeSheet: DetailViewSheet?
    
    private let lunarCalendarService: LunarCalendarService
    
    init(event: Event,
         viewModel: EventViewModel,
         lunarCalendarService: LunarCalendarService) {
        self.event = event
        self.viewModel = viewModel
        self.lunarCalendarService = lunarCalendarService
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Event Header
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Text(event.title)
                                .font(.largeTitle)
                                .fontWeight(.bold)
                                .foregroundColor(.primary)
                            
                            Spacer()
                            
                            if event.isPublicHoliday {
                                Image(systemName: "star.fill")
                                    .foregroundColor(.red)
                                    .font(.title2)
                            }
                        }
                        
                        HStack(spacing: 8) {
                            Text(event.category.displayName)
                                .font(.subheadline)
                                .fontWeight(.medium)
                                .foregroundColor(.white)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(Color.categoryColor(event.category))
                                .cornerRadius(8)
                            
                            if event.recurrence.isRepeating {
                                HStack(spacing: 4) {
                                    Image(systemName: "repeat")
                                        .font(.caption)
                                    Text(event.recurrence.displayName)
                                        .font(.caption)
                                }
                                .fontWeight(.medium)
                                .foregroundColor(.accentColor)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 6)
                                .background(Color.accentColor.opacity(0.1))
                                .cornerRadius(8)
                            }
                        }
                    }
                    
                    // Date Information
                    VStack(alignment: .leading, spacing: 12) {
                        Text(localized: .dateInformation)
                            .font(.headline)
                        
                        VStack(spacing: 8) {
                            HStack {
                                Image(systemName: "calendar.circle.fill")
                                    .foregroundColor(.accentColor)
                                
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(localized: .lunarDate)
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                    
                                    HStack(spacing: 4) {
                                        Text(event.lunarDate.fullYearDisplay())
                                            .font(.subheadline)
                                            .fontWeight(.medium)
                                        
                                        if event.lunarDate.isLeapMonth {
                                            Text(localized: .leapMonth)
                                                .font(.caption)
                                                .foregroundColor(.orange)
                                                .padding(.horizontal, 4)
                                                .background(Color.orange.opacity(0.2))
                                                .cornerRadius(4)
                                        }
                                    }
                                }
                                
                                Spacer()
                            }
                            
                            HStack {
                                Image(systemName: "calendar")
                                    .foregroundColor(.secondary)
                                
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(localized: .gregorianDate)
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                    
                                    Text(SharedDateFormatters.fullDate.string(from: event.gregorianDate))
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                }
                                
                                Spacer()
                            }
                        }
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(AppDesign.cardCornerRadius)
                    
                    // Description
                    if !event.description.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            Text(localized: .description)
                                .font(.headline)
                            
                            Text(event.description)
                                .font(.body)
                                .padding()
                                .background(Color(.systemGray6))
                                .cornerRadius(AppDesign.cardCornerRadius)
                        }
                    }
                    
                    // Reminders
                    if !event.reminderSettings.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            Text(localized: .reminders)
                                .font(.headline)
                            
                            VStack(alignment: .leading, spacing: 4) {
                                ForEach(event.reminderSettings, id: \.self) { reminder in
                                    HStack {
                                        Image(systemName: "bell.fill")
                                            .foregroundColor(.orange)
                                            .font(.caption)
                                        
                                        Text(reminder.displayName)
                                            .font(.subheadline)
                                    }
                                }
                            }
                            .padding()
                            .background(Color(.systemGray6))
                            .cornerRadius(AppDesign.cardCornerRadius)
                        }
                    }
                }
                .padding()
            }
            .navigationTitle(String.localized(.eventDetails))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(String.localized(.done)) {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    let isPreseeded = HolidayService.preseededEventNames.contains(event.title)
                    Menu {
                        Button(action: { activeSheet = .editForm }) {
                            Label(String.localized(.edit), systemImage: "pencil")
                        }
                        
                        if !isPreseeded {
                            Button(role: .destructive, action: { activeSheet = .deleteConfirmation }) {
                                Label(String.localized(.delete), systemImage: "trash")
                            }
                        }
                        
                        Button(action: {
                            activeSheet = event.isEnabled ? .disableConfirmation : .enableConfirmation
                        }) {
                            Label(
                                event.isEnabled ? String.localized(.disableEvent) : String.localized(.enableEvent),
                                systemImage: event.isEnabled ? "xmark.circle" : "checkmark.circle"
                            )
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                    }
                }
            }
            .sheet(item: $activeSheet) { sheet in
                switch sheet {
                case .editForm:
                    EventFormView(
                        viewModel: viewModel,
                        event: event,
                        lunarCalendarService: lunarCalendarService
                    )
                case .deleteConfirmation:
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
                            dismiss()
                        }
                    }
                case .disableConfirmation:
                    ConfirmationBottomSheet(
                        title: String.localized(.disableEventConfirmation),
                        message: String(format: String.localized(.disableEventMessage), event.title),
                        buttonTitle: String.localized(.disableEvent),
                        buttonRole: .destructive,
                        isPresented: Binding(
                            get: { activeSheet != nil },
                            set: { if !$0 { activeSheet = nil } }
                        )
                    ) {
                        Task {
                            await viewModel.disableEvent(event)
                            dismiss()
                        }
                    }
                case .enableConfirmation:
                    ConfirmationBottomSheet(
                        title: String.localized(.enableEvent),
                        message: String(format: String.localized(.enableEventMessage), event.title),
                        buttonTitle: String.localized(.enableEvent),
                        buttonRole: .cancel,
                        isPresented: Binding(
                            get: { activeSheet != nil },
                            set: { if !$0 { activeSheet = nil } }
                        )
                    ) {
                        Task {
                            await viewModel.enableEvent(event)
                            dismiss()
                        }
                    }
                }
            }
        }
    }
    
}

private enum DetailViewSheet: Identifiable {
    case editForm
    case deleteConfirmation
    case disableConfirmation
    case enableConfirmation
    
    var id: String {
        switch self {
        case .editForm: return "editForm"
        case .deleteConfirmation: return "deleteConfirmation"
        case .disableConfirmation: return "disableConfirmation"
        case .enableConfirmation: return "enableConfirmation"
        }
    }
}

#Preview("Event Management") {
    EventManagementView(
        lunarCalendarService: MockLunarCalendarService(),
        dataManager: MockDataManager(),
        notificationManager: MockNotificationManager()
    )
}
