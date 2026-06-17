//
//  CalendarView.swift
//  Luca
//
//  Created by Kiro on 16/12/25.
//

import SwiftUI

// MARK: - Calendar View Mode

// Year view removed — navigation handled via month/year picker

/// Main calendar view displaying lunar and Gregorian dates
struct CalendarView: View {
    @StateObject private var viewModel: CalendarViewModel
    @State private var selectedEvent: Event?
    @State private var showingDayEvents = false
    @State private var showingMonthPicker = false
    @Environment(\.themeManager) private var themeManager
    @Environment(\.accessibilityManager) private var accessibilityManager
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass

    init(
        lunarCalendarService: LunarCalendarService,
        dataManager: DataManager
    ) {
        self._viewModel = StateObject(
            wrappedValue: CalendarViewModel(
                lunarCalendarService: lunarCalendarService,
                dataManager: dataManager
            )
        )
    }

    var body: some View {
        VStack(spacing: 0) {
            // In-body calendar navigation bar
            calendarNavBar

            // Calendar grid fills remaining height
            GeometryReader { geometry in
                HStack {
                    Spacer(minLength: 0)
                    CalendarGridView(
                        currentDate: viewModel.currentDate,
                        selectedDate: viewModel.selectedDate,
                        events: viewModel.events,
                        publicHolidays: viewModel.publicHolidays,
                        availableHeight: geometry.size.height,
                        onDateSelected: { date in
                            viewModel.selectDate(date)
                            showingDayEvents = true
                        },
                        onEventTapped: { _ in },
                        lunarDateProvider: { date in viewModel.lunarDate(for: date) }
                    )
                    .frame(maxWidth: 480)
                    Spacer(minLength: 0)
                }
            }
        }
        .navigationTitle(String.localized(.lunarCalendar))
        .navigationBarTitleDisplayMode(.large)
        .task {
            if !viewModel.hasInitiallyLoaded {
                await viewModel.loadEvents()
            }
        }
        .refreshable {
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
            await viewModel.loadEvents()
        }
        .overlay(Group { if viewModel.isLoading { LoadingOverlayView() } })
        .sheet(item: $selectedEvent) { item in
            EventDetailSheet(event: item)
        }
        .sheet(isPresented: $showingDayEvents) {
            if let selectedDate = viewModel.selectedDate {
                DateDetailBottomSheet(
                    date: selectedDate,
                    viewModel: viewModel
                )
                .presentationDetents([.medium, .large])
                .presentationDragIndicator(.visible)
            }
        }
        .sheet(isPresented: $showingMonthPicker) {
            MonthYearPickerSheet(
                selectedDate: $viewModel.currentDate,
                onDone: {
                    showingMonthPicker = false
                    Task { await viewModel.loadEvents() }
                }
            )
            .presentationDetents([.height(320)])
            .presentationDragIndicator(.visible)
        }
    }

    // MARK: - Calendar navigation bar

