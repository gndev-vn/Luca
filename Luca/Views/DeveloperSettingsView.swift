import SwiftUI

struct DeveloperSettingsView: View {
    @StateObject private var viewModel: SettingsViewModel
    @AppStorage("developer_mode_enabled") private var developerModeEnabled = false
    @State private var activeSheet: DevSettingsSheet?
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
                    activeSheet = .reseed
                }
                .foregroundColor(.orange)

                Button(String.localized(.resetDeveloperMode)) {
                    activeSheet = .resetDevMode
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
        .sheet(item: $activeSheet) { sheet in
            switch sheet {
            case .reseed:
                ConfirmationBottomSheet(
                    title: String.localized(.reSeedTitle),
                    message: String.localized(.reseedingWarning),
                    buttonTitle: String.localized(.reSeed),
                    buttonRole: .destructive,
                    isPresented: Binding(
                        get: { activeSheet != nil },
                        set: { if !$0 { activeSheet = nil } }
                    )
                ) {
                    Task {
                        await viewModel.reseedPublicHolidays()
                        showToastMessage(viewModel.successMessage ?? String.localized(.holidaysReSeeded))
                    }
                }
            case .resetDevMode:
                ConfirmationBottomSheet(
                    title: String.localized(.resetDeveloperModeTitle),
                    message: String.localized(.resetDeveloperModeWarning),
                    buttonTitle: String.localized(.resetToDefaults),
                    buttonRole: .destructive,
                    isPresented: Binding(
                        get: { activeSheet != nil },
                        set: { if !$0 { activeSheet = nil } }
                    )
                ) {
                    developerModeEnabled = false
                    showToastMessage(String.localized(.developerModeDisabled))
                }
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

private enum DevSettingsSheet: Identifiable {
    case reseed
    case resetDevMode
    
    var id: String {
        switch self {
        case .reseed: return "reseed"
        case .resetDevMode: return "resetDevMode"
        }
    }
}
