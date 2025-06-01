import SwiftUI

struct ProfileIconView: View {
    @EnvironmentObject var profileViewModel: ProfileViewModel
    @State private var showProfile = false

    private var userEmail: String {
        profileViewModel.userEmail
    }

    private var initials: String {
        let namePart = userEmail.components(separatedBy: "@").first ?? ""
        let clean = namePart.replacingOccurrences(of: "[^a-zA-Z]", with: "", options: .regularExpression)
        return clean.prefix(1).uppercased()
    }

    private var color: Color {
        let hash = abs(userEmail.hashValue)
        let hue = Double((hash % 360)) / 360.0
        return Color(hue: hue, saturation: 0.4, brightness: 0.85)
    }

    var body: some View {
        Button {
            showProfile = true
        } label: {
            Text(initials)
                .font(.system(size: 16, weight: .bold))
                .foregroundColor(.white)
                .frame(width: 36, height: 36)
                .background(Circle().fill(color))
                .accessibilityLabel("Perfil")
        }
        .sheet(isPresented: $showProfile) {
            ProfileView()
        }
    }
}
