//
//  AppLoadingView.swift
//  Luca
//
//  Created by Kiro on 19/12/25.
//

import SwiftUI

/// Loading screen shown during app initialization
struct AppLoadingView: View {
    @ObservedObject var initializationService: AppInitializationService
    
    @State private var animationOffset: CGFloat = 0
    @State private var animationOpacity: Double = 0.5
    
    var body: some View {
        ZStack {
            // Background gradient
            LinearGradient(
                colors: [
                    Color.red.opacity(0.1),
                    Color.orange.opacity(0.1),
                    Color.yellow.opacity(0.1)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            VStack(spacing: 40) {
                Spacer()
                
                // App Logo with Animation
                VStack(spacing: 24) {
                    // App icon
                    Image("AppLogoIcon")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 100, height: 100)
                        .clipShape(RoundedRectangle(cornerRadius: 22))
                        .shadow(color: .black.opacity(0.2), radius: 10, x: 0, y: 5)
                        .offset(y: animationOffset)
                        .animation(
                            .easeInOut(duration: 1.5).repeatForever(autoreverses: true),
                            value: animationOffset
                        )
                    
                    VStack(spacing: 8) {
                        Text("Luca")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                            .foregroundColor(.primary)
                    }
                }
                
                Spacer()
            }
            .padding()
        }
        .onAppear {
            startAnimations()
        }
    }
    
    private func startAnimations() {
        // Start floating animation
        animationOffset = -10
        
        // Start pulsing animation
        animationOpacity = 1.0
    }
}

/// Error view shown if initialization fails
struct AppInitializationErrorView: View {
    let error: Error
    let onRetry: () -> Void
    
    var body: some View {
        VStack(spacing: 32) {
            Spacer()
            
            // Error Icon
            VStack(spacing: 24) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.system(size: 60))
                    .foregroundColor(.red)
                
                VStack(spacing: 8) {
                    Text(String.localized(.initializationFailed))
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .multilineTextAlignment(.center)
                    
                    Text(String.localized(.initializationErrorDescription))
                        .font(.body)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
            }
            
            // Error Details
            VStack(alignment: .leading, spacing: 12) {
                Text(String.localized(.errorDetails))
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Text(error.localizedDescription)
                    .font(.body)
                    .foregroundColor(.secondary)
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(8)
            }
            .padding(.horizontal)
            
            Spacer()
            
            // Retry Button
            VStack(spacing: 12) {
                Button(action: onRetry) {
                    HStack {
                        Image(systemName: "arrow.clockwise")
                        Text(String.localized(.tryAgain))
                    }
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.accentColor)
                    .cornerRadius(12)
                }
                
                Text(String.localized(.restartPrompt))
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            .padding(.horizontal)
            .padding(.bottom, 50)
        }
        .padding()
    }
}

#Preview("Loading") {
    AppLoadingView(initializationService: AppInitializationService(
        settingsManager: UserDefaultsSettingsManager(),
        dataManager: MockDataManager(),
        notificationManager: MockNotificationManager()
    ))
}

#Preview("Error") {
    AppInitializationErrorView(
        error: InitializationError.coreDataInitializationFailed,
        onRetry: { }
    )
}
