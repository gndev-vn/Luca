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
    @State private var slideForward = true // true = next month (slide left), false = prev month (slide right)
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
        VStack(spacing: 10) {
            // In-body calendar navigation bar
            calendarNavBar

            // Calendar grid fills remaining height
            GeometryReader { geometry in
                HStack {
                    Spacer(minLength: 0)
                    CalendarGridView(
                        currentDate: viewModel.currentDate,
                        selectedDate: viewModel.selectedDate,
                        customEventsProvider: { date in viewModel.customEvents(for: date) },
                        holidayEventsProvider: { date in viewModel.holidayEvents(for: date) },
                        availableHeight: geometry.size.height,
                        onDateSelected: { date in
                            viewModel.selectDate(date)
                            showingDayEvents = true
                        },
                        onEventTapped: { _ in },
                        lunarDateProvider: { date in viewModel.lunarDate(for: date) }
                    )
                    .frame(maxWidth: 520)
                    .id(viewModel.currentDate)
                    .transition(.asymmetric(
                        insertion: .move(edge: slideForward ? .trailing : .leading),
                        removal: .move(edge: slideForward ? .leading : .trailing)
                    ))
                    Spacer(minLength: 0)
                }
            }
            .animation(.easeInOut(duration: 0.25), value: viewModel.currentDate)
            .gesture(
                DragGesture(minimumDistance: 30, coordinateSpace: .local)
                    .onEnded { value in
                        let horizontal = value.translation.width
                        let vertical = value.translation.height
                        if abs(horizontal) > abs(vertical) && abs(horizontal) > 50 {
                            UIImpactFeedbackGenerator(style: .light).impactOccurred()
                            slideForward = horizontal < 0
                            if horizontal < 0 {
                                viewModel.nextMonth()
                            } else {
                                viewModel.previousMonth()
                            }
                        }
                    }
            )
        }
        .padding(.horizontal, 12)
        .padding(.bottom, 6)
        .background(Color(.systemGroupedBackground))
        .navigationTitle(String.localized(.lunarCalendar))
        .navigationBarTitleDisplayMode(.large)
        .task {
            await viewModel.loadEvents()
        }
        .onReceive(NotificationCenter.default.publisher(for: .eventsDidChange)) { _ in
            Task {
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
            MonthYearPickerSheet(selectedDate: $viewModel.currentDate)
            .presentationDetents([.height(320)])
            .presentationDragIndicator(.visible)
            .presentationBackground(.thinMaterial)
        }
    }

    // MARK: - Calendar navigation bar

    @ViewBuilder
    private var calendarNavBar: some View {
        HStack(spacing: 12) {
            Button {
                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                slideForward = false
                viewModel.previousMonth()
            } label: {
                Image(systemName: "chevron.left")
                    .font(.headline.weight(.semibold))
                    .foregroundStyle(.primary)
                    .frame(width: 36, height: 36)
                    .background(Circle().fill(Color(.secondarySystemBackground)))
            }
            .buttonStyle(.plain)

            Button {
                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                showingMonthPicker = true
            } label: {
                VStack(spacing: 2) {
                    HStack(spacing: 6) {
                        if let lunarDate = viewModel.currentLunarDate {
                            Text(lunarContextTitle(lunarDate))
                                .font(.system(.headline, design: .rounded))
                                .fontWeight(.semibold)
                                .foregroundColor(.primary)
                                .lineLimit(1)
                                .minimumScaleFactor(0.7)
                            if lunarDate.isLeapMonth {
                                Text(LocalizationService.leapMonthIndicator())
                                    .font(.caption2)
                                    .fontWeight(.semibold)
                                    .foregroundColor(.orange)
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 2)
                                    .background(Color.orange.opacity(0.16), in: Capsule())
                            }
                        }
                        Image(systemName: "chevron.down")
                            .font(.caption.weight(.bold))
                            .foregroundColor(.accentColor)
                    }
                    Text(lunarDateRangeSubtitle)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }
                .frame(maxWidth: .infinity)
                .padding(.horizontal, 10)
                .padding(.vertical, 10)
                .background(.thinMaterial, in: RoundedRectangle(cornerRadius: AppDesign.cardCornerRadius, style: .continuous))
            }
            .buttonStyle(.plain)

            Button {
                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                slideForward = true
                viewModel.nextMonth()
            } label: {
                Image(systemName: "chevron.right")
                    .font(.headline.weight(.semibold))
                    .foregroundStyle(.primary)
                    .frame(width: 36, height: 36)
                    .background(Circle().fill(Color(.secondarySystemBackground)))
            }
            .buttonStyle(.plain)
        }
        .padding(.top, 6)
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

        let fmt = SharedDateFormatters.ddMMyyyy
        return "\(String.localized(.gregorian)): \(fmt.string(from: firstGregorian)) – \(fmt.string(from: lastGregorian))"
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

    @Environment(\.horizontalSizeClass) private var horizontalSizeClass

    private var lunarYears: [Int] {
        let currentLunar = LunarDate.fromGregorian(Date())
        let currentTraditional = currentLunar.traditionalYear
        return Array((currentTraditional - 10)...(currentTraditional + 10))
    }

    private var lunarMonths: [Int] {
        let lunarYear = pickerYear - 1983
        let leapInfo = LunarCalendarConverter.getLeapMonthInfo(lunarYear)
        guard leapInfo.hasLeap, leapInfo.leapMonth > 0, leapInfo.leapMonth <= 12 else {
            return Array(1...12)
        }
        var months = Array(1...12)
        months.insert(leapInfo.leapMonth + 100, at: leapInfo.leapMonth)
        return months
    }

    @State private var pickerMonth: Int = 1
    @State private var pickerYear: Int = 2025

    private func monthLabel(for month: Int) -> String {
        let actualMonth = month > 100 ? month - 100 : month
        let isLeap = month > 100

        if isLeap {
            return LocalizedStringService.shared.localizedMonthFormat(actualMonth, isLeap: true)
        }
        if horizontalSizeClass == .regular {
            return LocalizedStringService.shared.localizedMonthFull(actualMonth)
        }
        return LocalizedStringService.shared.localizedMonthFormat(actualMonth)
    }

    var body: some View {
        VStack(spacing: 0) {
            HStack(alignment: .firstTextBaseline) {
                Text(String.localized(.selectLunarMonth))
                    .font(.title2.weight(.bold))
                    .foregroundStyle(.primary)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 28)
            .frame(maxWidth: .infinity, alignment: .leading)

            HStack(spacing: 0) {
                Picker("", selection: $pickerMonth) {
                    ForEach(lunarMonths, id: \.self) { month in
                        Text(monthLabel(for: month)).tag(month)
                    }
                }
                .pickerStyle(.wheel)
                .frame(maxWidth: .infinity)
                .clipped()
                .background(Color.clear)

                Picker("", selection: $pickerYear) {
                    ForEach(lunarYears, id: \.self) { year in
                        Text(String(year)).tag(year)
                    }
                }
                .pickerStyle(.wheel)
                .frame(maxWidth: 120)
                .clipped()
                .background(Color.clear)
            }
            .padding(.horizontal, 12)
            .padding(.top, 18)
            .padding(.bottom, 8)
            .background(
                RoundedRectangle(cornerRadius: AppDesign.cardCornerRadius, style: .continuous)
                    .fill(.ultraThinMaterial)
            )
            .overlay(
                RoundedRectangle(cornerRadius: AppDesign.cardCornerRadius, style: .continuous)
                    .stroke(Color.primary.opacity(0.06), lineWidth: 1)
            )
            .padding(.horizontal, 12)
        }
        .onAppear {
            let todayLunar = LunarDate.fromGregorian(Date())
            pickerMonth = todayLunar.isLeapMonth ? todayLunar.month + 100 : todayLunar.month
            pickerYear = todayLunar.traditionalYear
        }
        .onChange(of: pickerMonth) { _, _ in updateSelectedDate() }
        .onChange(of: pickerYear) { _, _ in
            normalizePickerMonth()
            updateSelectedDate()
        }
        .background(Color.clear)
    }

    private func normalizePickerMonth() {
        let available = lunarMonths
        if !available.contains(pickerMonth), let fallback = available.first {
            pickerMonth = fallback
        }
    }

    private func updateSelectedDate() {
        let lunarYear = pickerYear - 1983
        let isLeapMonth = pickerMonth > 100
        let month = isLeapMonth ? pickerMonth - 100 : pickerMonth
        let lunar = LunarDate(year: lunarYear, month: month, day: 1, isLeapMonth: isLeapMonth)
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
            VStack(spacing: 14) {
                HStack(spacing: 14) {
                    ZStack {
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [Color.accentColor.opacity(0.22), Color.accentColor.opacity(0.08)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 64, height: 64)
                        Text(lunarDate.map { "\($0.day)" } ?? dayNumber)
                            .font(.system(size: 27, weight: .bold, design: .rounded))
                            .foregroundColor(.primary)
                    }

                    VStack(alignment: .leading, spacing: 4) {
                        if let lunarDate = lunarDate {
                            Text(lunarMonthYearLine(lunarDate))
                                .font(.title3.weight(.semibold))

                            Text(lunarDayLine(lunarDate))
                                .font(.footnote)
                                .foregroundColor(.secondary)

                            HStack(spacing: 6) {
                                Text(String(format: String.localized(.correspondingGregorian), gregorianFormattedDate))
                                    .font(.caption)
                                    .foregroundColor(.secondary)

                                if lunarDate.isLeapMonth {
                                    Text(LocalizationService.leapMonthIndicator())
                                        .font(.caption2)
                                        .fontWeight(.semibold)
                                        .foregroundColor(.orange)
                                        .padding(.horizontal, 6)
                                        .padding(.vertical, 2)
                                        .background(.orange.opacity(0.15), in: Capsule())
                                }
                            }
                        } else {
                            Text(gregorianFormattedDate)
                                .font(.title3)
                                .fontWeight(.semibold)
                        }
                    }

                    Spacer()

                    if !events.isEmpty {
                        Label("\(events.count)", systemImage: "calendar.badge.clock")
                            .font(.caption.weight(.semibold))
                            .foregroundColor(.accentColor)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                            .background(Color.accentColor.opacity(0.12), in: Capsule())
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 14)
                .background(.thinMaterial, in: RoundedRectangle(cornerRadius: AppDesign.cardCornerRadius, style: .continuous))

                // ── Event List ───────────────────────────────────────
                if events.isEmpty {
                    VStack(spacing: 10) {
                        Image(systemName: "calendar.badge.checkmark")
                            .font(.system(size: 28))
                            .foregroundColor(.accentColor)
                        Text(String.localized(.noEventsOnDate))
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 36)
                    .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: AppDesign.cardCornerRadius, style: .continuous))
                } else {
                    LazyVStack(alignment: .leading, spacing: 10) {
                        ForEach(events) { event in
                            DayEventRow(event: event)
                                .contentShape(Rectangle())
                                .onTapGesture { selectedEvent = event }
                        }
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 12)
            .padding(.bottom, 20)
        }
        .scrollIndicators(.hidden)
        .background(Color(.systemGroupedBackground))
        .sheet(item: $selectedEvent) { event in
            EventDetailSheet(event: event)
        }
    }

    // MARK: - Formatted strings

    private var dayNumber: String {
        SharedDateFormatters.dayNumber.string(from: date)
    }

    private var gregorianFormattedDate: String {
        SharedDateFormatters.ddMMyyyy.string(from: date)
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
            lunarYear: lunarDate.traditionalYear  // must use Gregorian-equivalent year, not iOS lunar year
        )
        return String(format: String.localized(.lunarDayZodiacFormat), dayName, monthName)
    }
}

