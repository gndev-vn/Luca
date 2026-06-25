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
        .sheet(isPresented: $showReseedConfirmation) {
            ConfirmationBottomSheet(
                title: String.localized(.reSeedTitle),
                message: String.localized(.reseedingWarning),
                buttonTitle: String.localized(.reSeed),
                buttonRole: .destructive,
                isPresented: $showReseedConfirmation
            ) {
                Task {
                    await viewModel.reseedPublicHolidays()
                    showToastMessage(viewModel.successMessage ?? String.localized(.holidaysReSeeded))
                }
            }
        }
        .sheet(isPresented: $showResetDevConfirmation) {
            ConfirmationBottomSheet(
                title: String.localized(.resetDeveloperModeTitle),
                message: String.localized(.resetDeveloperModeWarning),
                buttonTitle: String.localized(.resetToDefaults),
                buttonRole: .destructive,
                isPresented: $showResetDevConfirmation
            ) {
                developerModeEnabled = false
                showToastMessage(String.localized(.developerModeDisabled))
            }
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
