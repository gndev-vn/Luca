//
//  LucaApp.swift
//  Luca
//
//  Created by Galvin Nguyen on 16/12/25.
//

import SwiftUI
import UserNotifications
import Combine
import AppIntents

// MARK: - Quick Action Handler

/// Shared observable object that bridges AppIntents to SwiftUI views
@MainActor
class QuickActionHandler: ObservableObject {
    static let shared = QuickActionHandler()
    @Published var pendingAction: QuickActionType?
    private var lastHandledAction: QuickActionType?
    private var lastHandledAt: Date = .distantPast
    
    func handle(_ action: QuickActionType) {
        let now = Date()
        if lastHandledAction == action, now.timeIntervalSince(lastHandledAt) < 0.5 {
            return
        }
        lastHandledAction = action
        lastHandledAt = now
        pendingAction = action
    }
}

/// Quick action types for home screen shortcuts
enum QuickActionType: String {
    case createEvent = "create-event"
    case toggleNotifications = "toggle-notifications"
}

@main
struct LucaApp: App {
    
    // MARK: - Quick Actions
    
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @StateObject private var quickActionHandler = QuickActionHandler.shared
    
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
                settingsManager: settingsManager
            )
                .environmentObject(coreDataStack)
                .environmentObject(initializationService)
                .environmentObject(quickActionHandler)
                .environment(\.themeManager, themeManager)
                .environment(\.accessibilityManager, accessibilityManager)
                .preferredColorScheme(themeManager.preferredColorScheme)
                .onAppear {
                    setupApp()
                }
                .onReceive(NotificationCenter.default.publisher(for: UIApplication.didBecomeActiveNotification)) { _ in
                    handleAppDidBecomeActive()
                }
                .onReceive(NotificationCenter.default.publisher(for: .settingsDidChange)) { _ in
                    Task { @MainActor in
                        updateHomeScreenQuickActions()
                    }
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

            await MainActor.run {
                updateHomeScreenQuickActions()
            }
        }
    }
    
    /// Handle app becoming active
    private func handleAppDidBecomeActive() {
        Task {
            await dynamicReminderService.handleAppDidBecomeActive()
            await MainActor.run {
                updateHomeScreenQuickActions()
            }
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

    @MainActor
    private func updateHomeScreenQuickActions() {
        let notificationsEnabled = settingsManager.loadSettings().notificationsEnabled
        let toggleTitle = notificationsEnabled
            ? String.localized(.muteNotifications)
            : String.localized(.unmuteNotifications)
        let toggleIconName = notificationsEnabled ? "bell.slash" : "bell"

        UIApplication.shared.shortcutItems = [
            UIApplicationShortcutItem(
                type: QuickActionType.createEvent.rawValue,
                localizedTitle: String.localized(.createEvent),
                localizedSubtitle: nil,
                icon: UIApplicationShortcutIcon(systemImageName: "plus.circle"),
                userInfo: nil
            ),
            UIApplicationShortcutItem(
                type: QuickActionType.toggleNotifications.rawValue,
                localizedTitle: toggleTitle,
                localizedSubtitle: nil,
                icon: UIApplicationShortcutIcon(systemImageName: toggleIconName),
                userInfo: nil
            )
        ]
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

// MARK: - Quick Actions - AppDelegate

/// Minimal app delegate for cold-launch quick action handling
class AppDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        let configuration = UISceneConfiguration(name: nil, sessionRole: connectingSceneSession.role)
        configuration.delegateClass = SceneDelegate.self
        return configuration
    }

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil) -> Bool {
        return true
    }
    
    func application(_ application: UIApplication, performActionFor shortcutItem: UIApplicationShortcutItem, completionHandler: @escaping (Bool) -> Void) {
        if let type = QuickActionType(rawValue: shortcutItem.type) {
            Task { @MainActor in
                QuickActionHandler.shared.handle(type)
                completionHandler(true)
            }
        } else {
            completionHandler(false)
        }
    }

    /// Handles home-screen quick actions in scene-based lifecycle.
    final class SceneDelegate: UIResponder, UIWindowSceneDelegate {
        func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
            if let shortcutItem = connectionOptions.shortcutItem {
                handle(shortcutItem)
            }
        }

        func windowScene(_ windowScene: UIWindowScene, performActionFor shortcutItem: UIApplicationShortcutItem, completionHandler: @escaping (Bool) -> Void) {
            completionHandler(handle(shortcutItem))
        }

        @discardableResult
        private func handle(_ shortcutItem: UIApplicationShortcutItem) -> Bool {
            guard let type = QuickActionType(rawValue: shortcutItem.type) else { return false }
            Task { @MainActor in
                QuickActionHandler.shared.handle(type)
            }
            return true
        }
    }
}

// MARK: - AppIntents (iOS 17+ Home Screen Quick Actions)

/// Provides home screen icon menu items via the App Intents framework
public struct LucaQuickActions: AppShortcutsProvider {
    public static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: CreateEventIntent(),
            phrases: ["Create event in \(.applicationName)"],
            shortTitle: LocalizedStringResource("Create Event", comment: "Home screen quick action"),
            systemImageName: "plus.circle"
        )
        AppShortcut(
            intent: MuteNotificationsIntent(),
            phrases: ["Mute notifications in \(.applicationName)"],
            shortTitle: LocalizedStringResource("Mute Notifications", comment: "Home screen quick action"),
            systemImageName: "bell.slash"
        )
        AppShortcut(
            intent: UnmuteNotificationsIntent(),
            phrases: ["Unmute notifications in \(.applicationName)"],
            shortTitle: LocalizedStringResource("Unmute Notifications", comment: "Home screen quick action"),
            systemImageName: "bell"
        )
    }
}

/// Opens the event creation form
@objc public final class CreateEventIntent: NSObject, AppIntent {
    public static var title: LocalizedStringResource = "Create Event"
    public static var openAppWhenRun: Bool = true

    @MainActor
    public func perform() async throws -> some IntentResult {
        QuickActionHandler.shared.handle(.createEvent)
        return .result()
    }
}

/// Mutes notifications
@objc public final class MuteNotificationsIntent: NSObject, AppIntent {
    public static var title: LocalizedStringResource = "Mute Notifications"
    public static var openAppWhenRun: Bool = true

    @MainActor
    public func perform() async throws -> some IntentResult {
        QuickActionHandler.shared.handle(.toggleNotifications)
        return .result()
    }
}

/// Unmutes notifications
@objc public final class UnmuteNotificationsIntent: NSObject, AppIntent {
    public static var title: LocalizedStringResource = "Unmute Notifications"
    public static var openAppWhenRun: Bool = true

    @MainActor
    public func perform() async throws -> some IntentResult {
        QuickActionHandler.shared.handle(.toggleNotifications)
        return .result()
    }
}
