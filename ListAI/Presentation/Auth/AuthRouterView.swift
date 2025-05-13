import SwiftUI

struct AuthRouterView: View {
    @State private var showRegister = false
    
    @EnvironmentObject var loginVM: LoginViewModel
    @EnvironmentObject var registerVM: RegisterViewModel

    var body: some View {
        VStack {
            if showRegister {
                RegisterView(toggleForm: { showRegister = false })
                    .environmentObject(registerVM)
            } else {
                LoginView(toggleForm: { showRegister = true })
                    .environmentObject(loginVM)
            }
        }
    }
}