// MARK: - Day Event Row

struct DayEventRow: View {
    let event: Event

    var body: some View {
        HStack(spacing: 14) {
            // Category dot
            Circle()
                .fill(categoryColor)
                .frame(width: 10, height: 10)

            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 8) {
                    Text(event.title)
                        .font(.body)
                        .fontWeight(event.isPublicHoliday ? .semibold : .regular)
                        .foregroundColor(.primary)
                        .lineLimit(1)

                    if event.isPublicHoliday {
                        Image(systemName: "star.fill")
                            .font(.caption2)
                            .foregroundColor(.red)
                    }
                }

                if !event.description.isEmpty {
                    Text(event.description)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(2)
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
                }
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundColor(.secondary.opacity(0.5))
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 12)
        .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: AppDesign.cardCornerRadius, style: .continuous))
    }

    private var categoryColor: Color {
        if event.isPublicHoliday { return .red }
        switch event.category {
        case .cultural: return .purple
        case .religious: return .indigo
        case .personal: return .accentColor
        }
    }
}


/// Calendar grid displaying dates with lunar dates as primary
struct CalendarGridView: View {
    let currentDate: Date
    let selectedDate: Date?
    let customEventsProvider: (Date) -> [Event]
    let holidayEventsProvider: (Date) -> [Event]
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
            LazyVGrid(columns: columns, spacing: 4) {
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
            }.padding(.vertical, 8)

