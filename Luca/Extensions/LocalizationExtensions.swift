//
//  LocalizationExtensions.swift
//  Luca
//
//  Created by Kiro on 19/12/25.
//

import SwiftUI

// MARK: - Text Extensions
extension Text {
    /// Create a Text view with localized string
    init(localized key: LocalizedStringKey) {
        self.init(LocalizedStringService.shared.localizedString(for: key))
    }
}

// MARK: - String Extensions
extension String {
    /// Get localized string for a key
    static func localized(_ key: LocalizedStringKey) -> String {
        return LocalizedStringService.shared.localizedString(for: key)
    }
}



// MARK: - View Extensions
extension View {
    /// Set navigation title with localized string
    func navigationTitle(localized key: LocalizedStringKey) -> some View {
        self.navigationTitle(LocalizedStringService.shared.localizedString(for: key))
    }
}

// MARK: - Environment Key for Localization Service
struct LocalizationServiceKey: EnvironmentKey {
    static let defaultValue = LocalizedStringService.shared
}

extension EnvironmentValues {
    var localizationService: LocalizedStringService {
        get { self[LocalizationServiceKey.self] }
        set { self[LocalizationServiceKey.self] = newValue }
    }
}

// MARK: - Localized Label
struct LocalizedLabel: View {
    let titleKey: LocalizedStringKey
    let systemImage: String
    
    init(_ titleKey: LocalizedStringKey, systemImage: String) {
        self.titleKey = titleKey
        self.systemImage = systemImage
    }
    
    var body: some View {
        Label(LocalizedStringService.shared.localizedString(for: titleKey), systemImage: systemImage)
    }
}

// MARK: - Localized Button
struct LocalizedButton: View {
    let titleKey: LocalizedStringKey
    let action: () -> Void
    
    init(_ titleKey: LocalizedStringKey, action: @escaping () -> Void) {
        self.titleKey = titleKey
        self.action = action
    }
    
    var body: some View {
        Button(LocalizedStringService.shared.localizedString(for: titleKey), action: action)
    }
}