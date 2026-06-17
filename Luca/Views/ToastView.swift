import SwiftUI

struct ToastView: ViewModifier {
    let message: String
    let isShowing: Bool
    let color: Color

    func body(content: Content) -> some View {
        content
            .overlay(alignment: .bottom) {
                if isShowing {
                    Text(message)
                        .font(.subheadline.weight(.semibold))
                        .foregroundColor(.white)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 12)
                        .background(color)
                        .cornerRadius(10)
                        .padding(.bottom, 30)
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                        .animation(.easeInOut(duration: 0.3), value: isShowing)
                }
            }
    }
}

extension View {
    func toast(message: String, isShowing: Bool, color: Color = .orange) -> some View {
        modifier(ToastView(message: message, isShowing: isShowing, color: color))
    }
}
