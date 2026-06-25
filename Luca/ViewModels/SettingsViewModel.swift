//
//  SettingsViewModel.swift
//  Luca
//
//  Created by Kiro on 16/12/25.
//

import Foundation
import SwiftUI
import Combine

/// ViewModel for managing app settings
@MainActor
class SettingsViewModel: ObservableObject {
    @Published var userSettings = UserSettings.default
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var successMessage: String?
    @Published var isRequestingPermissions = false
    @Published var hasNotificationPermissions = false
    @Published var developerModeEnabled = false
    
    let settingsManager: SettingsManager
    private let notificationManager: NotificationManager
    private let dataManager: DataManager
    private let reseedHolidays: (() async throws -> Void)?
    
    init(settingsManager: SettingsManager,
         notificationManager: NotificationManager,
         dataManager: DataManager,
         reseedHolidays: (() async throws -> Void)? = nil) {
        self.settingsManager = settingsManager
        self.notificationManager = notificationManager
        self.dataManager = dataManager
        self.reseedHolidays = reseedHolidays
        loadSettings()
        
        // Check notification permissions on init
        Task {
            await checkNotificationPermissions()
        }
    }
    
    /// Load user settings
    func loadSettings() {
        isLoading = true
        errorMessage = nil
        
        userSettings = settingsManager.loadSettings()
            
        isLoading = false
    }
    
    /// Save user settings
    func saveSettings() {
        settingsManager.saveSettings(userSettings)
        successMessage = String.localized(.settingsSaved)
        
        // Clear success message after a delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            self.successMessage = nil
        }
    }
    
    /// Check current notification permissions
    func checkNotificationPermissions() async {
        hasNotificationPermissions = await notificationManager.hasPermissions()
        
        // Update settings to match actual permissions
        if !hasNotificationPermissions && userSettings.notificationsEnabled {
            userSettings.notificationsEnabled = false
            saveSettings()
        }
    }

    /// Reset to defaults
    func resetToDefaults() {
        isLoading = true
        errorMessage = nil
        
        settingsManager.resetToDefaults()
        UserDefaults.standard.removeObject(forKey: "developer_mode_enabled")
        developerModeEnabled = false
        loadSettings()
        successMessage = String.localized(.settingsReset)
        
        // Clear success message after a delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            self.successMessage = nil
        }
        
        isLoading = false
    }
    
    /// Set or clear reminders for all events in a category (ignores individual settings)
    func setCategoryReminders(category: EventCategory, enabled: Bool) async {
        do {
            let allEvents = try await dataManager.fetchAllEvents()
            let targetEvents = allEvents.filter { $0.category == category }
            for event in targetEvents {
                if enabled {
                    guard event.reminderSettings.isEmpty else { continue }
                    event.reminderSettings = [.oneDayBefore]
                } else {
                    event.reminderSettings = []
                }
                try await dataManager.updateEvent(event)
                if enabled {
                    await notificationManager.updateReminders(for: event)
                } else {
                    notificationManager.cancelAllReminders(for: event.id)
                }
            }
        } catch {
            print("Failed to update reminders for \(category): \(error)")
        }
    }
    
    // MARK: - Developer Actions
    
    func reseedPublicHolidays() async {
        isLoading = true
        errorMessage = nil
        do {
            try await reseedHolidays?()
            successMessage = String.localized(.holidaysReSeededSuccess)
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                self.successMessage = nil
            }
        } catch {
            errorMessage = "\(String.localized(.failedToReSeed)): \(error.localizedDescription)"
        }
        isLoading = false
    }
}

