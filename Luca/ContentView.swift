//
//  ContentView.swift
//  Luca
//
//  Created by Galvin Nguyen on 16/12/25.
//

import SwiftUI
import Combine

/// Main content view with enhanced navigation and deep linking support
struct ContentView: View {
    // Services
    private let lunarCalendarService: LunarCalendarService
    private let dataManager: DataManager
    private let notificationManager: NotificationManager
    private let settingsManager: SettingsManager
    private let themeManager: ThemeManager
    
    // Navigation state
    @StateObject private var navigationCoordinator = NavigationCoordinator()
    @State private var selectedTab: AppTab = .calendar

    
    // Deep linking state
    @State private var pendingDeepLink: DeepLink?
    
    // Onboarding state
    @State private var showingOnboarding = false
    @State private var hasCompletedOnboarding = false
    
    // Initialization state
    @EnvironmentObject private var initializationService: AppInitializationService
    
    @MainActor
    init() {
        let settingsManager = UserDefaultsSettingsManager()
        self.init(
            lunarCalendarService: DefaultLunarCalendarService(),
            dataManager: DefaultDataManager(coreDataStack: CoreDataStack.shared),
            notificationManager: DefaultNotificationManager(),
            settingsManager: settingsManager,
            themeManager: ThemeManager(settingsManager: settingsManager)
        )
    }

    init(
        lunarCalendarService: LunarCalendarService,
        dataManager: DataManager,
        notificationManager: NotificationManager,
        settingsManager: SettingsManager,
        themeManager: ThemeManager
    ) {
        self.lunarCalendarService = lunarCalendarService
        self.dataManager = dataManager
        self.notificationManager = notificationManager
        self.settingsManager = settingsManager
        self.themeManager = themeManager
    }
    
    var body: some View {
        Group {
            switch initializationService.initializationState {
            case .notStarted, .inProgress:
                AppLoadingView(initializationService: initializationService)
                
            case .failed(let error):
                AppInitializationErrorView(error: error) {
                    Task {
                        await initializationService.initializeApp()
                    }
                }
                
            case .completed:
                mainAppView
            }
        }
        .onAppear {
            setupApp()
        }
        .onReceive(NotificationCenter.default.publisher(for: .deepLinkReceived)) { notification in
            handleDeepLink(notification)
        }
        .onReceive(NotificationCenter.default.publisher(for: UIApplication.didBecomeActiveNotification)) { _ in
            handleAppBecameActive()
        }
        .fullScreenCover(isPresented: $showingOnboarding) {
            OnboardingView(
                settingsManager: settingsManager,
                notificationManager: notificationManager,
                onComplete: {
                    hasCompletedOnboarding = true
                    showingOnboarding = false
                }
            )
        }
    }
    
    @ViewBuilder
    private var mainAppView: some View {
        TabView(selection: $selectedTab) {
            // Calendar Tab
            NavigationStack(path: $navigationCoordinator.calendarPath) {
                CalendarView(
                    lunarCalendarService: lunarCalendarService,
                    dataManager: dataManager
                )
                .navigationDestination(for: CalendarDestination.self) { destination in
                    destinationView(for: destination)
                }
            }
            .tabItem {
                LocalizedLabel(.calendar, systemImage: "calendar")
            }
            .tag(AppTab.calendar)
            
            // Events Tab
            NavigationStack(path: $navigationCoordinator.eventsPath) {
                EventManagementView(
                    lunarCalendarService: lunarCalendarService,
                    dataManager: dataManager,
                    notificationManager: notificationManager
                )
                .navigationDestination(for: EventDestination.self) { destination in
                    destinationView(for: destination)
                }
            }
            .tabItem {
                LocalizedLabel(.events, systemImage: "list.bullet")
            }
            .tag(AppTab.events)
            
            // Settings Tab
            NavigationStack(path: $navigationCoordinator.settingsPath) {
                SettingsView(
                    settingsManager: settingsManager,
                    notificationManager: notificationManager,
                    dataManager: dataManager,
                    reseedHolidays: { [dataManager, settingsManager] in
                        var settings = settingsManager.loadSettings()
                        settings.hasSeededPublicHolidays = false
                        settingsManager.saveSettings(settings)

                        let existingEvents = try await dataManager.fetchAllEvents()
                        for event in existingEvents {
                            try await dataManager.deleteEvent(event)
                        }

                        let holidayService = HolidayService()
                        holidayService.clearCache()

                        let currentYear = Calendar.current.component(.year, from: Date())
                        let iosYear = currentYear - 1983
                        let fromYear = iosYear - 3
                        let toYear = iosYear + 7
                        try await holidayService.seedPublicHolidays(to: dataManager, from: fromYear, to: toYear)
                    }
                )
                .navigationDestination(for: SettingsDestination.self) { destination in
                    destinationView(for: destination)
                }
            }
            .tabItem {
                LocalizedLabel(.settings, systemImage: "gear")
            }
            .tag(AppTab.settings)
        }
        .environmentObject(navigationCoordinator)

        .onAppear {
            setupApp()
        }
        .onReceive(NotificationCenter.default.publisher(for: .deepLinkReceived)) { notification in
            handleDeepLink(notification)
        }
        .onReceive(NotificationCenter.default.publisher(for: UIApplication.didBecomeActiveNotification)) { _ in
            handleAppBecameActive()
        }
        .onChange(of: selectedTab) { _, newTab in
            navigationCoordinator.currentTab = newTab
        }
    }
    
