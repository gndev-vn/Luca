//
//  LucaApp.swift
//  Luca
//
//  Created by Galvin Nguyen on 16/12/25.
//

import SwiftUI
import UserNotifications

@main
struct LucaApp: App {
    
    // MARK: - Services
    
    /// Core Data stack for data persistence
    @StateObject private var coreDataStack = CoreDataStack.shared
    
    /// Notification manager for handling reminders
    private let notificationManager: NotificationManager
    
    /// Data manager for accessing events
    private let dataManager: DataManager

    /// Lunar calendar service for date conversion
    private let lunarCalendarService: LunarCalendarService
    
    /// Dynamic reminder service for automatic updates
    private let dynamicReminderService: DynamicReminderService

    /// Settings manager for user preferences
    private let settingsManager: SettingsManager
    
    /// Notification delegate (needs to be stored to prevent deallocation)
    private let notificationDelegate: NotificationDelegate
    
    /// Theme manager for handling app themes
    @StateObject private var themeManager: ThemeManager

    /// Accessibility manager for handling accessibility features
    @StateObject private var accessibilityManager = AccessibilityManager()
    
    /// App initialization service
    @StateObject private var initializationService: AppInitializationService
    
    // MARK: - Initialization
    
    init() {
        // Initialize services with shared instances
        let notificationManager = DefaultNotificationManager()
        let lunarCalendarService = DefaultLunarCalendarService()
        let dataManager = DefaultDataManager(coreDataStack: CoreDataStack.shared)
        
        self.notificationManager = notificationManager
        self.lunarCalendarService = lunarCalendarService
        self.dataManager = dataManager
        
        // Create and store notification delegate to prevent deallocation
        self.notificationDelegate = NotificationDelegate(
            notificationManager: notificationManager
        )
        
        // Initialize theme manager
        let settingsManager = UserDefaultsSettingsManager()
        self.settingsManager = settingsManager
        self._themeManager = StateObject(wrappedValue: ThemeManager(settingsManager: settingsManager))
        
        let dynamicReminderService = DynamicReminderService(
            notificationManager: notificationManager,
            dataManager: dataManager,
            settingsManager: settingsManager
        )
        self.dynamicReminderService = dynamicReminderService

        // Initialize app initialization service
        self._initializationService = StateObject(wrappedValue: AppInitializationService(
            settingsManager: settingsManager,
            dataManager: dataManager,
            notificationManager: notificationManager
        ))
        
        // Set up notification delegate
        UNUserNotificationCenter.current().delegate = self.notificationDelegate
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView(
                lunarCalendarService: lunarCalendarService,
                dataManager: dataManager,
                notificationManager: notificationManager,
                settingsManager: settingsManager,
                themeManager: themeManager
            )
                .environmentObject(coreDataStack)
                .environmentObject(initializationService)
                .environment(\.themeManager, themeManager)
                .environment(\.accessibilityManager, accessibilityManager)
                .preferredColorScheme(themeManager.preferredColorScheme)
                .onAppear {
                    setupApp()
                }
                .onReceive(NotificationCenter.default.publisher(for: UIApplication.didBecomeActiveNotification)) { _ in
                    handleAppDidBecomeActive()
                }
                .onReceive(NotificationCenter.default.publisher(for: UIApplication.significantTimeChangeNotification)) { _ in
                    handleSignificantTimeChange()
                }
                .onOpenURL { url in
                    handleDeepLink(url)
                }
        }
    }
    
    // MARK: - App Lifecycle
    
    /// Set up the app on first launch
    private func setupApp() {
        Task {
            // Initialize the app
            await initializationService.initializeApp()
            
            // Start dynamic reminder service
            dynamicReminderService.startService()
        }
    }
    
    /// Handle app becoming active
    private func handleAppDidBecomeActive() {
        Task {
            await dynamicReminderService.handleAppDidBecomeActive()
        }
    }
    
    /// Handle significant time changes
    private func handleSignificantTimeChange() {
        Task {
            await dynamicReminderService.handleSignificantTimeChange()
        }
    }
    
    /// Handle deep link URLs
    private func handleDeepLink(_ url: URL) {
        guard let components = URLComponents(url: url, resolvingAgainstBaseURL: true),
              let scheme = components.scheme,
              scheme == "luca" else {
            return
        }
        
        let deepLink = parseDeepLink(from: components)
        
        // Post notification for ContentView to handle
        NotificationCenter.default.post(
            name: .deepLinkReceived,
            object: nil,
            userInfo: ["deepLink": deepLink]
        )
    }
    
    /// Parse deep link from URL components
    private func parseDeepLink(from components: URLComponents) -> DeepLink {
        let path = components.path
        let queryItems = components.queryItems ?? []
        
        switch path {
        case "/event":
            if let eventIdString = queryItems.first(where: { $0.name == "id" })?.value,
               let eventId = UUID(uuidString: eventIdString) {
                return .event(eventId)
            }
            return .createEvent(Date())
            
        case "/calendar":
            if let dateString = queryItems.first(where: { $0.name == "date" })?.value,
               let timestamp = Double(dateString) {
                let date = Date(timeIntervalSince1970: timestamp)
                return .calendar(date)
            }
            return .calendar(Date())
            
        case "/settings":
            if let sectionString = queryItems.first(where: { $0.name == "section" })?.value,
               let section = SettingsSection(rawValue: sectionString) {
                return .settings(section)
            }
            return .settings(.about)
            
        case "/create":
            if let dateString = queryItems.first(where: { $0.name == "date" })?.value,
               let timestamp = Double(dateString) {
                let date = Date(timeIntervalSince1970: timestamp)
                return .createEvent(date)
            }
            return .createEvent(Date())
            
        default:
            return .calendar(Date())
        }
    }
}

// MARK: - Notification Delegate

/// Handles notification responses and presentation
class NotificationDelegate: NSObject, UNUserNotificationCenterDelegate {
    
    private let notificationManager: NotificationManager
    
    init(notificationManager: NotificationManager) {
        self.notificationManager = notificationManager
    }
    
    /// Handle notification response when user interacts with notification
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        Task {
            await notificationManager.handleNotificationResponse(response)

            // Clear badge when user taps notification
            clearBadge()

            // Handle deep linking from notification
            handleNotificationDeepLink(response)

            completionHandler()
        }
    }

    /// Handle deep linking from notification response
    private func handleNotificationDeepLink(_ response: UNNotificationResponse) {
        let userInfo = response.notification.request.content.userInfo

        // Extract event ID from notification
        if let eventIdString = userInfo["eventId"] as? String,
           let eventId = UUID(uuidString: eventIdString) {
            let deepLink = DeepLink.event(eventId)

            // Post notification for ContentView to handle
            NotificationCenter.default.post(
                name: .deepLinkReceived,
                object: nil,
                userInfo: ["deepLink": deepLink]
            )
        }
    }
    
    /// Handle notification presentation when app is in foreground
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        completionHandler([.banner, .sound, .badge])
    }

    /// Clear badge when app becomes active
    func clearBadge() {
        UIApplication.shared.applicationIconBadgeNumber = 0
    }
}
