//
//  ThemeManager.swift
//  Luca
//
//  Created by Kiro on 18/12/25.
//

import SwiftUI
import UIKit
import Combine

/// Manager for handling app theme changes and accessibility
@MainActor
final class ThemeManager: ObservableObject {
    @Published var currentTheme: UserSettings.Theme = .system
    @Published var isDarkMode: Bool = false
    @Published var preferredColorScheme: ColorScheme?
    
    private let settingsManager: SettingsManager
    
    init(settingsManager: SettingsManager) {
        self.settingsManager = settingsManager
        loadCurrentTheme()
        setupSystemThemeObserver()
    }
    
    /// Load current theme from settings
    private func loadCurrentTheme() {
        let settings = settingsManager.loadSettings()
        currentTheme = settings.preferredTheme
        updateAppearance()
    }
    
    /// Set up observer for system theme changes
    private func setupSystemThemeObserver() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleDidBecomeActiveNotification(_:)),
            name: UIApplication.didBecomeActiveNotification,
            object: nil
        )
    }
    
    @objc private func handleDidBecomeActiveNotification(_ notification: Notification) {
        // We are already on the main actor because ThemeManager is @MainActor
        updateAppearance()
    }
    
    /// Update app appearance based on current theme
    private func updateAppearance() {
        switch currentTheme {
        case .system:
            isDarkMode = UITraitCollection.current.userInterfaceStyle == .dark
            preferredColorScheme = nil
        case .light:
            isDarkMode = false
            preferredColorScheme = .light
        case .dark:
            isDarkMode = true
            preferredColorScheme = .dark
        }
        
        // Apply theme to the app
        applyTheme()
    }
    
    /// Apply theme to the entire app
    private func applyTheme() {
        let style: UIUserInterfaceStyle
        switch currentTheme {
        case .system:
            style = .unspecified
        case .light:
            style = .light
        case .dark:
            style = .dark
        }

        UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .flatMap(\.windows)
            .forEach { window in
                window.overrideUserInterfaceStyle = style
            }
    }
    
    /// Set new theme
    func setTheme(_ theme: UserSettings.Theme) {
        currentTheme = theme
        
        // Save to settings
        var settings = settingsManager.loadSettings()
        settings.preferredTheme = theme
        settingsManager.saveSettings(settings)
        
        // Update appearance
        updateAppearance()
        
        // Haptic feedback for theme change
        let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
        impactFeedback.impactOccurred()
    }
    
    /// Get appropriate colors for current theme
    var themeColors: ThemeColors {
        return ThemeColors(isDarkMode: isDarkMode)
    }
}

/// Theme-aware color definitions
struct ThemeColors {
    let isDarkMode: Bool
    
    // Primary colors
    var primaryBackground: Color {
        isDarkMode ? Color(.systemBackground) : Color(.systemBackground)
    }
    
    var secondaryBackground: Color {
        isDarkMode ? Color(.secondarySystemBackground) : Color(.secondarySystemBackground)
    }
    
    var tertiaryBackground: Color {
        isDarkMode ? Color(.tertiarySystemBackground) : Color(.tertiarySystemBackground)
    }
    
    // Text colors
    var primaryText: Color {
        isDarkMode ? Color(.label) : Color(.label)
    }
    
    var secondaryText: Color {
        isDarkMode ? Color(.secondaryLabel) : Color(.secondaryLabel)
    }
    
    var tertiaryText: Color {
        isDarkMode ? Color(.tertiaryLabel) : Color(.tertiaryLabel)
    }
    
    // Accent colors
    var accent: Color {
        Color.accentColor
    }
    
    var destructive: Color {
        Color.red
    }
    
    // Calendar-specific colors
    var calendarBackground: Color {
        isDarkMode ? Color(.systemGray6) : Color(.systemGray6)
    }
    
    var selectedDateBackground: Color {
        accent
    }
    
    var todayBackground: Color {
        accent.opacity(0.15)
    }
    
    var holidayBackground: Color {
        Color.red.opacity(isDarkMode ? 0.2 : 0.1)
    }
    
    var holidayBorder: Color {
        Color.red.opacity(isDarkMode ? 0.4 : 0.3)
    }
}

/// Environment key for theme manager
struct ThemeManagerKey: EnvironmentKey {
    static let defaultValue: ThemeManager? = nil
}

extension EnvironmentValues {
    var themeManager: ThemeManager? {
        get { self[ThemeManagerKey.self] }
        set { self[ThemeManagerKey.self] = newValue }
    }
}
