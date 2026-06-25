import SwiftUI

struct ConfirmationBottomSheet: View {
    let title: String
    let message: String
    let buttonTitle: String
    var buttonRole: ButtonRole = .destructive
    var cancelTitle: String? = nil
    var showCancel: Bool = true
    @Binding var isPresented: Bool
    let action: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            Text(title)
                .font(.title3)
                .fontWeight(.semibold)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 24)
                .padding(.top, 20)

            Text(message)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 24)
                .padding(.top, 10)

            Divider()
                .padding(.vertical, 20)

            Button(role: buttonRole) {
                isPresented = false
                action()
            } label: {
                Text(buttonTitle)
                    .fontWeight(.semibold)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
            }
            .buttonStyle(.borderedProminent)
            .tint(buttonRole == .destructive ? .red : .accentColor)
            .padding(.horizontal, 24)

            if showCancel {
                Button(cancelTitle ?? String.localized(.cancel)) {
                    isPresented = false
                }
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(.secondary)
                .padding(.vertical, 14)
                .frame(maxWidth: .infinity)

                Spacer(minLength: 0)
            }
        }
        .presentationDetents([.height(260)])
        .presentationDragIndicator(.visible)
    }
}
