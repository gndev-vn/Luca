//
//  SettingsView.swift
//  Luca
//
//  Created by Kiro on 18/12/25.
//

import SwiftUI
import UserNotifications

/// Settings interface for the Luca app
struct SettingsView: View {
    @StateObject private var viewModel: SettingsViewModel
    @AppStorage("developer_mode_enabled") private var developerModeEnabled = false
    @State private var showResetConfirmation = false
    @State private var notificationsEnabled = false
    @State private var hasPermission = false
    @Environment(\.themeManager) private var themeManager
    
    init(settingsManager: SettingsManager,
         notificationManager: NotificationManager,
         dataManager: DataManager,
         reseedHolidays: (() async throws -> Void)? = nil) {
        self._viewModel = StateObject(wrappedValue: SettingsViewModel(
            settingsManager: settingsManager,
            notificationManager: notificationManager,
            dataManager: dataManager,
            reseedHolidays: reseedHolidays
        ))
    }
    
    var body: some View {
        Form {
            // Notifications Section
            Section {
                Toggle(isOn: Binding(
                    get: { notificationsEnabled },
                    set: { newValue in
                        if newValue {
                            Task { await enableNotifications() }
                        } else {
                            updateNotificationSetting(false)
                        }
                    }
                )) {
                    HStack {
                        Image(systemName: "bell.fill")
                            .foregroundColor(.orange)
                        Text(localized: .enableNotifications)
                    }
                }
                
                if notificationsEnabled {
                    Toggle(String.localized(.culturalNotifications), isOn: Binding(
                        get: { viewModel.userSettings.culturalNotificationsEnabled },
                        set: { newValue in
                            var settings = viewModel.settingsManager.loadSettings()
                            settings.culturalNotificationsEnabled = newValue
                            viewModel.settingsManager.saveSettings(settings)
                            viewModel.userSettings.culturalNotificationsEnabled = newValue
                            Task { await viewModel.setCategoryReminders(category: .cultural, enabled: newValue) }
                        }
                    ))
                    
                    Toggle(String.localized(.religiousNotifications), isOn: Binding(
                        get: { viewModel.userSettings.religiousNotificationsEnabled },
                        set: { newValue in
                            var settings = viewModel.settingsManager.loadSettings()
                            settings.religiousNotificationsEnabled = newValue
                            viewModel.settingsManager.saveSettings(settings)
                            viewModel.userSettings.religiousNotificationsEnabled = newValue
                            Task { await viewModel.setCategoryReminders(category: .religious, enabled: newValue) }
                        }
                    ))
                }
            } footer: {
                Text(String.localized(.enableNotificationsDescription))
                    .foregroundColor(.secondary)
            }
            
            // Theme Section
            Section {
                Picker(selection: Binding(
                    get: { viewModel.userSettings.preferredTheme },
                    set: { newTheme in
                        var settings = viewModel.settingsManager.loadSettings()
                        settings.preferredTheme = newTheme
                        viewModel.settingsManager.saveSettings(settings)
                        viewModel.userSettings.preferredTheme = newTheme
                        themeManager?.setTheme(newTheme)
                    }
                )) {
                    ForEach(UserSettings.Theme.allCases, id: \.self) { theme in
                        HStack {
                            Image(systemName: theme.iconName)
                                .foregroundColor(theme.color)
                            Text(theme.localizedDisplayName)
                        }
                        .tag(theme)
                    }
                } label: {
                    HStack {
                        Image(systemName: "paintbrush")
                            .foregroundColor(.accentColor)
                        Text(localized: .themeSettings)
                    }
                }
            } footer: {
                Text(String.localized(.themeDescription))
                    .foregroundColor(.secondary)
            }
            
            // About
            Section {
                NavigationLink(value: SettingsDestination.about) {
                    Label(String.localized(.about), systemImage: "info.circle")
                }
            }
            
            // Additional Options Section
            Section {
                if developerModeEnabled {
                    NavigationLink(value: SettingsDestination.developer) {
                        Label(String.localized(.developerOptions), systemImage: "wrench")
                    }
                }
                Button(String.localized(.resetToDefaults), systemImage: "arrow.counterclockwise") {
                    showResetConfirmation = true
                }
                .foregroundColor(.red)
            } header: {
                Text(localized: .advanced)
            } footer: {
                Text(String.localized(.resetSettingsDescription))
                    .foregroundColor(.secondary)
            }
            .confirmationDialog(
                String.localized(.resetAllSettingsTitle),
                isPresented: $showResetConfirmation,
                titleVisibility: .visible
            ) {
                Button(String.localized(.resetToDefaults), role: .destructive) {
                    let impactFeedback = UIImpactFeedbackGenerator(style: .heavy)
                    impactFeedback.impactOccurred()

                    viewModel.resetToDefaults()
                }
                Button(String.localized(.cancel), role: .cancel) {}
            } message: {
                Text(String.localized(.resetAllSettingsWarning))
            }
        }
        .navigationTitle(localized: .settings)
        .navigationBarTitleDisplayMode(.large)
        .onAppear {
            viewModel.loadSettings()
            loadNotificationData()
        }
    }
    
    private func loadNotificationData() {
        Task {
            let settings = await UNUserNotificationCenter.current().notificationSettings()
            hasPermission = settings.authorizationStatus == .authorized
            let userSettings = viewModel.settingsManager.loadSettings()
            notificationsEnabled = userSettings.notificationsEnabled && hasPermission
        }
    }
    
    private func enableNotifications() async {
        let center = UNUserNotificationCenter.current()
        do {
            let granted = try await center.requestAuthorization(options: [.alert, .sound, .badge])
            await MainActor.run {
                hasPermission = granted
                if granted {
                    updateNotificationSetting(true)
                } else {
                    notificationsEnabled = false
                }
            }
        } catch {
            await MainActor.run { notificationsEnabled = false }
        }
    }
    
    private func updateNotificationSetting(_ enabled: Bool) {
        var settings = viewModel.settingsManager.loadSettings()
        settings.notificationsEnabled = enabled
        viewModel.settingsManager.saveSettings(settings)
        notificationsEnabled = enabled && hasPermission
    }
}

// MARK: - Preview

#Preview {
    SettingsView(
        settingsManager: UserDefaultsSettingsManager(),
        notificationManager: DefaultNotificationManager(),
        dataManager: MockDataManager()
    )
}
