import SwiftUI

struct ConfirmationBottomSheet: View {
    let title: String
    let message: String
    let buttonTitle: String
    let buttonRole: ButtonRole
    @Binding var isPresented: Bool
    let action: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            Capsule()
                .fill(Color(.systemGray4))
                .frame(width: 36, height: 5)
                .padding(.top, 10)
                .padding(.bottom, 16)

            Text(title)
                .font(.headline)
                .fontWeight(.semibold)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 24)

            Text(message)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 24)
                .padding(.top, 8)

            Divider()
                .padding(.vertical, 16)

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

            Button(String.localized(.cancel)) {
                isPresented = false
            }
            .font(.subheadline)
            .foregroundColor(.secondary)
            .padding(.vertical, 14)
            .frame(maxWidth: .infinity)

            Spacer(minLength: 0)
        }
        .presentationDetents([.height(280)])
        .presentationDragIndicator(.visible)
    }
}