    @ViewBuilder
    private var calendarNavBar: some View {
        VStack(spacing: 0) {
            ZStack {
                // Center: month + year title
                Button {
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    showingMonthPicker = true
                } label: {
                    VStack(spacing: 2) {
                        HStack(spacing: 4) {
                            if let lunarDate = viewModel.currentLunarDate {
                                Text(lunarContextTitle(lunarDate))
                                    .font(.system(.headline, design: .rounded))
                                    .fontWeight(.medium)
                                    .foregroundColor(.primary)
                                    .lineLimit(1)
                                    .minimumScaleFactor(0.7)
                                if lunarDate.isLeapMonth {
                                    Text(LocalizationService.leapMonthIndicator())
                                        .font(.caption2)
                                        .fontWeight(.semibold)
                                        .foregroundColor(.orange)
                                }
                            }
                            Image(systemName: "chevron.down")
                                .font(.caption2)
                                .fontWeight(.semibold)
                                .foregroundColor(.accentColor)
                        }
                        Text(lunarDateRangeSubtitle)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                .buttonStyle(PlainButtonStyle())

                // Left: previous month
                HStack {
                    Button {
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                        viewModel.previousMonth()
                    } label: {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundColor(.accentColor)
                            .frame(width: 40, height: 40)
                    }
                    Spacer()
                }

                // Right: next month
                HStack {
                    Spacer()
                    Button {
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                        viewModel.nextMonth()
                    } label: {
                        Image(systemName: "chevron.right")
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundColor(.accentColor)
                            .frame(width: 40, height: 40)
                    }
                }
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 8)

            Divider()
        }
        .background(Color(.systemBackground))
    }

    // MARK: - Helpers

    private var lunarDateRangeSubtitle: String {
        guard let lunar = viewModel.currentLunarDate else { return "" }
        let calendar = Calendar.current
        let firstLunar = LunarDate(year: lunar.year, month: lunar.month, day: 1, isLeapMonth: lunar.isLeapMonth)
        let firstGregorian = firstLunar.toGregorian()

        var lastGregorian = firstGregorian
        var cursor = firstGregorian
        for _ in 0..<31 {
            guard let nextDay = calendar.date(byAdding: .day, value: 1, to: cursor) else { break }
            cursor = nextDay
            let nextLunar = viewModel.lunarDate(for: cursor)
            if nextLunar.month != lunar.month || nextLunar.year != lunar.year || nextLunar.isLeapMonth != lunar.isLeapMonth {
                break
            }
            lastGregorian = cursor
        }

        let fmt = DateFormatter()
        fmt.locale = Locale(identifier: "vi_VN")
        fmt.dateFormat = "d/M"
        return "\(fmt.string(from: firstGregorian)) – \(fmt.string(from: lastGregorian))"
    }

    private func lunarContextTitle(_ lunarDate: LunarDate) -> String {
        let monthName: String
        if horizontalSizeClass == .regular {
            monthName = LocalizedStringService.shared.localizedMonthFull(lunarDate.month)
        } else {
            monthName = LocalizedStringService.shared.localizedMonthFormat(lunarDate.month)
        }
        return "\(monthName) \(lunarDate.fullYearDisplay())"
    }
}


// MARK: - Month Year Picker Sheet

struct MonthYearPickerSheet: View {
    @Binding var selectedDate: Date
    let onDone: () -> Void

    @Environment(\.horizontalSizeClass) private var horizontalSizeClass

    private let lunarMonths = Array(1...12)
    private var lunarYears: [Int] {
        let currentLunar = LunarDate.fromGregorian(Date())
        let currentTraditional = currentLunar.traditionalYear
        return Array((currentTraditional - 10)...(currentTraditional + 10))
    }

    @State private var pickerMonth: Int = 1
    @State private var pickerYear: Int = 2025

    private var monthNames: [String] {
        if horizontalSizeClass == .regular {
            return LocalizationService.lunarMonthNames()
        }
        return (1...12).map { LocalizedStringService.shared.localizedMonthFormat($0) }
    }

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text(String.localized(.selectLunarMonth))
                    .font(.headline)
                Spacer()
                Button(String.localized(.done)) { onDone() }
                    .fontWeight(.semibold)
            }
            .padding(.horizontal, 20)
            .padding(.top, 20)
            .padding(.bottom, 8)

            Divider()

            HStack(spacing: 0) {
                Picker("", selection: $pickerMonth) {
                    ForEach(lunarMonths, id: \.self) { month in
                        Text(monthNames[month - 1]).tag(month)
                    }
                }
                .pickerStyle(.wheel)
                .frame(maxWidth: .infinity)
                .clipped()

                Picker("", selection: $pickerYear) {
                    ForEach(lunarYears, id: \.self) { year in
                        Text(String(year)).tag(year)
                    }
                }
                .pickerStyle(.wheel)
                .frame(maxWidth: 120)
                .clipped()
            }
            .padding(.horizontal, 12)
        }
        .onAppear {
            let todayLunar = LunarDate.fromGregorian(Date())
            pickerMonth = todayLunar.month
            pickerYear = todayLunar.traditionalYear
        }
        .onChange(of: pickerMonth) { _, _ in updateSelectedDate() }
        .onChange(of: pickerYear) { _, _ in updateSelectedDate() }
    }

    private func updateSelectedDate() {
        let lunarYear = pickerYear - 1983
        let lunar = LunarDate(year: lunarYear, month: pickerMonth, day: 1, isLeapMonth: false)
        selectedDate = lunar.toGregorian()
    }
}

