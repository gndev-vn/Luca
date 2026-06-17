//
//  AboutView.swift
//  Luca
//
//  Created by Kiro on 19/12/25.
//

import SwiftUI

/// About view with app information and credits
struct AboutView: View {
    @Environment(\.dismiss) private var dismiss
    @AppStorage("developer_mode_enabled") private var developerModeEnabled = false
    @State private var versionTapCount = 0
    @State private var showDeveloperToast = false
    
    private let appVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
    private let buildNumber = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // App Header
                VStack(spacing: 12) {
                    RoundedRectangle(cornerRadius: 20)
                        .fill(
                            LinearGradient(
                                colors: [.red, .orange],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 72, height: 72)
                        .overlay(
                            Text("🌙")
                                .font(.system(size: 36))
                        )
                    
                    VStack(spacing: 2) {
                        Text("Luca")
                            .font(.title.bold())
                        
                        Text(localized: .lunarCalendarApp)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        
                        Text(String(format: String.localized(.versionFormat), appVersion, buildNumber))
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .onTapGesture {
                                versionTapCount += 1
                                if versionTapCount >= 5 {
                                    developerModeEnabled = true
                                    versionTapCount = 0
                                    withAnimation {
                                        showDeveloperToast = true
                                    }
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                                        withAnimation {
                                            showDeveloperToast = false
                                        }
                                    }
                                }
                            }
                    }
                }
                
                // Description
                VStack(alignment: .leading, spacing: 12) {
                    Text(localized: .aboutLuca)
                        .font(.headline.weight(.bold))
                    
                    Text(localized: .aboutDescription)
                        .font(.body)
                        .foregroundColor(.secondary)
                        .lineSpacing(2)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(12)
                
                // Features
                VStack(alignment: .leading, spacing: 12) {
                    Text(localized: .featuresTitle)
                        .font(.headline.weight(.bold))
                    
                    VStack(spacing: 0) {
                        FeatureRow(
                            icon: "calendar.circle.fill",
                            title: String.localized(.unifiedCalendar),
                            description: String.localized(.unifiedCalendarDesc),
                            color: .blue
                        )
                        Divider().padding(.leading, 36)
                        FeatureRow(
                            icon: "star.circle.fill",
                            title: String.localized(.culturalHolidays),
                            description: String.localized(.culturalHolidaysDesc),
                            color: .red
                        )
                        Divider().padding(.leading, 36)
                        FeatureRow(
                            icon: "plus.circle.fill",
                            title: String.localized(.customEvents),
                            description: String.localized(.customEventsDesc),
                            color: .green
                        )
                        Divider().padding(.leading, 36)
                        FeatureRow(
                            icon: "bell.circle.fill",
                            title: String.localized(.smartReminders),
                            description: String.localized(.smartRemindersDesc),
                            color: .orange
                        )
                    }
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(12)
                
                // Credits
                VStack(alignment: .leading, spacing: 12) {
                    Text(localized: .creditsTitle)
                        .font(.headline.weight(.bold))
                    
                    VStack(alignment: .leading, spacing: 6) {
                        Text(localized: .creditCalcAlgo)
                        Text(localized: .creditHolidayData)
                        Text(localized: .creditCommunity)
                        Text(localized: .creditSwiftUI)
                    }
                    .font(.caption)
                    .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(12)
                
                // Legal
                VStack(alignment: .leading, spacing: 12) {
                    Text(localized: .legalTitle)
                        .font(.headline.weight(.bold))
                    
                    VStack(spacing: 0) {
                        LegalRow(title: String.localized(.privacyPolicy), description: String.localized(.privacyPolicyDesc))
                        Divider().padding(.leading, 36)
                        LegalRow(title: String.localized(.openSource), description: String.localized(.openSourceDesc))
                    }
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(12)
                
                // Contact
                VStack(alignment: .leading, spacing: 12) {
                    Text(localized: .contactSupport)
                        .font(.headline.weight(.bold))
                    
                    VStack(spacing: 0) {
                        ContactRow(
                            icon: "envelope.fill",
                            title: String.localized(.emailSupport),
                            subtitle: String.localized(.emailSupportDesc),
                            color: .blue
                        )
                        Divider().padding(.leading, 36)
                        ContactRow(
                            icon: "star.fill",
                            title: String.localized(.rateAppStore),
                            subtitle: String.localized(.rateAppStoreDesc),
                            color: .orange
                        )
                    }
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(12)
                
                // Copyright
                Text(localized: .copyright)
                    .font(.caption2)
                    .foregroundColor(.secondary)
                    .padding(.top)
            }
            .padding()
        }
        .navigationTitle(localized: .about)
        .navigationBarTitleDisplayMode(.large)
        .overlay(alignment: .bottom) {
            if showDeveloperToast {
                Text(String.localized(.developerModeEnabled))
                    .font(.subheadline.weight(.semibold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 12)
                    .background(Color.orange)
                    .cornerRadius(10)
                    .padding(.bottom, 30)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
    }
}

/// Feature row for the features section
struct FeatureRow: View {
    let icon: String
    let title: String
    let description: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(color)
                .font(.title2)
                .frame(width: 24)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Text(description)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
        }
        .padding(.vertical, 8)
    }
}

/// Legal row for legal section
struct LegalRow: View {
    let title: String
    let description: String
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Text(description)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
        }
        .padding(.vertical, 8)
    }
}

/// Contact row for contact section
struct ContactRow: View {
    let icon: String
    let title: String
    let subtitle: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(color)
                .font(.title3)
                .frame(width: 24)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Text(subtitle)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
        }
        .padding(.vertical, 8)
    }
}

#Preview {
    NavigationView {
        AboutView()
    }
}
