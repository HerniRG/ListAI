import SwiftUI

// MARK: - Haptic Feedback Helper
enum Haptic {
    static func light() {
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.impactOccurred()
    }
}

struct FloatingAddButton: View {
    @Binding var fabRotation: Double
    @Binding var showAddProductSheet: Bool

    var body: some View {
        Button {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.5)) {
                fabRotation += 90
            }
            Haptic.light()
            showAddProductSheet = true
        } label: {
            ZStack {
                Circle()
                    .fill(Color.accentColor)
                    .frame(width: 56, height: 56)
                    .shadow(color: .accentColor.opacity(0.16), radius: 8, x: 0, y: 4)
                Image(systemName: "plus")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundColor(.white)
                    .rotationEffect(.degrees(fabRotation))
                    .animation(.spring(response: 0.3, dampingFraction: 0.5), value: fabRotation)
            }
        }
        .accessibilityLabel("Añadir elemento")
    }
}