// MARK: - Date Detail Bottom Sheet

struct DateDetailBottomSheet: View {
    let date: Date
    @ObservedObject var viewModel: CalendarViewModel
    @State private var selectedEvent: Event?
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass

    private var lunarDate: LunarDate? { viewModel.lunarDate(for: date) }
    private var events: [Event] { viewModel.events(for: date) }

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                // ── Header ──────────────────────────────────────────
                VStack(spacing: 6) {
                    if let lunarDate = lunarDate {
                        Text("\(lunarDate.day)")
                            .font(.system(size: 72, weight: .bold, design: .rounded))
                            .foregroundColor(.primary)
                    } else {
                        Text(dayNumber)
                            .font(.system(size: 72, weight: .bold, design: .rounded))
                            .foregroundColor(.primary)
                    }

                    if let lunarDate = lunarDate {
                        Text(lunarMonthYearLine(lunarDate))
                            .font(.title3)
                            .fontWeight(.medium)
                            .foregroundColor(.secondary)
                    }

                    if let lunarDate = lunarDate {
                        Text(lunarDayLine(lunarDate))
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }

                    Text(String(format: String.localized(.correspondingGregorian), gregorianFormattedDate))
                        .font(.subheadline)
                        .foregroundColor(.secondary)

                    if let lunarDate = lunarDate, lunarDate.isLeapMonth {
                        Text(LocalizationService.leapMonthIndicator())
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundColor(.orange)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 4)
                            .background(Color.orange.opacity(0.15))
                            .cornerRadius(12)
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(.top, 24)
                .padding(.bottom, 20)
                .background(Color(.secondarySystemBackground))

                Divider()

                // ── Event List ───────────────────────────────────────
                if events.isEmpty {
                    VStack(spacing: 12) {
                        Image(systemName: "calendar.badge.checkmark")
                            .font(.largeTitle)
                            .foregroundColor(.secondary)
                        Text(String.localized(.noEventsOnDate))
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 40)
                } else {
                    LazyVStack(alignment: .leading, spacing: 0) {
                        ForEach(events) { event in
                            DayEventRow(event: event)
                                .contentShape(Rectangle())
                                .onTapGesture { selectedEvent = event }
                            if event.id != events.last?.id {
                                Divider().padding(.leading, 36)
                            }
                        }
                    }
                    .padding(.vertical, 8)
                }
            }
        }
        .background(Color(.systemBackground))
        .sheet(item: $selectedEvent) { event in
            EventDetailSheet(event: event)
        }
    }

    // MARK: - Formatted strings

    private var dayNumber: String {
        let f = DateFormatter()
        f.dateFormat = "d"
        return f.string(from: date)
    }

    private var gregorianFormattedDate: String {
        let f = DateFormatter()
        f.locale = Locale(identifier: "vi_VN")
        f.dateFormat = "dd/MM/yyyy"
        return f.string(from: date)
    }

    /// "Tháng Năm, Ất Tỵ (2025)" (regular) / "Tháng 5 Ất Tỵ (2025)" (compact)
    private func lunarMonthYearLine(_ lunarDate: LunarDate) -> String {
        let monthName: String
        if horizontalSizeClass == .regular {
            monthName = LocalizedStringService.shared.localizedMonthFull(lunarDate.month)
            return "\(monthName), \(lunarDate.fullYearDisplay())"
        }
        monthName = LocalizedStringService.shared.localizedMonthFormat(lunarDate.month)
        return "\(monthName) \(lunarDate.fullYearDisplay())"
    }

    /// "Ngày Giáp Dần, Tháng Quý Tỵ"
    private func lunarDayLine(_ lunarDate: LunarDate) -> String {
        let dayName   = ZodiacYearCalculator.getZodiacDay(for: date)
        let monthName = ZodiacYearCalculator.getZodiacMonth(
            lunarMonth: lunarDate.month,
            lunarYear: lunarDate.traditionalYear  // must use Gregorian-equivalent year, not iOS Chinese year
        )
        return String(format: String.localized(.lunarDayZodiacFormat), dayName, monthName)
    }
}

// MARK: - Day Event Row

struct DayEventRow: View {
    let event: Event

