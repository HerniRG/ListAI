import SwiftUI

struct EmptyListsAnimatedView: View {
    @State private var appear = false
    let onCreate: () -> Void
    
    var body: some View {
        VStack(spacing: 24) {
            Image(systemName: "rectangle.stack.badge.plus")
                .resizable()
                .scaledToFit()
                .frame(width: 72, height: 72)
                .foregroundColor(.accentColor.opacity(0.3))
                .scaleEffect(appear ? 1 : 0.8)
                .opacity(appear ? 1 : 0)
                .animation(.spring(response: 0.5, dampingFraction: 0.6), value: appear)
            Text("No tienes listas todavía")
                .font(.title3.bold())
                .scaleEffect(appear ? 1 : 0.8)
                .opacity(appear ? 1 : 0)
                .animation(.spring(response: 0.7, dampingFraction: 0.7).delay(0.07), value: appear)
            Button("Crear primera lista") {
                onCreate()
            }
            .buttonStyle(.borderedProminent)
            .scaleEffect(appear ? 1 : 0.9)
            .opacity(appear ? 1 : 0)
            .animation(.spring(response: 0.8, dampingFraction: 0.7).delay(0.13), value: appear)
        }
        .padding(.top, 60)
        .onAppear { appear = true }
        .onDisappear { appear = false }
    }
    
}
