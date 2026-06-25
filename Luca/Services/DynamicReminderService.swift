//
//  DynamicReminderService.swift
//  Luca
//
//  Created by Kiro on 18/12/25.
//

import Foundation
import UserNotifications

/// Service for managing dynamic reminder scheduling that adapts to lunar date shifts
class DynamicReminderService {
    
    // MARK: - Private Properties
    
    /// Notification manager for scheduling reminders
    private let notificationManager: NotificationManager
    
    /// Data manager for accessing events
    private let dataManager: DataManager
    
    /// Settings manager for checking notification preferences
    private let settingsManager: SettingsManager
    
    /// Timer for periodic reminder checks
    private var reminderUpdateTimer: Timer?
    
    /// Date of last reminder update check
    private var lastUpdateCheck: Date {
        get {
            UserDefaults.standard.object(forKey: "last_reminder_update_check") as? Date ?? Date.distantPast
        }
        set {
            UserDefaults.standard.set(newValue, forKey: "last_reminder_update_check")
        }
    }
    
    // MARK: - Initialization
    
    init(
        notificationManager: NotificationManager,
        dataManager: DataManager,
        settingsManager: SettingsManager
    ) {
        self.notificationManager = notificationManager
        self.dataManager = dataManager
        self.settingsManager = settingsManager
    }
    
    deinit {
        stopPeriodicReminderUpdates()
    }
    
    // MARK: - Public Methods
    
    /// Start the dynamic reminder scheduling service
    func startService() {
        startPeriodicReminderUpdates()
    }
    
    /// Stop the dynamic reminder scheduling service
    func stopService() {
        stopPeriodicReminderUpdates()
    }
    
    /// Update reminders for a specific event
    func updateRemindersForEvent(_ event: Event) async {
        await notificationManager.updateReminders(for: event)
    }
    
    /// Check if reminders need updating based on lunar date shifts
    /// - Returns: True if reminders were updated, false otherwise
    @discardableResult
    func checkAndUpdateReminders() async -> Bool {
        let now = Date()
        let timeSinceLastCheck = now.timeIntervalSince(lastUpdateCheck)
        
        guard timeSinceLastCheck > 6 * 3600 else {
            return false
        }
        
        await performReminderUpdate()
        lastUpdateCheck = now
        return true
    }
    
    // MARK: - Private Methods
    
    /// Perform the actual reminder update process
    private func performReminderUpdate() async {
        do {
            let startDate = Date()
            let endDate = Calendar.current.date(byAdding: .month, value: 3, to: startDate) ?? startDate
            let dateRange = DateInterval(start: startDate, end: endDate)
            
            let events = try await dataManager.fetchEvents(for: dateRange)
            let settings = settingsManager.loadSettings()
            let eventsWithReminders = events.filter { event in
                guard !event.reminderSettings.isEmpty else { return false }
                switch event.category {
                case .cultural: return settings.culturalNotificationsEnabled
                case .religious: return settings.religiousNotificationsEnabled
                case .personal: return true
                }
            }
            
            for event in eventsWithReminders {
                await notificationManager.updateReminders(for: event)
            }
        } catch {
            print("Reminder update failed: \(error)")
        }
    }
    
    // MARK: - Periodic Updates
    
    /// Start periodic reminder updates
    private func startPeriodicReminderUpdates() {
        stopPeriodicReminderUpdates()
        
        reminderUpdateTimer = Timer.scheduledTimer(withTimeInterval: 6 * 3600, repeats: true) { [weak self] _ in
            Task {
                await self?.checkAndUpdateReminders()
            }
        }
    }
    
    private func stopPeriodicReminderUpdates() {
        reminderUpdateTimer?.invalidate()
        reminderUpdateTimer = nil
    }
}

// MARK: - Background Task Support

extension DynamicReminderService {
    
    func handleAppDidBecomeActive() async {
        await checkAndUpdateReminders()
    }
    
    func handleSignificantTimeChange() async {
        await performReminderUpdate()
    }
}