    var body: some View {
        HStack(alignment: .top, spacing: 14) {
            RoundedRectangle(cornerRadius: 2)
                .fill(event.isPublicHoliday ? Color.red : Color.accentColor)
                .frame(width: 4, height: 44)

            VStack(alignment: .leading, spacing: 4) {
                Text(event.title)
                    .font(.body)
                    .fontWeight(event.isPublicHoliday ? .semibold : .regular)
                    .foregroundColor(.primary)

                if !event.description.isEmpty {
                    Text(event.description)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                }

                HStack(spacing: 6) {
                    Text(event.category.displayName)
                        .font(.caption2)
                        .foregroundColor(event.isPublicHoliday ? .red : .accentColor)

                    if !event.tags.isEmpty {
                        ForEach(event.tags.prefix(3), id: \.self) { tag in
                            Text(tag)
                                .font(.caption2.weight(.medium))
                                .foregroundColor(.accentColor)
                                .padding(.horizontal, 5)
                                .padding(.vertical, 1)
                                .background(Color.accentColor.opacity(0.1))
                                .cornerRadius(4)
                        }
                        if event.tags.count > 3 {
                            Text("+\(event.tags.count - 3)")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }

            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
    }
}


/// Calendar grid displaying dates with lunar dates as primary
struct CalendarGridView: View {
    let currentDate: Date
    let selectedDate: Date?
    let events: [Event]
    let publicHolidays: [Event]
    let availableHeight: CGFloat
    let onDateSelected: (Date) -> Void
    let onEventTapped: (Event) -> Void
    let lunarDateProvider: (Date) -> LunarDate

    @Environment(\.horizontalSizeClass) private var horizontalSizeClass

    private let calendar = Calendar.current
    private let columns = Array(repeating: GridItem(.flexible()), count: 7)
    private let weekdayHeaderHeight: CGFloat = 20
    private let verticalPadding: CGFloat = 8
    private let ultraShortWeekdaySymbols = ["CN", "T2", "T3", "T4", "T5", "T6", "T7"]

    private var displayedLunarMonth: LunarDate {
        lunarDateProvider(currentDate)
    }

    private var cellHeight: CGFloat {
        let rows: CGFloat = 6
        let usable = availableHeight - weekdayHeaderHeight - verticalPadding
        return max(40, usable / rows)
    }

    var body: some View {
        VStack(spacing: 0) {
            // Weekday headers
            LazyVGrid(columns: columns, spacing: 0) {
                ForEach(Array(zip(1...7, ultraShortWeekdaySymbols)), id: \.0) { i, symbol in
                    let text = horizontalSizeClass == .regular
                        ? LocalizedStringService.shared.localizedWeekdayFull(i)
                        : symbol
                    Text(text.uppercased())
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(.secondary)
                        .frame(height: weekdayHeaderHeight)
                }
            }

            // Calendar dates
            LazyVGrid(columns: columns, spacing: 0) {
                ForEach(datesInMonth, id: \.self) { date in
                    let dateEvents = eventsForDate(date)
                    let dateHolidays = holidaysForDate(date)
                    let lunar = lunarDateProvider(date)
                    let isInDisplayedMonth = lunar.month == displayedLunarMonth.month
                        && lunar.year == displayedLunarMonth.year
                        && lunar.isLeapMonth == displayedLunarMonth.isLeapMonth

                    CalendarDateView(
                        date: date,
                        isSelected: calendar.isDate(
                            date,
                            inSameDayAs: selectedDate ?? Date.distantPast
                        ),
                        isToday: calendar.isDateInToday(date),
                        isCurrentMonth: isInDisplayedMonth,
                        lunarDate: lunar,
                        events: dateEvents,
                        holidays: dateHolidays,
                        cellHeight: cellHeight,
                        onTap: { onDateSelected(date) },
                        onEventTap: {
                            onDateSelected(date)
                        }
                    )
                }
            }
        }
        .padding(.vertical, 4)
    }

    private var datesInMonth: [Date] {
        let lunar = displayedLunarMonth

        // Convert first day of lunar month to Gregorian
        let firstOfMonth = LunarDate(year: lunar.year, month: lunar.month, day: 1, isLeapMonth: lunar.isLeapMonth)
        let firstGregorian = firstOfMonth.toGregorian()

        // Collect all Gregorian dates in this lunar month
        var monthDates: [Date] = []
        var cursor = firstGregorian
        for _ in 0..<31 {
            monthDates.append(cursor)
            guard let nextDay = calendar.date(byAdding: .day, value: 1, to: cursor) else { break }
            cursor = nextDay
            let nextLunar = lunarDateProvider(cursor)
            if nextLunar.month != lunar.month || nextLunar.year != lunar.year || nextLunar.isLeapMonth != lunar.isLeapMonth {
                break
            }
        }

        // Leading dates from previous lunar month to fill the first row
        let firstWeekday = calendar.component(.weekday, from: firstGregorian)
        let daysToSubtract = (firstWeekday - calendar.firstWeekday + 7) % 7

        var allDates: [Date] = []
        if let startDate = calendar.date(byAdding: .day, value: -daysToSubtract, to: firstGregorian) {
            var leadingCursor = startDate
            while leadingCursor < firstGregorian {
                allDates.append(leadingCursor)
                guard let next = calendar.date(byAdding: .day, value: 1, to: leadingCursor) else { break }
                leadingCursor = next
            }
        }

        allDates.append(contentsOf: monthDates)

        // Trailing dates to fill 6 weeks (42 cells)
        let remaining = 42 - allDates.count
        if remaining > 0, let lastDate = allDates.last {
            var trailingCursor = calendar.date(byAdding: .day, value: 1, to: lastDate) ?? lastDate
            for _ in 0..<remaining {
                allDates.append(trailingCursor)
                trailingCursor = calendar.date(byAdding: .day, value: 1, to: trailingCursor) ?? trailingCursor
            }
        }

        return allDates
    }

    private func eventsForDate(_ date: Date) -> [Event] {
        return events.filter { event in
            event.occurs(on: date)
        }
    }
    
    private func holidaysForDate(_ date: Date) -> [Event] {
        return publicHolidays.filter { holiday in
            holiday.occurs(on: date)
        }
    }
}

/// Individual calendar date cell with lunar date as primary display
struct CalendarDateView: View {
    let date: Date
    let isSelected: Bool
    let isToday: Bool
    let isCurrentMonth: Bool
    let lunarDate: LunarDate?
    let events: [Event]
    let holidays: [Event]
    let cellHeight: CGFloat
    let onTap: () -> Void
    let onEventTap: () -> Void

    private var hasEvents: Bool { !events.isEmpty }
    private var hasHolidays: Bool { !holidays.isEmpty }
    private var totalCount: Int { events.count + holidays.count }

    private var gregorianDayFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateFormat = "d"
        return formatter
    }

    var body: some View {
        VStack(spacing: 1) {
            Text("\(lunarDate?.day ?? 0)")
                .font(.system(size: 17, weight: .medium, design: .rounded))
                .foregroundColor(primaryTextColor)
                .frame(height: 36)

            Text(gregorianDayFormatter.string(from: date))
                .font(.system(size: 9, weight: .regular))
                .foregroundColor(secondaryTextColor)

            // Event title chips (up to 2)
            if totalCount > 0 {
                let chips = eventChips
                VStack(spacing: 1) {
                    ForEach(chips.indices, id: \.self) { i in
                        let (title, isHoliday) = chips[i]
                        Text(title)
                            .font(.system(size: 7, weight: .medium))
                            .lineLimit(1)
                            .foregroundColor(isHoliday ? .red : .accentColor)
                            .padding(.horizontal, 2)
                            .padding(.vertical, 1)
                            .frame(maxWidth: .infinity)
                            .background(
                                RoundedRectangle(cornerRadius: 2)
                                    .fill(isHoliday ? Color.red.opacity(0.12) : Color.accentColor.opacity(0.12))
                            )
                    }
                }
                .padding(.horizontal, 1)
            }

        }
        .frame(maxWidth: .infinity)
        .frame(height: cellHeight)
        .padding(.vertical, 1)
        .background(cellBackground)
        .cornerRadius(8)
        .opacity(isCurrentMonth ? 1.0 : 0.25)
        .contentShape(Rectangle())
        .onTapGesture {
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
            if totalCount > 0 {
                onEventTap()
            } else {
                onTap()
            }
        }
        .onLongPressGesture {
            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
            onTap()
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(accessibilityLabel)
        .accessibilityHint(accessibilityHint)
        .accessibilityAddTraits(accessibilityTraits)
    }

    private var eventChips: [(String, Bool)] {
        var chips: [(String, Bool)] = []
        for h in holidays.prefix(2) { chips.append((h.title, true)) }
        let remaining = 2 - chips.count
        for e in events.prefix(remaining) { chips.append((e.title, false)) }
        return chips
    }

    private var cellBackground: Color {
        if isToday { return .calendarTodayBackground }
        if isSelected { return .calendarSelectedBackground }
        return .clear
    }

    private var primaryTextColor: Color {
        if isToday { return .white }
        if hasHolidays { return .calendarHolidayText }
        return .primary
    }

    private var secondaryTextColor: Color {
        if isToday { return .white.opacity(0.7) }
        return .secondary.opacity(0.6)
    }

    // MARK: - Accessibility

    private var accessibilityLabel: String {
        let gregorianDay = gregorianDayFormatter.string(from: date)
        var label = "Date \(gregorianDay)"
        if let lunarDate = lunarDate {
            label += ", Lunar day \(lunarDate.day)"
            if lunarDate.isLeapMonth { label += " in leap month" }
        }
        if isToday { label += ", today" }
        if isSelected { label += ", selected" }
        if hasHolidays, let h = holidays.first { label += ", holiday: \(h.title)" }
        if hasEvents { label += ", has events" }
        return label
    }

    private var accessibilityHint: String {
        (hasHolidays || hasEvents) ? "Double tap to view details" : "Double tap to select this date"
    }

    private var accessibilityTraits: AccessibilityTraits {
        var traits: AccessibilityTraits = [.isButton]
        if isSelected { traits.formUnion(.isSelected) }
        return traits
    }
}

/// Enhanced event detail sheet for holidays and events with cultural information
struct EventDetailSheet: View {
    let event: Event
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Event header with enhanced styling
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Text(event.title)
                                .font(.largeTitle)
                                .fontWeight(.bold)
                                .foregroundColor(
                                    event.isPublicHoliday ? .red : .primary
                                )

                            Spacer()

                            if event.isPublicHoliday {
                                Image(systemName: "star.fill")
                                    .foregroundColor(.red)
                                    .font(.title2)
                            }
                        }

                        if event.recurrence.isRepeating {
                            // Recurrence description
                            HStack(spacing: 8) {
                                Image(systemName: "repeat")
                                    .foregroundColor(.accentColor)

                                Text(event.recurrenceDescription)
                                    .font(.headline)
                                    .foregroundColor(.primary)
                            }
                        } else {
                            // Lunar date with enhanced display
                            HStack(spacing: 8) {
                                Image(systemName: "calendar.circle.fill")
                                    .foregroundColor(.accentColor)

                                VStack(alignment: .leading, spacing: 2) {
                                    Text(lunarDateDisplayText(event.lunarDate))
                                        .font(.headline)
                                        .foregroundColor(.primary)

                                    if event.lunarDate.isLeapMonth {
                                        HStack {
                                            Text(LocalizationService.leapMonthIndicator())
                                            .font(.caption)
                                            .fontWeight(.semibold)
                                            .foregroundColor(.orange)
                                            .padding(.horizontal, 8)
                                            .padding(.vertical, 3)
                                            .background(Color.orange.opacity(0.2))
                                            .cornerRadius(6)

                                            Text(localized: .leapMonth)
                                                .font(.caption2)
                                                .foregroundColor(.secondary)
                                        }
                                    }
                                }
                            }

                            // Gregorian date
                            HStack(spacing: 8) {
                                Image(systemName: "calendar")
                                    .foregroundColor(.secondary)

                                Text(
                                    DateFormatter.localizedString(
                                        from: event.gregorianDate,
                                        dateStyle: .full,
                                        timeStyle: .none
                                    )
                                )
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                            }
                        }
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(12)

                    // Holiday-specific information (removed — not currently useful)

                    // Recurring indicator
                    if event.recurrence.isRepeating && !event.isPublicHoliday {
                        HStack(spacing: 4) {
                            Image(systemName: "repeat")
                                .font(.caption)
                            Text(event.recurrence.displayName)
                                .font(.caption)
                        }
                        .foregroundColor(.accentColor)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color.accentColor.opacity(0.1))
                        .cornerRadius(8)
                    }

                    // Event description
                    if !event.description.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            Label(String.localized(.description), systemImage: "text.alignleft")
                                .font(.headline)
                                .foregroundColor(.primary)

                            Text(event.description)
                                .font(.body)
                                .padding()
                                .background(Color(.systemGray6))
                                .cornerRadius(8)
                        }
                    }

