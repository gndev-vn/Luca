//
//  EventDetailByIdView.swift
//  Luca
//
//  Created by Kiro on 19/12/25.
//

import SwiftUI

/// Event detail view that loads an event by its ID
struct EventDetailByIdView: View {
    let eventId: UUID
    let dataManager: DataManager
    let notificationManager: NotificationManager
    let lunarCalendarService: LunarCalendarService
    
    @State private var event: Event?
    @State private var isLoading = true
    @State private var errorMessage: String?
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        Group {
            if isLoading {
                ProgressView(String.localized(.loadingEvent))
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if let event = event {
                EventDetailView(
                    event: event,
                    viewModel: EventViewModel(dataManager: dataManager, notificationManager: notificationManager),
                    lunarCalendarService: lunarCalendarService
                )
            } else {
                VStack(spacing: 16) {
                    Image(systemName: "exclamationmark.triangle")
                        .font(.largeTitle)
                        .foregroundColor(.orange)
                    
                    Text(localized: .eventNotFound)
                        .font(.headline)
                    
                    if let errorMessage = errorMessage {
                        Text(errorMessage)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    
                    LocalizedButton(.goBack) {
                        dismiss()
                    }
                    .buttonStyle(.borderedProminent)
                }
                .padding()
            }
        }
        .task {
            await loadEvent()
        }
    }
    
    private func loadEvent() async {
        isLoading = true
        errorMessage = nil
        
        do {
            let allEvents = try await dataManager.fetchAllEvents()
            event = allEvents.first { $0.id == eventId }
            
            if event == nil {
                errorMessage = String.localized(.eventNotFoundMessage)
            }
        } catch {
            errorMessage = "\(String.localized(.failedToLoadEvent)): \(error.localizedDescription)"
        }
        
        isLoading = false
    }
}

#Preview {
    EventDetailByIdView(
        eventId: UUID(),
        dataManager: MockDataManager(),
        notificationManager: MockNotificationManager(),
        lunarCalendarService: MockLunarCalendarService()
    )
}
