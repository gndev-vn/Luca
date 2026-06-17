//
//  AccessibilityManager.swift
//  Luca
//
//  Created by Kiro on 18/12/25.
//

import SwiftUI
import UIKit
import Combine

/// Manager for handling accessibility features and compliance
@MainActor
final class AccessibilityManager: ObservableObject {
    @Published var isVoiceOverEnabled: Bool = false
    @Published var isDynamicTypeEnabled: Bool = false
    @Published var preferredContentSizeCategory: ContentSizeCategory = .medium
    @Published var isReduceMotionEnabled: Bool = false
    @Published var isHighContrastEnabled: Bool = false
    
    init() {
        updateAccessibilitySettings()
        setupAccessibilityObservers()
    }
    
    /// Update accessibility settings from system
    private func updateAccessibilitySettings() {
        isVoiceOverEnabled = UIAccessibility.isVoiceOverRunning
        isDynamicTypeEnabled = UIApplication.shared.preferredContentSizeCategory.isAccessibilityCategory
        preferredContentSizeCategory = ContentSizeCategory(UIApplication.shared.preferredContentSizeCategory)
        isReduceMotionEnabled = UIAccessibility.isReduceMotionEnabled
        isHighContrastEnabled = UIAccessibility.isDarkerSystemColorsEnabled
    }
    
    /// Set up observers for accessibility changes
    private func setupAccessibilityObservers() {
        NotificationCenter.default.addObserver(self, selector: #selector(handleVoiceOverChanged(_:)), name: UIAccessibility.voiceOverStatusDidChangeNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(handleContentSizeCategoryChanged(_:)), name: UIContentSizeCategory.didChangeNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(handleReduceMotionChanged(_:)), name: UIAccessibility.reduceMotionStatusDidChangeNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(handleDarkerSystemColorsChanged(_:)), name: UIAccessibility.darkerSystemColorsStatusDidChangeNotification, object: nil)
    }
    
    @objc private func handleVoiceOverChanged(_ notification: Notification) {
        updateAccessibilitySettings()
    }
    
    @objc private func handleContentSizeCategoryChanged(_ notification: Notification) {
        updateAccessibilitySettings()
    }
    
    @objc private func handleReduceMotionChanged(_ notification: Notification) {
        updateAccessibilitySettings()
    }
    
    @objc private func handleDarkerSystemColorsChanged(_ notification: Notification) {
        updateAccessibilitySettings()
    }
    
    /// Get accessibility-aware animation duration
    var animationDuration: Double {
        return isReduceMotionEnabled ? 0.0 : 0.3
    }
    
    /// Get accessibility-aware scale effect
    var scaleEffect: Double {
        return isReduceMotionEnabled ? 1.0 : 0.95
    }
    
    /// Get font size multiplier for dynamic type
    var fontSizeMultiplier: CGFloat {
        switch preferredContentSizeCategory {
        case .extraSmall: return 0.8
        case .small: return 0.9
        case .medium: return 1.0
        case .large: return 1.1
        case .extraLarge: return 1.2
        case .extraExtraLarge: return 1.3
        case .extraExtraExtraLarge: return 1.4
        case .accessibilityMedium: return 1.6
        case .accessibilityLarge: return 1.8
        case .accessibilityExtraLarge: return 2.0
        case .accessibilityExtraExtraLarge: return 2.2
        case .accessibilityExtraExtraExtraLarge: return 2.4
        default: return 1.0
        }
    }
    
    /// Get contrast-aware colors
    func contrastAwareColor(_ baseColor: Color, isDarkMode: Bool) -> Color {
        if isHighContrastEnabled {
            return isDarkMode ? Color.white : Color.black
        }
        return baseColor
    }
    
    /// Create accessibility label for lunar date
    func lunarDateAccessibilityLabel(_ lunarDate: LunarDate) -> String {
        let monthNames = [
            "First month", "Second month", "Third month", "Fourth month",
            "Fifth month", "Sixth month", "Seventh month", "Eighth month",
            "Ninth month", "Tenth month", "Eleventh month", "Twelfth month"
        ]
        
        let monthName = monthNames[safe: lunarDate.month - 1] ?? "Month \(lunarDate.month)"
        let leapText = lunarDate.isLeapMonth ? "leap " : ""
        
        return "Lunar date: \(leapText)\(monthName), day \(lunarDate.day), year \(lunarDate.traditionalYear)"
    }
    
    /// Create accessibility label for event
    func eventAccessibilityLabel(_ event: Event) -> String {
        let typeText = event.isPublicHoliday ? "Holiday" : "Event"
        let dateText = lunarDateAccessibilityLabel(event.lunarDate)
        let reminderText = event.reminderSettings.isEmpty ? "" : ", has \(event.reminderSettings.count) reminder\(event.reminderSettings.count == 1 ? "" : "s")"
        
        return "\(typeText): \(event.title). \(dateText)\(reminderText)"
    }
    
}

/// Environment key for accessibility manager
struct AccessibilityManagerKey: EnvironmentKey {
    static let defaultValue: AccessibilityManager? = nil
}

extension EnvironmentValues {
    var accessibilityManager: AccessibilityManager? {
        get { self[AccessibilityManagerKey.self] }
        set { self[AccessibilityManagerKey.self] = newValue }
    }
}

/// Content size category extension
extension ContentSizeCategory {
    init(_ uiContentSizeCategory: UIContentSizeCategory) {
        switch uiContentSizeCategory {
        case .extraSmall: self = .extraSmall
        case .small: self = .small
        case .medium: self = .medium
        case .large: self = .large
        case .extraLarge: self = .extraLarge
        case .extraExtraLarge: self = .extraExtraLarge
        case .extraExtraExtraLarge: self = .extraExtraExtraLarge
        case .accessibilityMedium: self = .accessibilityMedium
        case .accessibilityLarge: self = .accessibilityLarge
        case .accessibilityExtraLarge: self = .accessibilityExtraLarge
        case .accessibilityExtraExtraLarge: self = .accessibilityExtraExtraLarge
        case .accessibilityExtraExtraExtraLarge: self = .accessibilityExtraExtraExtraLarge
        default: self = .medium
        }
    }
}