    // MARK: - Setup and Lifecycle
    
    /// Initial app setup
    private func setupApp() {
        // Wait for initialization to complete before checking onboarding
        Task {
            // Wait for initialization to complete
            while initializationService.initializationState != .completed {
                if case .failed = initializationService.initializationState {
                    return // Don't proceed if initialization failed
                }
                try? await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds
            }
            
            await MainActor.run {
                checkOnboardingStatus()
                processPendingDeepLink()
            }
        }
    }
    
    /// Check if user has completed onboarding
    private func checkOnboardingStatus() {
        let settings = settingsManager.loadSettings()
        hasCompletedOnboarding = settings.hasCompletedOnboarding
        
        // Show onboarding if not completed
        if !hasCompletedOnboarding {
            showingOnboarding = true
        }
    }
    
    /// Handle app becoming active (for state restoration)
    private func handleAppBecameActive() {
        // Clear notification badge
        UIApplication.shared.applicationIconBadgeNumber = 0

        // Restore navigation state if needed
        navigationCoordinator.restoreNavigationState()

        // Process any pending deep links
        processPendingDeepLink()
    }
    
    /// Handle deep link notifications
    private func handleDeepLink(_ notification: Notification) {
        guard let deepLink = notification.userInfo?["deepLink"] as? DeepLink else { return }
        
        // Store the deep link if the app isn't fully loaded yet
        if navigationCoordinator.isReady {
            processDeepLink(deepLink)
        } else {
            pendingDeepLink = deepLink
        }
    }
    
    /// Process pending deep links when app is ready
    private func processPendingDeepLink() {
        guard let deepLink = pendingDeepLink else { return }
        pendingDeepLink = nil
        processDeepLink(deepLink)
    }
    
    /// Process a deep link by navigating to the appropriate destination
    private func processDeepLink(_ deepLink: DeepLink) {
        switch deepLink {
        case .event(let eventId):
            navigateToEvent(eventId: eventId)
        case .calendar(let date):
            navigateToCalendar(date: date)
        case .settings(let section):
            navigateToSettings(section: section)
        case .createEvent(let date):
            navigateToCreateEvent(date: date)
        }
    }
    
    // MARK: - Navigation Methods
    
    /// Navigate to a specific event
    private func navigateToEvent(eventId: UUID) {
        selectedTab = .events
        navigationCoordinator.navigateToEvent(eventId: eventId)
    }
    
    /// Navigate to calendar with specific date
    private func navigateToCalendar(date: Date) {
        selectedTab = .calendar
        navigationCoordinator.navigateToCalendar(date: date)
    }
    
    /// Navigate to settings section
    private func navigateToSettings(section: SettingsSection) {
        selectedTab = .settings
        navigationCoordinator.navigateToSettings(section: section)
    }
    
    /// Navigate to create event with pre-selected date
    private func navigateToCreateEvent(date: Date) {
        selectedTab = .events
        navigationCoordinator.navigateToCreateEvent(date: date)
    }
    
    // MARK: - Destination Views
    
    /// Create destination view for calendar navigation
    @ViewBuilder
    private func destinationView(for destination: CalendarDestination) -> some View {
        switch destination {
        case .eventDetail(let eventId):
            EventDetailByIdView(
                eventId: eventId,
                dataManager: dataManager,
                notificationManager: notificationManager,
                lunarCalendarService: lunarCalendarService
            )
        case .dateDetail(let date):
            DateDetailView(
                date: date,
                lunarCalendarService: lunarCalendarService,
                dataManager: dataManager
            )
        }
    }
    
    /// Create destination view for events navigation
    @ViewBuilder
    private func destinationView(for destination: EventDestination) -> some View {
        switch destination {
        case .eventDetail(let eventId):
            EventDetailByIdView(
                eventId: eventId,
                dataManager: dataManager,
                notificationManager: notificationManager,
                lunarCalendarService: lunarCalendarService
            )
        case .createEvent(_):
            EventFormView(
                viewModel: EventViewModel(dataManager: dataManager, notificationManager: notificationManager),
                lunarCalendarService: lunarCalendarService
            )
        case .eventList(_):
            EventListView(
                viewModel: EventViewModel(dataManager: dataManager, notificationManager: notificationManager),
                lunarCalendarService: lunarCalendarService
            )
        }
    }
    
