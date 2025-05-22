

import SwiftUI

struct ProfileIconView: View {
    @State private var showProfile = false

    var body: some View {
        Button {
            showProfile = true
        } label: {
            Image(systemName: "person.crop.circle.fill")
                .font(.system(size: 30))
                .foregroundColor(.accentColor)
                .accessibilityLabel("Perfil")
        }
        .sheet(isPresented: $showProfile) {
            ProfileView()
        }
    }
}
