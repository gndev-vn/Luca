//
//  OnboardingView.swift
//  Luca
//
//  Created by Kiro on 19/12/25.
//

import SwiftUI
import Combine

/// Onboarding flow for first-time users
struct OnboardingView: View {
    @StateObject private var onboardingManager = OnboardingManager()
    @Environment(\.dismiss) private var dismiss
    
    let settingsManager: SettingsManager
    let notificationManager: NotificationManager
    let onComplete: () -> Void
    
    var body: some View {
        TabView(selection: $onboardingManager.currentStep) {
            // Welcome Step
            WelcomeStepView(
                onGetStarted: {
                    onboardingManager.nextStep()
                }
            )
                .tag(OnboardingStep.welcome)
            
            // Features Step
            FeaturesStepView(
                onNext: {
                    onboardingManager.nextStep()
                }
            )
            .tag(OnboardingStep.features)
            
            // Permissions Step
            PermissionsStepView(
                notificationManager: notificationManager,
                settingsManager: settingsManager,
                onNext: {
                    onboardingManager.nextStep()
                }
            )
            .tag(OnboardingStep.permissions)
            
            // Completion Step
            CompletionStepView(
                onComplete: {
                    completeOnboarding()
                }
            )
            .tag(OnboardingStep.completion)
        }
        .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
        .safeAreaInset(edge: .bottom) {
            HStack {
                Spacer()

                HStack(spacing: 8) {
                    ForEach(OnboardingStep.allCases, id: \.self) { step in
                        Circle()
                            .fill(step == onboardingManager.currentStep ? Color.accentColor : Color.secondary.opacity(0.3))
                            .frame(width: 8, height: 8)
                    }
                }

                Spacer()
            }
            .padding(.horizontal)
            .padding(.top, 8)
            .padding(.bottom, 8)
        }
        .interactiveDismissDisabled()
    }
    
    private func completeOnboarding() {
        // Save onboarding completion
        var settings = settingsManager.loadSettings()
        settings.hasCompletedOnboarding = true
        settingsManager.saveSettings(settings)
        
        // Complete onboarding
        onComplete()
    }
}

// MARK: - Onboarding Steps

enum OnboardingStep: Int, CaseIterable {
    case welcome = 0
    case permissions = 2
    case features = 1
    case completion = 3
}

// MARK: - Onboarding Manager

@MainActor
class OnboardingManager: ObservableObject {
    @Published var currentStep: OnboardingStep = .welcome
    
    func nextStep() {
        let nextIndex = currentStep.rawValue + 1
        if nextIndex < OnboardingStep.allCases.count {
            withAnimation(.easeInOut(duration: 0.3)) {
                currentStep = OnboardingStep(rawValue: nextIndex) ?? .completion
            }
        }
    }
    
    func previousStep() {
        let previousIndex = currentStep.rawValue - 1
        if previousIndex >= 0 {
            withAnimation(.easeInOut(duration: 0.3)) {
                currentStep = OnboardingStep(rawValue: previousIndex) ?? .welcome
            }
        }
    }
}

// MARK: - Welcome Step

struct WelcomeStepView: View {
    let onGetStarted: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(spacing: 24) {
                    // App Icon and Title
                    VStack(spacing: 24) {
                        RoundedRectangle(cornerRadius: 24)
                            .fill(
                                LinearGradient(
                                    colors: [.red, .orange],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 100, height: 100)
                            .overlay(
                                Text("🌙")
                                    .font(.system(size: 50))
                            )
                            .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 5)
                        
                        VStack(spacing: 8) {
                            Text(localized: .welcomeToLuca)
                                .font(.largeTitle)
                                .fontWeight(.bold)
                                .multilineTextAlignment(.center)
                        }
                    }
                    
                    // Description
                    VStack(spacing: 16) {
                        Text(localized: .onboardingWelcomeDescription)
                            .font(.body)
                            .multilineTextAlignment(.center)
                            .lineSpacing(2)
                            .foregroundColor(.secondary)
                    }
                }
                .frame(maxWidth: .infinity)
                .padding()
            }
            .scrollIndicators(.hidden)
            
            Button(action: onGetStarted) {
                Text(localized: .getStarted)
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.accentColor)
                    .cornerRadius(12)
            }
            .padding(.horizontal)
            .padding(.vertical, 8)
        }
    }
}

// MARK: - Permissions Step

struct PermissionsStepView: View {
    let notificationManager: NotificationManager
    let settingsManager: SettingsManager
    let onNext: () -> Void
    
    @State private var notificationPermissionGranted = false
    @State private var isRequestingPermission = false
    
