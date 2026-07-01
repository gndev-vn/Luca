//
//  DateDetailView.swift
//  Luca
//
//  Created by Kiro on 19/12/25.
//

import SwiftUI

/// Detailed view for a specific date showing lunar information and events
struct DateDetailView: View {
    let date: Date
    let lunarCalendarService: LunarCalendarService
    let dataManager: DataManager
    
    @State private var events: [Event] = []
    @State private var isLoading = false
    @Environment(\.dismiss) private var dismiss
    
    private var lunarDate: LunarDate {
        lunarCalendarService.convertToLunar(gregorian: date)
    }
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Date Header
                VStack(alignment: .leading, spacing: 12) {
                    Text(SharedDateFormatters.fullDate.string(from: date))
                        .font(.largeTitle)
                        .fontWeight(.bold)
                    
                        VStack {
                            Text(localized: .lunarDate)
                                .font(.caption)
                                .foregroundColor(.secondary)
                            
                            VStack(alignment: .leading, spacing: 2) {
                                Text(lunarDate.fullYearDisplay())
                                    .font(.headline)
                                
                                Text("\(lunarDate.month) \(String.localized(.month)) \(lunarDate.day) \(String.localized(.day))")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                
                                if lunarDate.isLeapMonth {
                                    Text(localized: .leapMonth)
                                        .font(.caption)
                                        .foregroundColor(.orange)
                                        .padding(.horizontal, 4)
                                        .background(Color.orange.opacity(0.2))
                                        .cornerRadius(4)
                                }
                            }
                        }
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(AppDesign.cardCornerRadius)
                
                // Events Section
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Text(localized: .events)
                            .font(.headline)
                        
                        Spacer()
                        
                        if !events.isEmpty {
                            Text("\(events.count)")
                                .font(.caption)
                                .fontWeight(.semibold)
                                .foregroundColor(.white)
                                .frame(width: 20, height: 20)
                                .background(Color.accentColor)
                                .clipShape(Circle())
                        }
                    }
                    
                    if isLoading {
                        ProgressView()
                            .frame(maxWidth: .infinity)
                    } else if events.isEmpty {
                        Text(localized: .noEventsOnDate)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color(.systemGray6))
                            .cornerRadius(AppDesign.cardCornerRadius)
                    } else {
                        ForEach(events) { event in
                            DateEventRowView(event: event)
                        }
                    }
                }
            }
            .padding()
        }
        .navigationTitle(String.localized(.dateDetails))
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await loadEvents()
        }
    }
    
    private func loadEvents() async {
        isLoading = true
        
        do {
            let calendar = Calendar.current
            let startOfDay = calendar.startOfDay(for: date)
            let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay) ?? date
            let dateRange = DateInterval(start: startOfDay, end: endOfDay)
            
            let fetched = try await dataManager.fetchEvents(for: dateRange)
            events = fetched.filter { $0.isEnabled }
        } catch {
            print("Error loading events: \(error)")
        }
        
        isLoading = false
    }
}

/// Row view for displaying an event in the date detail
struct DateEventRowView: View {
    let event: Event
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(event.title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                if !event.description.isEmpty {
                    Text(event.description)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                }
                
                Text(event.category.displayName)
                    .font(.caption2)
                    .foregroundColor(.white)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Color.categoryColor(event.category))
                    .cornerRadius(4)
            }
            
            Spacer()
            
            if event.isPublicHoliday {
                Image(systemName: "star.fill")
                    .foregroundColor(.red)
            } else if event.recurrence.isRepeating {
                Image(systemName: "repeat")
                    .foregroundColor(.accentColor)
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(AppDesign.cardCornerRadius)
    }
    
}

#Preview {
    NavigationStack {
        DateDetailView(
            date: Date(),
            lunarCalendarService: MockLunarCalendarService(),
            dataManager: MockDataManager()
        )
    }
}