            // Calendar dates
            LazyVGrid(columns: columns, spacing: 2) {
                ForEach(datesInMonth, id: \.self) { date in
                    let dateEvents = customEventsProvider(date)
                    let dateHolidays = holidayEventsProvider(date)
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
        .padding(.horizontal, 8)
        .padding(.top, 6)
        .padding(.bottom, 10)
        .background(Color(.systemBackground), in: RoundedRectangle(cornerRadius: AppDesign.cardCornerRadius, style: .continuous))
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

    var body: some View {
        VStack(spacing: 0) {
            Text("\(lunarDate?.day ?? 0)")
                .font(.system(size: 17, weight: .medium, design: .rounded))
                .foregroundColor(primaryTextColor)
                .frame(height: 28)

            Text(SharedDateFormatters.dayNumber.string(from: date))
                .font(.system(size: 10, weight: .regular))
                .foregroundColor(secondaryTextColor)
                .padding(.bottom, 2)

            // Event title chips (up to 2)
            if totalCount > 0 {
                let chips = eventChips
                VStack(spacing: 1) {
                    ForEach(chips.indices, id: \.self) { i in
                        let (title, isHoliday) = chips[i]
                        let chipTextColor: Color = {
                            if isHoliday { return .red }
                            if isToday { return .white }
                            return .accentColor
                        }()
                        let chipBackgroundColor: Color = {
                            if isHoliday { return Color.red.opacity(0.12) }
                            if isToday { return Color.white.opacity(0.25) }
                            return Color.accentColor.opacity(0.12)
                        }()

                        Text(title)
                            .font(.system(size: 7, weight: .medium))
                            .lineLimit(1)
                            .foregroundColor(chipTextColor)
                            .padding(.horizontal, 2)
                            .padding(.vertical, 1)
                            .frame(maxWidth: .infinity)
                            .background(
                                RoundedRectangle(cornerRadius: 2)
                                    .fill(chipBackgroundColor)
                            )
                    }
                }
                .padding(.horizontal, 1)
            }

        }
        .frame(maxWidth: .infinity)
        .frame(height: cellHeight, alignment: .top)
        .padding(.vertical, 1)
        .background(cellBackground)
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(borderColor, lineWidth: borderWidth)
        )
        .cornerRadius(10)
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
        if hasHolidays || hasEvents { return Color.accentColor.opacity(0.04) }
        return .clear
    }

    private var borderColor: Color {
        if isToday { return .accentColor.opacity(0.35) }
        if isSelected { return .accentColor.opacity(0.5) }
        return .clear
    }

    private var borderWidth: CGFloat {
        (isToday || isSelected) ? 1 : 0
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
        let gregorianDay = SharedDateFormatters.dayNumber.string(from: date)
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
        NavigationStack {
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
                                    SharedDateFormatters.fullDate.string(from: event.gregorianDate)
                                )
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                            }
                        }
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(AppDesign.cardCornerRadius)

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
                                .cornerRadius(AppDesign.cardCornerRadius)
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
            .cornerRadius(AppDesign.cardCornerRadius)
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