    /// Create destination view for settings navigation
    @ViewBuilder
    private func destinationView(for destination: SettingsDestination) -> some View {
        switch destination {
        case .about:
            AboutView()
        case .developer:
            DeveloperSettingsView(
                settingsManager: settingsManager,
                notificationManager: notificationManager,
                dataManager: dataManager,
                reseedHolidays: reseedHolidaysClosure
            )
        }
    }

    private var reseedHolidaysClosure: (() async throws -> Void) {
        { [dataManager, settingsManager] in
            var settings = settingsManager.loadSettings()
            settings.hasSeededPublicHolidays = false
            settingsManager.saveSettings(settings)

            let existingEvents = try await dataManager.fetchAllEvents()
            for event in existingEvents {
                try await dataManager.deleteEvent(event)
            }

            let holidayService = HolidayService()
            holidayService.clearCache()

            let currentYear = Calendar.current.component(.year, from: Date())
            let iosYear = currentYear - 1983
            let fromYear = iosYear - 3
            let toYear = iosYear + 7
            try await holidayService.seedPublicHolidays(to: dataManager, from: fromYear, to: toYear)
        }
    }
}

// MARK: - Navigation Types

/// App tab enumeration
enum AppTab: String, CaseIterable {
    case calendar = "calendar"
    case events = "events"
    case settings = "settings"
    
    var displayName: String {
        switch self {
        case .calendar: return "Calendar"
        case .events: return "Events"
        case .settings: return "Settings"
        }
    }
}

/// Calendar navigation destinations
enum CalendarDestination: Hashable {
    case eventDetail(UUID)
    case dateDetail(Date)
}

/// Events navigation destinations
enum EventDestination: Hashable {
    case eventDetail(UUID)
    case createEvent(Date?)
    case eventList(EventCategory?)
}

/// Settings navigation destinations
enum SettingsDestination: Hashable {
    case about
    case developer
}

/// Settings sections for deep linking
enum SettingsSection: String {
    case notifications = "notifications"
    case theme = "theme"
    case about = "about"
}

/// Deep link types
enum DeepLink {
    case event(UUID)
    case calendar(Date)
    case settings(SettingsSection)
    case createEvent(Date)
}

// MARK: - Navigation Coordinator

/// Centralized navigation coordinator for managing app navigation state
@MainActor
class NavigationCoordinator: ObservableObject {
    @Published var calendarPath = NavigationPath()
    @Published var eventsPath = NavigationPath()
    @Published var settingsPath = NavigationPath()
    @Published var currentTab: AppTab = .calendar
    @Published var isReady = false
    
    init() {
        // Mark as ready after a short delay to ensure all views are loaded
        Task {
            try? await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds
            isReady = true
        }
    }
    
    @Published var currentEventId: UUID?

    /// Navigate to event detail
    func navigateToEvent(eventId: UUID) {
        guard currentEventId != eventId else { return }
        currentEventId = eventId
        eventsPath.append(EventDestination.eventDetail(eventId))
    }
    
    /// Navigate to calendar with specific date
    func navigateToCalendar(date: Date) {
        currentEventId = nil
        calendarPath.append(CalendarDestination.dateDetail(date))
    }

    /// Navigate to settings section
    func navigateToSettings(section: SettingsSection) {
        currentEventId = nil
        switch section {
        case .about:
            settingsPath.append(SettingsDestination.about)
        default:
            break
        }
    }

    /// Navigate to create event
    func navigateToCreateEvent(date: Date) {
        currentEventId = nil
        eventsPath.append(EventDestination.createEvent(date))
    }
    
    /// Clear all navigation paths
    func clearAllPaths() {
        calendarPath = NavigationPath()
        eventsPath = NavigationPath()
        settingsPath = NavigationPath()
    }
    
    /// Restore navigation state (placeholder for future implementation)
    func restoreNavigationState() {
        // This could restore navigation state from UserDefaults or other persistence
        // For now, it's a placeholder
    }
    
    /// Save current navigation state (placeholder for future implementation)
    func saveNavigationState() {
        // This could save navigation state to UserDefaults for restoration
        // For now, it's a placeholder
    }
}

// MARK: - Notification Extensions

extension Notification.Name {
    static let deepLinkReceived = Notification.Name("deepLinkReceived")
}

// MARK: - Event Placeholder

extension Event {
    static let placeholder = Event(
        title: "Placeholder Event",
        description: "This is a placeholder event",
        lunarDate: LunarDate(year: 2024, month: 1, day: 1, isLeapMonth: false),
        category: .personal
    )
}

#Preview {
    ContentView()
}
