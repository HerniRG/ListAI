import SwiftUI

struct HomeHeaderView: View {
    @State private var appear = false
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text("ListAI").font(.largeTitle.bold())
                Text("Organiza tus ideas, compras o eventos fácilmente")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            Spacer()
            ProfileIconView()
        }
        .scaleEffect(appear ? 1 : 0.96)
        .opacity(appear ? 1 : 0)
        .animation(.spring(response: 0.45, dampingFraction: 0.7), value: appear)
        .padding(.bottom, 12)
        .onAppear { appear = true }
        .onDisappear { appear = false }
    }
}
