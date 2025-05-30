import SwiftUI

struct AuthRouterView: View {
    @State private var showRegister = false

    @EnvironmentObject var loginVM: LoginViewModel
    @EnvironmentObject var registerVM: RegisterViewModel

    var body: some View {
        ZStack {
            if showRegister {
                RegisterView(toggleForm: { showRegister = false })
                    .environmentObject(registerVM)
                    .transition(.asymmetric(insertion: .move(edge: .trailing),
                                            removal: .move(edge: .trailing)))
            } else {
                LoginView(toggleForm: { showRegister = true })
                    .environmentObject(loginVM)
                    .transition(.asymmetric(insertion: .move(edge: .leading),
                                            removal: .move(edge: .leading)))
            }
        }
        .background(Color(.systemGroupedBackground).ignoresSafeArea())
        .animation(.easeInOut(duration: 0.4), value: showRegister)
    }
}
