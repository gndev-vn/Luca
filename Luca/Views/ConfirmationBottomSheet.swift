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

    @Environment(\.horizontalSizeClass) private var horizontalSizeClass

    private var isDestructive: Bool { buttonRole == .destructive }

    private var iconName: String {
        isDestructive ? "exclamationmark.triangle.fill" : "info.circle.fill"
    }

    private var iconColor: Color {
        isDestructive ? .red : .accentColor
    }

    private let actionButtonHeight: CGFloat = 58

    private var estimatedSheetHeight: CGFloat {
        let baseHeight: CGFloat = showCancel ? 255 : 215
        let charsPerLine: CGFloat = horizontalSizeClass == .regular ? 48 : 32
        let estimatedLines = ceil(CGFloat(max(message.count, 1)) / charsPerLine)
        let messageHeight = estimatedLines * 22
        return min(500, max(250, baseHeight + messageHeight))
    }

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 12) {
                Image(systemName: iconName)
                    .font(.system(size: 19, weight: .semibold))
                    .foregroundStyle(iconColor)
                    .frame(width: 28, height: 28)

                Text(title)
                    .font(.title3.weight(.bold))
                    .foregroundStyle(.primary)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(.horizontal, 20)
            .padding(.top, 18)
            .padding(.bottom, 8)

            Text(message)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.leading)
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 20)
                .padding(.bottom, 18)

            VStack(spacing: 10) {
                Button {
                    isPresented = false
                    action()
                } label: {
                    Text(buttonTitle)
                        .fontWeight(.semibold)
                        .frame(maxWidth: .infinity)
                        .frame(height: actionButtonHeight)
                }
                .foregroundStyle(.white)
                .background(
                    Capsule()
                        .fill(isDestructive ? Color.red : Color.accentColor)
                )

                if showCancel {
                    Button(cancelTitle ?? String.localized(.cancel)) {
                        isPresented = false
                    }
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(.primary)
                    .frame(maxWidth: .infinity)
                    .frame(height: actionButtonHeight)
                    .background(
                        Capsule()
                            .fill(Color.primary.opacity(0.08))
                    )
                }
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 20)
        }
        .frame(maxWidth: .infinity)
        .presentationDetents([.height(estimatedSheetHeight)])
        .presentationDragIndicator(.visible)
        .presentationBackground(.regularMaterial)
    }
}
