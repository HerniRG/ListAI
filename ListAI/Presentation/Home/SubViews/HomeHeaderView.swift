import SwiftUI

struct HomeHeaderView: View {
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
        .padding(.bottom, 12)
    }
}
