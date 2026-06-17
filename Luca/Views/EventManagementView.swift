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
    @State private var selectedEvent: Event?
    @State private var showingEventForm = false
    @State private var showingDeleteConfirmation = false
    @State private var eventToDelete: Event?
    
    private let lunarCalendarService: LunarCalendarService
    private let dataManager: DataManager
    private let notificationManager: NotificationManager
    
    init(lunarCalendarService: LunarCalendarService,
         dataManager: DataManager,
         notificationManager: NotificationManager) {
        self.lunarCalendarService = lunarCalendarService
        self.dataManager = dataManager
        self.notificationManager = notificationManager
        
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
                Button(action: { showingEventForm = true }) {
                    Image(systemName: "plus.circle")
                        .font(.title2)
                }
            }
        }
        .sheet(isPresented: $showingEventForm) {
            EventFormView(
                viewModel: eventViewModel,
                lunarCalendarService: lunarCalendarService
            )
        }
        .sheet(item: $selectedEvent) { event in
            EventDetailView(
                event: event,
                viewModel: eventViewModel,
                lunarCalendarService: lunarCalendarService
            )
        }
        .alert(String.localized(.deleteEventConfirmation), isPresented: $showingDeleteConfirmation) {
            Button(String.localized(.cancel), role: .cancel) { }
            Button(String.localized(.delete), role: .destructive) {
                if let event = eventToDelete {
                    Task {
                        await eventViewModel.deleteEvent(event)
                    }
                }
            }
        } message: {
            if let event = eventToDelete {
                Text(String(format: String.localized(.deleteEventMessage), event.title))
            }
        }
    }
}
/// Event detail view with edit and delete options
struct EventDetailView: View {
    let event: Event
    @ObservedObject var viewModel: EventViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var showingEditForm = false
    @State private var showingDeleteConfirmation = false
    
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
                                    
                                    Text(DateFormatter.localizedString(
                                        from: event.gregorianDate,
                                        dateStyle: .full,
                                        timeStyle: .none
                                    ))
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                }
                                
                                Spacer()
                            }
                        }
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
                    
                    // Description
                    if !event.description.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            Text(localized: .description)
                                .font(.headline)
                            
                            Text(event.description)
                                .font(.body)
                                .padding()
                                .background(Color(.systemGray6))
                                .cornerRadius(8)
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
                            .cornerRadius(8)
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
                    Menu {
                        Button(action: { showingEditForm = true }) {
                            Label(String.localized(.edit), systemImage: "pencil")
                        }
                        
                        Button(role: .destructive, action: { showingDeleteConfirmation = true }) {
                            Label(String.localized(.delete), systemImage: "trash")
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                    }
                }
            }
            .sheet(isPresented: $showingEditForm) {
                EventFormView(
                    viewModel: viewModel,
                    event: event,
                    lunarCalendarService: lunarCalendarService
                )
            }
            .alert(String.localized(.deleteEventConfirmation), isPresented: $showingDeleteConfirmation) {
                Button(String.localized(.cancel), role: .cancel) { }
                Button(String.localized(.delete), role: .destructive) {
                    Task {
                        await viewModel.deleteEvent(event)
                        dismiss()
                    }
                }
            } message: {
                Text(String(format: String.localized(.deleteEventMessage), event.title))
            }
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