                    // Category and additional details
                    VStack(alignment: .leading, spacing: 12) {
                        Label(String.localized(.category), systemImage: "tag.fill")
                            .font(.headline)
                            .foregroundColor(.primary)

                        HStack {
                            Text(event.category.displayName)
                                .font(.subheadline)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(Color.accentColor.opacity(0.1))
                                .foregroundColor(.accentColor)
                                .cornerRadius(8)

                            Spacer()
                        }

                        if !event.reminderSettings.isEmpty {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(localized: .reminders)
                                    .font(.subheadline)
                                    .fontWeight(.medium)

                                ForEach(event.reminderSettings, id: \.self) {
                                    reminder in
                                    HStack {
                                        Image(systemName: "bell.fill")
                                            .foregroundColor(.orange)
                                            .font(.caption)

                                        Text(reminder.displayName)
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                }
                            }
                        }
                    }

                    Spacer()
                }
                .padding()
            }
            .navigationTitle(
                event.isPublicHoliday
                    ? String.localized(.holidayDetails)
                    : String.localized(.eventDetails)
            )
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    LocalizedButton(.done) {
                        dismiss()
                    }
                }
            }
        }
    }

    private func lunarDateDisplayText(_ lunarDate: LunarDate) -> String {
        return LocalizationService.lunarDateDisplayText(lunarDate)
    }
}


