import SwiftUI

struct FloatingIAButton: View {
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: "sparkles")
                .resizable()
                .scaledToFit()
                .frame(width: 22, height: 22)
                .padding()
                .background(Circle().fill(Color.indigo))
                .foregroundColor(.white)
                .shadow(color: Color.black.opacity(0.2), radius: 4, x: 0, y: 2)
        }
        .accessibilityLabel("Sugerencias IA")
        .accessibilityHint("Pulsa para obtener sugerencias basadas en la lista")
    }
}
