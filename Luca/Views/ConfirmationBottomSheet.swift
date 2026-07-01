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
            VStack(spacing: 14) {
                VStack(spacing: 10) {
                    Text(title)
                        .font(.title3.weight(.semibold))
                        .multilineTextAlignment(.center)
                        .foregroundStyle(.primary)

                    Text(message)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding(.horizontal, 6)

                VStack(spacing: 10) {
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

                    if showCancel {
                        Button(cancelTitle ?? String.localized(.cancel)) {
                            isPresented = false
                        }
                        .font(.subheadline.weight(.medium))
                        .foregroundColor(.secondary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                    }
                }
            }
            .padding(.horizontal, 18)
            .padding(.top, 14)
            .padding(.bottom, 18)
            .background(.thinMaterial, in: RoundedRectangle(cornerRadius: AppDesign.cardCornerRadius, style: .continuous))
            .padding(.horizontal, 16)
            .padding(.top, 12)
        }
        .background(Color(.systemGroupedBackground))
        .presentationDetents([.height(260)])
        .presentationDragIndicator(.visible)
        .presentationBackground(.thinMaterial)
    }
}