    var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(spacing: 24) {
                    // Header
                    VStack(spacing: 16) {
                        Image(systemName: "bell.circle.fill")
                            .font(.system(size: 60))
                            .foregroundColor(.orange)
                        
                        Text(localized: .enableNotifications)
                            .font(.largeTitle)
                            .fontWeight(.bold)
                            .multilineTextAlignment(.center)
                        
                        Text(localized: .notificationsDescription)
                            .font(.body)
                            .multilineTextAlignment(.center)
                            .foregroundColor(.secondary)
                    }
                    
                    // Permission Benefits
                    VStack(spacing: 16) {
                        PermissionBenefit(
                            icon: "calendar.badge.clock",
                            title: String.localized(.eventReminders),
                            description: String.localized(.eventRemindersDescription)
                        )
                        
                        PermissionBenefit(
                            icon: "star.circle",
                            title: String.localized(.holidayAlerts),
                            description: String.localized(.holidayAlertsDescription)
                        )
                        
                        PermissionBenefit(
                            icon: "person.circle",
                            title: String.localized(.onboardingPersonalEventReminders),
                            description: String.localized(.onboardingPersonalEventRemindersDesc)
                        )
                    }
                }
                .frame(maxWidth: .infinity)
                .padding()
            }
            .scrollIndicators(.hidden)
            
            VStack(spacing: 12) {
                Button(action: {
                    requestNotificationPermission()
                }) {
                    HStack {
                        if isRequestingPermission {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                .scaleEffect(0.8)
                        } else {
                            Image(systemName: notificationPermissionGranted ? "checkmark" : "bell")
                        }
                        
                        Text(notificationPermissionGranted ? String.localized(.notificationsEnabled) : String.localized(.enableNotifications))
                    }
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(notificationPermissionGranted ? Color.green : Color.orange)
                    .cornerRadius(12)
                }
                .disabled(isRequestingPermission || notificationPermissionGranted)
                
                Button(action: onNext) {
                    Text(notificationPermissionGranted ? String.localized(.continueAction) : String.localized(.skipForNow))
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 8)
        }
        .task {
            await checkNotificationPermission()
        }
    }
    
    private func checkNotificationPermission() async {
        notificationPermissionGranted = await notificationManager.hasPermissions()
    }
    
    private func requestNotificationPermission() {
        isRequestingPermission = true
        
        Task {
            let granted = await notificationManager.requestPermissions()
            
            await MainActor.run {
                notificationPermissionGranted = granted
                isRequestingPermission = false
                
                if granted {
                    var settings = settingsManager.loadSettings()
                    settings.notificationsEnabled = true
                    settingsManager.saveSettings(settings)
                    
                    let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
                    impactFeedback.impactOccurred()
                }
            }
        }
    }
}

// MARK: - Features Step

struct FeaturesStepView: View {
    let onNext: () -> Void
    
    var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(spacing: 24) {
                    // Header
                    VStack(spacing: 16) {
                        Text(localized: .featuresTitle)
                            .font(.largeTitle)
                            .fontWeight(.bold)
                            .multilineTextAlignment(.center)
                        
                        Text(localized: .featuresDescription)
                            .font(.body)
                            .multilineTextAlignment(.center)
                            .foregroundColor(.secondary)
                    }
                    
                    VStack(spacing: 20) {
                        OnboardingFeatureCard(
                            icon: "calendar.circle.fill",
                            title: String.localized(.unifiedCalendar),
                            description: String.localized(.unifiedCalendarDesc),
                            color: .blue
                        )
                        
                        OnboardingFeatureCard(
                            icon: "star.circle.fill",
                            title: String.localized(.onboardingHolidaysEvents),
                            description: String.localized(.onboardingHolidaysEventsDesc),
                            color: .red
                        )
                        
                        OnboardingFeatureCard(
                            icon: "plus.circle.fill",
                            title: String.localized(.customEvents),
                            description: String.localized(.customEventsDesc),
                            color: .green
                        )
                        
                        OnboardingFeatureCard(
                            icon: "bell.circle.fill",
                            title: String.localized(.onboardingNotifications),
                            description: String.localized(.onboardingNotificationsDesc),
                            color: .orange
                        )
                    }
                }
                .frame(maxWidth: .infinity)
                .padding()
            }
            .scrollIndicators(.hidden)
            
            Button(action: onNext) {
                Text(localized: .continueAction)
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.accentColor)
                    .cornerRadius(12)
            }
            .padding(.horizontal)
            .padding(.vertical, 8)
        }
    }
}

// MARK: - Completion Step

struct CompletionStepView: View {
    let onComplete: () -> Void
    
    var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(spacing: 24) {
                    // Success Animation
                    VStack(spacing: 24) {
                        ZStack {
                            Circle()
                                .fill(Color.green.opacity(0.1))
                                .frame(width: 120, height: 120)
                            
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 60))
                                .foregroundColor(.green)
                        }
                        
                        VStack(spacing: 8) {
                            Text(localized: .youreAllSet)
                                .font(.largeTitle)
                                .fontWeight(.bold)
                                .multilineTextAlignment(.center)
                        }
                    }
                }
                .frame(maxWidth: .infinity)
                .padding()
            }
            .scrollIndicators(.hidden)
            
            Button(action: onComplete) {
                Text(localized: .startUsingLuca)
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.accentColor)
                    .cornerRadius(12)
            }
            .padding(.horizontal)
            .padding(.vertical, 8)
        }
    }
}

// MARK: - Supporting Views

struct PermissionBenefit: View {
    let icon: String
    let title: String
    let description: String
    
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .foregroundColor(.orange)
                .font(.title2)
                .frame(width: 32)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                
                Text(description)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
        }
    }
}

struct OnboardingFeatureCard: View {
    let icon: String
    let title: String
    let description: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .foregroundColor(color)
                .font(.largeTitle)
                .frame(width: 48)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Text(description)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .lineLimit(3)
            }
            
            Spacer()
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

#Preview {
    OnboardingView(
        settingsManager: UserDefaultsSettingsManager(),
        notificationManager: DefaultNotificationManager(),
        onComplete: { }
    )
}
