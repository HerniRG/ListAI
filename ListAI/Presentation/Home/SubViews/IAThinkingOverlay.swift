import SwiftUI

struct IAThinkingOverlay: View {
    @State private var animate = false

    var body: some View {
        ZStack {
            Color.indigo
                .opacity(animate ? 0.65 : 0.35)
                .ignoresSafeArea()
                .animation(.easeInOut(duration: 1).repeatForever(autoreverses: true), value: animate)

            VStack(spacing: 16) {
                Image(systemName: "sparkles")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 48, height: 48)
                    .foregroundColor(.white)
                    .scaleEffect(animate ? 1.25 : 0.9)
                    .animation(.easeInOut(duration: 1).repeatForever(autoreverses: true), value: animate)

                Text("Analizando…")
                    .font(.headline)
                    .foregroundColor(.white)
                    .opacity(animate ? 1 : 0.6)
                    .animation(.easeInOut(duration: 1).repeatForever(autoreverses: true), value: animate)
            }
        }
        .onAppear {
            animate = true
        }
        .onDisappear {
            animate = false
        }
    }
}
