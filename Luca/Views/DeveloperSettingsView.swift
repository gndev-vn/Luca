import SwiftUI

struct DeveloperSettingsView: View {
    @StateObject private var viewModel: SettingsViewModel
    @AppStorage("developer_mode_enabled") private var developerModeEnabled = false
    @State private var showReseedConfirmation = false
    @State private var showResetDevConfirmation = false
    @State private var toastMessage = ""
    @State private var showToast = false

    init(settingsManager: SettingsManager,
         notificationManager: NotificationManager,
         reseedHolidays: (() async throws -> Void)? = nil) {
        self._viewModel = StateObject(wrappedValue: SettingsViewModel(
            settingsManager: settingsManager,
            notificationManager: notificationManager,
            reseedHolidays: reseedHolidays
        ))
    }

    var body: some View {
        Form {
            Section {
                Button(String.localized(.reSeedHolidays)) {
                    showReseedConfirmation = true
                }
                .foregroundColor(.orange)

                Button(String.localized(.resetDeveloperMode)) {
                    showResetDevConfirmation = true
                }
                .foregroundColor(.red)
            } header: {
                Text(String.localized(.developer))
                    .foregroundColor(.orange)
            } footer: {
                Text(String.localized(.reseedingDescription))
                    .foregroundColor(.secondary)
            }
        }
        .navigationTitle(String.localized(.developer))
        .navigationBarTitleDisplayMode(.inline)
        .confirmationDialog(String.localized(.reSeedTitle),
                            isPresented: $showReseedConfirmation,
                            titleVisibility: .visible) {
            Button(String.localized(.reSeed), role: .destructive) {
                Task {
                    await viewModel.reseedPublicHolidays()
                    showToastMessage(viewModel.successMessage ?? String.localized(.holidaysReSeeded))
                }
            }
            Button(String.localized(.cancel), role: .cancel) {}
        } message: {
            Text(String.localized(.reseedingWarning))
        }
        .confirmationDialog(String.localized(.resetDeveloperModeTitle),
                            isPresented: $showResetDevConfirmation,
                            titleVisibility: .visible) {
            Button(String.localized(.resetToDefaults), role: .destructive) {
                developerModeEnabled = false
                showToastMessage(String.localized(.developerModeDisabled))
            }
            Button(String.localized(.cancel), role: .cancel) {}
        } message: {
            Text(String.localized(.resetDeveloperModeWarning))
        }
        .toast(message: toastMessage, isShowing: showToast)
    }

    private func showToastMessage(_ msg: String) {
        toastMessage = msg
        showToast = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            showToast = false
        }
    }
}
