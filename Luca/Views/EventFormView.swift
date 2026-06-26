//
//  EventFormView.swift
//  Luca
//
//  Created by Kiro on 18/12/25.
//

import SwiftUI

/// View for creating and editing events with lunar date picker
struct EventFormView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.accessibilityManager) private var accessibilityManager
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @ObservedObject var viewModel: EventViewModel
    
    // Form state
    @State private var title: String
    @State private var description: String
    @State private var tags: [String]
    @State private var selectedCategory: EventCategory
    @State private var recurrence: RecurrenceType
    @State private var selectedLunarDate: LunarDate
    @State private var showingValidationError = false
    @State private var validationErrors: [String] = []
    @State private var isSaving = false
    
    // Event status
    @State private var isEventEnabled: Bool
    
    // Reminder state
    @State private var notifyOnDay: Bool
    @State private var notifyBefore: Bool
    @State private var notifyBeforeDays: Int
    @State private var notificationTime: Date
    @State private var soundEnabled: Bool
    @State private var vibrationEnabled: Bool
    @State private var notificationSoundName: String?
    
    // Lunar date picker state (inline)
    @State private var pickerYear: Int
    @State private var pickerMonth: Int
    @State private var pickerDay: Int
    
    private let event: Event?
    private let isEditing: Bool
    private let isPreseeded: Bool
    private let lunarCalendarService: LunarCalendarService
    
    private var isNewEvent: Bool { !isEditing }
    
    private var recurrenceDescription: String {
        switch recurrence {
        case .none: return ""
        case .daily: return String.localized(.recurrenceDaily)
        case .weekly:
            return String(format: String.localized(.recurrenceWeeklyFormat),
                          LocalizedStringService.shared.localizedWeekdayFull(pickerDay))
        case .monthly:
            return String(format: String.localized(.recurrenceMonthlyFormat), pickerDay)
        case .yearly:
            return String(format: String.localized(.recurrenceYearlyFormat), pickerDay, selectedLunarDate.month)
        }
    }
    
    private var pickerIsLeap: Bool { pickerMonth > 100 }
    private var pickerActualMonth: Int { pickerIsLeap ? pickerMonth - 100 : pickerMonth }
    
    private var availableYears: [Int] {
        let currentLunarDate = LunarDate.fromGregorian(Date())
        let currentYear = currentLunarDate.year
        return Array((currentYear - 10)...(currentYear + 10))
    }
    
    private var availableMonths: [Int] {
        let leapInfo = LunarCalendarConverter.getLeapMonthInfo(pickerYear)
        if leapInfo.hasLeap {
            let leapMonth = leapInfo.leapMonth
            var months = Array(1...12)
            if leapMonth > 0 && leapMonth <= 12 {
                months.insert(leapMonth + 100, at: leapMonth)
            }
            return months
        } else {
            return Array(1...12)
        }
    }
    
    private var availableDays: [Int] {
        let daysInMonth = LunarCalendarConverter.daysInLunarMonth(
            year: pickerYear,
            month: pickerActualMonth,
            isLeapMonth: pickerIsLeap
        )
        return Array(1...daysInMonth)
    }
    
    /// Initialize for creating a new event
    init(viewModel: EventViewModel, 
         lunarCalendarService: LunarCalendarService,
         initialDate: Date? = nil) {
        self.viewModel = viewModel
        self.event = nil
        self.isEditing = false
        self.isPreseeded = false
        self.lunarCalendarService = lunarCalendarService
        
        let lunarDate = initialDate != nil 
            ? LunarDate.fromGregorian(initialDate!)
            : LunarDate.fromGregorian(Date())
        
        _title = State(initialValue: "")
        _description = State(initialValue: "")
        _tags = State(initialValue: [])
        _selectedCategory = State(initialValue: .personal)
        _recurrence = State(initialValue: .none)
        _selectedLunarDate = State(initialValue: lunarDate)
        _pickerYear = State(initialValue: lunarDate.year)
        let initialMonth = lunarDate.isLeapMonth ? lunarDate.month + 100 : lunarDate.month
        _pickerMonth = State(initialValue: initialMonth)
        _pickerDay = State(initialValue: lunarDate.day)
        _isEventEnabled = State(initialValue: true)
        _notifyOnDay = State(initialValue: false)
        _notifyBefore = State(initialValue: false)
        _notifyBeforeDays = State(initialValue: 1)
        _notificationTime = State(initialValue: Event.defaultNotificationTime)
        _soundEnabled = State(initialValue: true)
        _vibrationEnabled = State(initialValue: true)
        _notificationSoundName = State(initialValue: nil)
    }
    
    private var shouldShowCategory: Bool {
        isEditing && !isPreseeded
    }
    
    /// Initialize for editing an existing event
    init(viewModel: EventViewModel,
         event: Event,
         lunarCalendarService: LunarCalendarService) {
        self.viewModel = viewModel
        self.event = event
        self.isEditing = true
        self.isPreseeded = HolidayService.preseededEventNames.contains(event.title)
        self.lunarCalendarService = lunarCalendarService
        
        _title = State(initialValue: event.title)
        _description = State(initialValue: event.description)
        _tags = State(initialValue: event.tags)
        _selectedCategory = State(initialValue: event.category)
        _recurrence = State(initialValue: event.recurrence)
        _selectedLunarDate = State(initialValue: event.lunarDate)
        _pickerYear = State(initialValue: event.lunarDate.year)
        let initialMonth = event.lunarDate.isLeapMonth ? event.lunarDate.month + 100 : event.lunarDate.month
        _pickerMonth = State(initialValue: initialMonth)
        let initialDay: Int
        if event.recurrence == .weekly {
            initialDay = Calendar.current.component(.weekday, from: event.gregorianDate)
        } else {
            initialDay = event.lunarDate.day
        }
        _pickerDay = State(initialValue: initialDay)
        _isEventEnabled = State(initialValue: event.isEnabled)
        _notifyOnDay = State(initialValue: event.reminderSettings.contains(.onDay))
        _notifyBefore = State(initialValue: event.reminderSettings.contains { $0 != .onDay })
        if let beforeType = event.reminderSettings.first(where: { $0 != .onDay }) {
            _notifyBeforeDays = State(initialValue: abs(beforeType.daysOffset))
        } else {
            _notifyBeforeDays = State(initialValue: 1)
        }
        _notificationTime = State(initialValue: event.notificationTime)
        _soundEnabled = State(initialValue: event.soundEnabled)
        _vibrationEnabled = State(initialValue: event.vibrationEnabled)
        _notificationSoundName = State(initialValue: event.notificationSoundName)
    }
    
    var body: some View {
        NavigationView {
            Form {
                // Title and Description Section
                Section {
                    VStack(alignment: .leading, spacing: 16) {
                        TextField(String.localized(.eventTitle), text: $title)
                            .textInputAutocapitalization(.words)
                            .disabled(isPreseeded)
                            .font(.title3)
                            .accessibilityLabel(String.localized(.eventTitle))
                            .accessibilityHint("Enter the title for your event")
                        
                        ZStack(alignment: .topLeading) {
                            if description.isEmpty {
                                Text(localized: .descriptionOptional)
                                    .foregroundColor(.secondary)
                                    .padding(.horizontal, 4)
                                    .padding(.vertical, 8)
                            }
                            
                            TextEditor(text: $description)
                                .frame(minHeight: 100)
                                .disabled(isPreseeded)
                                .opacity(description.isEmpty ? 0.25 : 1)
                                .accessibilityLabel("Event description")
                                .accessibilityHint("Enter an optional description for your event")
                        }
                    }
                    .padding(.vertical, 8)
                } header: {
                    Text(localized: .eventDetails)
                        .textCase(nil)
                        .font(.subheadline.weight(.semibold))
                        .foregroundColor(.secondary)
                }

                // Tags Section
                if !isPreseeded {
                    Section {
                        VStack(alignment: .leading, spacing: 8) {
                            TagsInputView(tags: $tags)
                        }
                        .padding(.vertical, 4)
                    } header: {
                        Text(String.localized(.tags))
                            .textCase(nil)
                            .font(.subheadline.weight(.semibold))
                            .foregroundColor(.secondary)
                    }
                }

                // Recurrence Section — placed before date section
                if !isPreseeded {
                    Section {
                        Picker(String.localized(.repeatEvent), selection: $recurrence) {
                            ForEach(RecurrenceType.allCases, id: \.self) { type in
                                HStack {
                                    Image(systemName: recurrenceIcon(for: type))
                                        .foregroundColor(.accentColor)
                                        .symbolRenderingMode(.hierarchical)
                                    Text(type.displayName.localizedCapitalized)
                                }
                                .tag(type)
                            }
                        }
                        .pickerStyle(.menu)
                    } header: {
                        Text(localized: .recurrence)
                            .textCase(nil)
                            .font(.subheadline.weight(.semibold))
                            .foregroundColor(.secondary)
                    }
                }

                // Lunar Date Section
                Section {
                    VStack(spacing: 12) {
                        if recurrence.isRepeating {
                            HStack(spacing: 8) {
                                Image(systemName: "repeat")
                                    .foregroundColor(.accentColor)

                                Text(recurrenceDescription)
                                    .font(.title3.weight(.semibold))
                                    .foregroundColor(.primary)
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                        } else {
                            HStack {
                                VStack(alignment: .leading, spacing: 6) {
                                    let ld = selectedLunarDate
                                    
                                    Text(String(format: String.localized(.lunarDateLine1Format), ld.day, ld.month, ld.traditionalYear))
                                        .font(.title3.weight(.semibold))
                                        .foregroundColor(.primary)
                                    
                                    if horizontalSizeClass == .regular {
                                        let yearZodiac = ZodiacYearCalculator.getZodiacYear(for: ld.traditionalYear)
                                        let monthZodiac = ZodiacYearCalculator.getZodiacMonth(lunarMonth: ld.month, lunarYear: ld.year)
                                        let dayZodiac = ZodiacYearCalculator.getZodiacDay(for: ld.toGregorian())
                                        Text(String(format: String.localized(.lunarDateLine2Format), dayZodiac, monthZodiac, yearZodiac))
                                            .font(.subheadline)
                                            .foregroundColor(.secondary)
                                    }
                                    
                                    Text(String(format: String.localized(.gregorianDateFormat), gregorianDateString(ld.toGregorian())))
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)
                                }
                                Spacer()
                            }
                        }
                        
                        // Date pickers adapt to recurrence:
                        //   daily → hidden entirely
                        //   weekly → only weekday picker
                        //   monthly → day picker only
                        //   yearly → month + day pickers
                        //   none → all three
                        if !isPreseeded && recurrence != .daily {
                            Divider()
                            
                            HStack(spacing: 8) {
                                if recurrence == .weekly {
                                    Picker(String.localized(.day), selection: $pickerDay) {
                                        ForEach(1...7, id: \.self) { weekday in
                                            Text(weekdaySymbol(for: weekday))
                                                .tag(weekday)
                                        }
                                    }
                                    .pickerStyle(.wheel)
                                } else {
                                    Picker(String.localized(.day), selection: $pickerDay) {
                                        ForEach(availableDays, id: \.self) { day in
                                            Text(verbatim: "\(day)")
                                                .tag(day)
                                        }
                                    }
                                    .pickerStyle(.wheel)
                                }
                                
                                if recurrence != .weekly && recurrence != .monthly {
                                    Picker(String.localized(.month), selection: $pickerMonth) {
                                        ForEach(availableMonths, id: \.self) { month in
                                            let actualMonth = month > 100 ? month - 100 : month
                                            let isLeap = month > 100
                                            if horizontalSizeClass == .regular {
                                                Text(LocalizedStringService.shared.localizedMonthFull(actualMonth))
                                                    .tag(month)
                                            } else if isLeap {
                                                Text(LocalizedStringService.shared.localizedMonthFormat(actualMonth, isLeap: true))
                                                    .tag(month)
                                            } else {
                                                Text(LocalizedStringService.shared.localizedMonthFormat(actualMonth))
                                                    .tag(month)
                                            }
                                        }
                                    }
                                    .pickerStyle(.wheel)
                                }
                                
                                if recurrence != .weekly && recurrence != .monthly && recurrence != .yearly {
                                    Picker(String.localized(.year), selection: $pickerYear) {
                                        ForEach(availableYears, id: \.self) { year in
                                            Text(verbatim: "\(year + 1983)")
                                                .tag(year)
                                        }
                                    }
                                    .pickerStyle(.wheel)
                                }
                            }
                            .frame(height: 160)
                            .onChange(of: pickerYear) { _, _ in
                                validateAndAdjustDay()
                                syncLunarDate()
                            }
                            .onChange(of: pickerMonth) { _, _ in
                                validateAndAdjustDay()
                                syncLunarDate()
                            }
                            .onChange(of: pickerDay) { _, _ in
                                syncLunarDate()
                            }
                            .onChange(of: recurrence) { _, newValue in
                                if newValue == .weekly {
                                    pickerDay = Calendar.current.component(.weekday, from: selectedLunarDate.toGregorian())
                                    syncLunarDate()
                                }
                            }
                        }
                    }
                    .padding(.vertical, 4)
                } header: {
                    Text(localized: .lunarDate)
                        .textCase(nil)
                        .font(.subheadline.weight(.semibold))
                        .foregroundColor(.secondary)
                }
                
                // Category Section (only for editing non-preseeded events)
                if shouldShowCategory {
                    Section {
                        HStack(spacing: 12) {
                            ForEach(EventCategory.allCases, id: \.self) { category in
                                Button {
                                    selectedCategory = category
                                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                                } label: {
                                    VStack(spacing: 6) {
                                        Image(systemName: categoryIcon(for: category))
                                            .font(.title3)
                                            .foregroundColor(selectedCategory == category ? .white : Color.categoryColor(category))
                                            .frame(width: 44, height: 44)
                                            .background(selectedCategory == category ? Color.categoryColor(category) : Color.categoryColor(category).opacity(0.12))
                                            .cornerRadius(12)

                                        Text(category.displayName)
                                            .font(.caption2)
                                            .fontWeight(selectedCategory == category ? .semibold : .regular)
                                            .foregroundColor(selectedCategory == category ? Color.categoryColor(category) : .secondary)
                                    }
                                }
                                .buttonStyle(PlainButtonStyle())
                                .frame(maxWidth: .infinity)
                            }
                        }
                        .padding(.vertical, 4)
                    } header: {
                        Text(localized: .category)
                            .textCase(nil)
                            .font(.subheadline.weight(.semibold))
                            .foregroundColor(.secondary)
                    }
                }
                
                // Reminders Section
                Section {
                    // Notify on the day
                    Toggle(isOn: $notifyOnDay) {
                        HStack {
                            Image(systemName: "bell.fill")
                                .foregroundColor(.orange)
                                .symbolRenderingMode(.hierarchical)
                            Text(localized: .notifyOnDay)
                        }
                    }
                    if notifyOnDay {
                        DatePicker(String.localized(.time), selection: $notificationTime, displayedComponents: .hourAndMinute)
                            .datePickerStyle(.compact)
                            .padding(.leading)
                    }
                    
                    // Notify before
                    Toggle(isOn: $notifyBefore) {
                        HStack {
                            Image(systemName: "bell.badge.fill")
                                .foregroundColor(.orange)
                                .symbolRenderingMode(.hierarchical)
                            Text(localized: .notifyBefore)
                        }
                    }
                    if notifyBefore {
                        Picker(String.localized(.daysBefore), selection: $notifyBeforeDays) {
                            Text("1 \(String.localized(.day))").tag(1)
                            Text("2 \(String.localized(.days))").tag(2)
                            Text("3 \(String.localized(.days))").tag(3)
                        }
                        .pickerStyle(.segmented)
                        .padding(.leading)
                    }
                } header: {
                    Text(localized: .reminders)
                        .textCase(nil)
                        .font(.subheadline.weight(.semibold))
                        .foregroundColor(.secondary)
                }
                
                // Sound & Vibration Section — only shown when reminders are enabled
                if notifyOnDay || notifyBefore {
                    Section {
                        Toggle(isOn: $soundEnabled) {
                            HStack {
                                Image(systemName: "speaker.wave.2.fill")
                                    .foregroundColor(.blue)
                                    .symbolRenderingMode(.hierarchical)
                                Text(localized: .notificationSound)
                            }
                        }
                        
                        Toggle(isOn: $vibrationEnabled) {
                            HStack {
                                Image(systemName: "iphone.radiowaves.left.and.right")
                                    .foregroundColor(.blue)
                                    .symbolRenderingMode(.hierarchical)
                                Text(localized: .vibration)
                            }
                        }
                    } header: {
                        Text(localized: .soundAndVibration)
                            .textCase(nil)
                            .font(.subheadline.weight(.semibold))
                            .foregroundColor(.secondary)
                    }
                }
                
                // Event Status Section
                Section {
                    Toggle(isOn: $isEventEnabled) {
                        HStack {
                            Image(systemName: "eye")
                                .foregroundColor(.blue)
                                .symbolRenderingMode(.hierarchical)
                            Text(String.localized(isEventEnabled ? .enableEvent : .disableEvent))
                        }
                    }
                } header: {
                    Text(String.localized(.enableEvent))
                        .textCase(nil)
                        .font(.subheadline.weight(.semibold))
                        .foregroundColor(.secondary)
                }
                
                // Validation Errors
                if !validationErrors.isEmpty {
                    Section {
                        ForEach(validationErrors, id: \.self) { error in
                            HStack {
                                Image(systemName: "exclamationmark.triangle.fill")
                                    .foregroundColor(.red)
                                Text(error)
                                    .foregroundColor(.red)
                                    .font(.caption)
                            }
                        }
                    }
                }
            }
            .navigationTitle(isEditing ? String.localized(.editEvent) : String.localized(.newEvent))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(String.localized(.cancel)) {
                        dismiss()
                    }
                    .disabled(isSaving)
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        // Haptic feedback for save action
                        let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
                        impactFeedback.impactOccurred()
                        
                        saveEvent()
                    }) {
                        if isSaving {
                            HStack(spacing: 8) {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle())
                                    .scaleEffect(0.8)
                                Text(localized: .saving)
                            }
                        } else {
                            Text(isEditing ? String.localized(.save) : String.localized(.create))
                                .fontWeight(.semibold)
                        }
                    }
                    .disabled(isSaving)
                }
            }
            .sheet(isPresented: $showingValidationError) {
                ConfirmationBottomSheet(
                    title: String.localized(.validationError),
                    message: validationErrors.joined(separator: "\n"),
                    buttonTitle: String.localized(.done),
                    buttonRole: .cancel,
                    showCancel: false,
                    isPresented: $showingValidationError,
                    action: {}
                )
            }
        }
    }
    
    // MARK: - Helper Methods
    
    private func weekdaySymbol(for weekday: Int) -> String {
        LocalizedStringService.shared.localizedWeekdayShort(weekday)
    }
    
    private func fullWeekdayName(for weekday: Int) -> String {
        LocalizedStringService.shared.localizedWeekdayFull(weekday)
    }
    
    private func categoryIcon(for category: EventCategory) -> String {
        switch category {
        case .personal: return "person.fill"
        case .cultural: return "star.fill"
        case .religious: return "book.fill"
        }
    }
    
    private func recurrenceIcon(for type: RecurrenceType) -> String {
        switch type {
        case .none: return "slash.circle"
        case .daily: return "repeat"
        case .weekly: return "repeat"
        case .monthly: return "repeat"
        case .yearly: return "repeat"
        }
    }
    
    private func gregorianDateString(_ date: Date) -> String {
        SharedDateFormatters.ddMMyyyy.string(from: date)
    }
    
    private func syncLunarDate() {
        selectedLunarDate = LunarDate(
            year: pickerYear,
            month: pickerActualMonth,
            day: pickerDay,
            isLeapMonth: pickerIsLeap
        )
    }
    
    private func validateAndAdjustDay() {
        let maxDays = LunarCalendarConverter.daysInLunarMonth(
            year: pickerYear,
            month: pickerActualMonth,
            isLeapMonth: pickerIsLeap
        )
        if pickerDay > maxDays {
            pickerDay = maxDays
        }
    }
    
    private func saveEvent() {
        // Validate input
        validationErrors = []
        
        if title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            validationErrors.append(String.localized(.eventTitleRequired))
        }
        
        if !selectedLunarDate.isValid() {
            validationErrors.append(String.localized(.invalidLunarDate))
        }
        
        if !validationErrors.isEmpty {
            showingValidationError = true
            return
        }
        
        isSaving = true
        
        var reminderSettings: [ReminderType] = []
        if notifyOnDay {
            reminderSettings.append(.onDay)
        }
        if notifyBefore {
            let type: ReminderType
            switch notifyBeforeDays {
            case 2: type = .twoDaysBefore
            case 3: type = .threeDaysBefore
            default: type = .oneDayBefore
            }
            reminderSettings.append(type)
        }
        
        Task {
            let eventToSave: Event
            
            if let existingEvent = event {
                if isPreseeded {
                    existingEvent.reminderSettings = reminderSettings
                    existingEvent.isEnabled = isEventEnabled
                } else {
                    existingEvent.title = title.trimmingCharacters(in: .whitespacesAndNewlines)
                    existingEvent.description = description.trimmingCharacters(in: .whitespacesAndNewlines)
                    existingEvent.tags = tags
                    existingEvent.lunarDate = selectedLunarDate
                    existingEvent.category = selectedCategory
                    existingEvent.recurrence = recurrence
                    existingEvent.reminderSettings = reminderSettings
                    existingEvent.notificationTime = notificationTime
                    existingEvent.soundEnabled = soundEnabled
                    existingEvent.vibrationEnabled = vibrationEnabled
                    existingEvent.notificationSoundName = notificationSoundName
                    existingEvent.isEnabled = isEventEnabled
                }
                await viewModel.updateEvent(existingEvent)
            } else {
                // Create new event
                eventToSave = Event(
                    title: title.trimmingCharacters(in: .whitespacesAndNewlines),
                    description: description.trimmingCharacters(in: .whitespacesAndNewlines),
                    tags: tags,
                    lunarDate: selectedLunarDate,
                    category: selectedCategory,
                    isPublicHoliday: false,
                    recurrence: recurrence,
                    reminderSettings: reminderSettings,
                    soundEnabled: soundEnabled,
                    vibrationEnabled: vibrationEnabled,
                    notificationTime: notificationTime,
                    notificationSoundName: notificationSoundName,
                    isEnabled: isEventEnabled
                )
                
                await viewModel.createEvent(eventToSave)
            }
            
            isSaving = false
            dismiss()
        }
    }
}

#Preview("New Event") {
    EventFormView(
        viewModel: EventViewModel(
            dataManager: MockDataManager(),
            notificationManager: MockNotificationManager()
        ),
        lunarCalendarService: MockLunarCalendarService()
    )
}

#Preview("Edit Event") {
    let event = Event(
        title: "Test Event",
        description: "This is a test event",
        lunarDate: LunarDate(year: 41, month: 1, day: 15),
        category: .personal,
        reminderSettings: [.onDay, .oneDayBefore],
        notificationTime: Event.defaultNotificationTime
    )
    
    EventFormView(
        viewModel: EventViewModel(
            dataManager: MockDataManager(),
            notificationManager: MockNotificationManager()
        ),
        event: event,
        lunarCalendarService: MockLunarCalendarService()
    )
}