#Preview {
    CalendarView(
        lunarCalendarService: MockLunarCalendarService(),
        dataManager: MockDataManager()
    )
}

// MARK: - Mock Services for Preview
class MockLunarCalendarService: LunarCalendarService {
    func convertToLunar(gregorian: Date) -> LunarDate {
        return LunarDate(year: 2024, month: 1, day: 1, isLeapMonth: false)
    }

    func convertToGregorian(lunar: LunarDate) -> Date {
        return Date()
    }

    func getPublicHolidays(year: Int) -> [Event] {
        return []
    }

    func validateLunarDate(_ date: LunarDate) -> Bool {
        return true
    }

    func getCurrentLunarDate() -> LunarDate {
        return LunarDate(year: 2024, month: 1, day: 1, isLeapMonth: false)
    }
}

/// Loading overlay view with progress indicator
struct LoadingOverlayView: View {
    @State private var isAnimating = false

    var body: some View {
        ZStack {
            Color.black.opacity(0.3)
                .ignoresSafeArea()

            VStack(spacing: 16) {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    .scaleEffect(1.2)

                Text(localized: .loading)
                    .font(.subheadline)
                    .foregroundColor(.white)
                    .fontWeight(.medium)
            }
            .padding(24)
            .background(Color.black.opacity(0.7))
            .cornerRadius(12)
            .scaleEffect(isAnimating ? 1.0 : 0.8)
            .opacity(isAnimating ? 1.0 : 0.0)
            .onAppear {
                withAnimation(.easeOut(duration: 0.3)) {
                    isAnimating = true
                }
            }
        }
    }
}

class MockDataManager: DataManager {
    func saveEvent(_ event: Event) async throws {}
    func saveEvents(_ events: [Event]) async throws {}
    func fetchEvents(for dateRange: DateInterval) async throws -> [Event] {
        return []
    }
    func fetchAllEvents() async throws -> [Event] { return [] }
    func deleteEvent(_ event: Event) async throws {}
    func updateEvent(_ event: Event) async throws {}
    func fetchEvents(for lunarDate: LunarDate) async throws -> [Event] {
        return []
    }
    func getEventCount() async -> Int { return 0 }
    func clearAllEvents() async throws {}
}

