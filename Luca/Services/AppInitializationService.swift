//
//  AppInitializationService.swift
//  Luca
//
//  Created by Kiro on 19/12/25.
//

import Foundation
import Combine

/// Service responsible for app initialization and first launch setup
@MainActor
class AppInitializationService: ObservableObject {
    @Published var initializationState: InitializationState = .notStarted
    @Published var initializationProgress: Double = 0.0
    @Published var currentStep: String = ""
    
    private let settingsManager: SettingsManager
    private let dataManager: DataManager
    private let notificationManager: NotificationManager
    private let holidayService: HolidayService
    
    init(settingsManager: SettingsManager, dataManager: DataManager, notificationManager: NotificationManager, holidayService: HolidayService = HolidayService()) {
        self.settingsManager = settingsManager
        self.dataManager = dataManager
        self.notificationManager = notificationManager
        self.holidayService = holidayService
    }
    
    /// Initialize the app on first launch or after updates
    func initializeApp() async {
        initializationState = .inProgress
        currentStep = "Starting initialization..."
        initializationProgress = 0.0
        
        do {
            // Step 1: Validate and migrate settings
            await updateProgress(0.2, step: "Validating settings...")
            try await validateAndMigrateSettings()
            
            // Step 2: Initialize Core Data
            await updateProgress(0.4, step: "Setting up data storage...")
            try await initializeCoreData()
            
            // Step 3: Seed public holidays to Core Data
            await updateProgress(0.6, step: "Loading holiday data...")
            try await seedPublicHolidays()
            
            // Step 4: Setup notification permissions if needed
            await updateProgress(0.8, step: "Configuring notifications...")
            await setupNotifications()
            
            // Step 5: Validate data integrity
            await updateProgress(0.9, step: "Validating data integrity...")
            try await validateDataIntegrity()
            
            // Step 6: Complete initialization
            await updateProgress(1.0, step: "Initialization complete")
            initializationState = .completed
            
        } catch {
            print("App initialization failed: \(error)")
            initializationState = .failed(error)
        }
    }
    
    /// Check if this is the first launch
    func isFirstLaunch() -> Bool {
        let settings = settingsManager.loadSettings()
        return settings.firstLaunch
    }
    
    /// Check if onboarding has been completed
    func hasCompletedOnboarding() -> Bool {
        let settings = settingsManager.loadSettings()
        return settings.hasCompletedOnboarding
    }
    
    /// Seed public holidays to Core Data for faster access
    private func seedPublicHolidays() async throws {
        var settings = settingsManager.loadSettings()
        guard !settings.hasSeededPublicHolidays else { return }

        let currentYear = Calendar.current.component(.year, from: Date())
        let iosYear = currentYear - 1983
        let fromYear = iosYear - 3
        let toYear = iosYear + 7

        try await holidayService.seedPublicHolidays(to: dataManager, from: fromYear, to: toYear)

        settings.hasSeededPublicHolidays = true
        settingsManager.saveSettings(settings)
    }
    
    /// Mark first launch as completed
    func markFirstLaunchCompleted() {
        var settings = settingsManager.loadSettings()
        settings.firstLaunch = false
        settingsManager.saveSettings(settings)
    }
    
    // MARK: - Private Methods
    
    private func updateProgress(_ progress: Double, step: String) async {
        initializationProgress = progress
        currentStep = step
        
        // Small delay to make progress visible
        try? await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds
    }
    
    private func validateAndMigrateSettings() async throws {
        var settings = settingsManager.loadSettings()
        var needsUpdate = false
        
        // Validate theme setting
        if !UserSettings.Theme.allCases.contains(settings.preferredTheme) {
            settings.preferredTheme = .system
            needsUpdate = true
        }
        
        // Save updated settings if needed
        if needsUpdate {
            settingsManager.saveSettings(settings)
        }
    }
    
    private func initializeCoreData() async throws {
        // Verify Core Data stack is working
        let eventCount = await dataManager.getEventCount()
        print("Core Data initialized with \(eventCount) existing events")
        
        // Perform any necessary data migrations here
        // This is where you would handle schema migrations between app versions
    }
    
    private func setupNotifications() async {
        let settings = settingsManager.loadSettings()
        
        if settings.notificationsEnabled {
            // Check if we already have permissions
            let hasPermissions = await notificationManager.hasPermissions()
            
            if !hasPermissions {
                // Don't request permissions during initialization
                // This will be handled during onboarding or when user enables notifications
                print("Notification permissions not granted - will request during onboarding")
            } else {
                print("Notification permissions already granted")
            }
        }
    }
    
    private func validateDataIntegrity() async throws {
        // Check for any corrupted events and clean them up
        do {
            let allEvents = try await dataManager.fetchAllEvents()
            var corruptedEvents: [Event] = []
            
            for event in allEvents {
                // Validate event data
                if event.title.isEmpty {
                    corruptedEvents.append(event)
                    continue
                }
                
                // Validate lunar date
                if !event.lunarDate.isValid() {
                    corruptedEvents.append(event)
                    continue
                }
                
                // Validate Gregorian date is reasonable
                let currentDate = Date()
                let tenYearsAgo = Calendar.current.date(byAdding: .year, value: -10, to: currentDate) ?? currentDate
                let fiftyYearsFromNow = Calendar.current.date(byAdding: .year, value: 50, to: currentDate) ?? currentDate
                
                if event.gregorianDate < tenYearsAgo || event.gregorianDate > fiftyYearsFromNow {
                    corruptedEvents.append(event)
                }
            }
            
            // Remove corrupted events
            for corruptedEvent in corruptedEvents {
                try await dataManager.deleteEvent(corruptedEvent)
                print("Removed corrupted event: \(corruptedEvent.title)")
            }
            
            if !corruptedEvents.isEmpty {
                print("Cleaned up \(corruptedEvents.count) corrupted events")
            }
            
        } catch {
            print("Warning: Could not validate data integrity: \(error)")
            // Don't throw here - data validation failure shouldn't prevent app startup
        }
    }
}

// MARK: - Supporting Types

enum InitializationState: Equatable {
    case notStarted
    case inProgress
    case completed
    case failed(Error)
    
    static func == (lhs: InitializationState, rhs: InitializationState) -> Bool {
        switch (lhs, rhs) {
        case (.notStarted, .notStarted),
             (.inProgress, .inProgress),
             (.completed, .completed):
            return true
        case (.failed, .failed):
            return true // Simplified equality for errors
        default:
            return false
        }
    }
}

enum InitializationError: LocalizedError {
    case holidayDataLoadFailed
    case coreDataInitializationFailed
    case settingsMigrationFailed
    
    var errorDescription: String? {
        switch self {
        case .holidayDataLoadFailed:
            return "Failed to load Vietnamese holiday data"
        case .coreDataInitializationFailed:
            return "Failed to initialize data storage"
        case .settingsMigrationFailed:
            return "Failed to migrate app settings"
        }
    }
}
