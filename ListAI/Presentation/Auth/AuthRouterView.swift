import SwiftUI

struct AuthRouterView: View {
    @State private var showRegister = false
    
    @EnvironmentObject var loginVM: LoginViewModel
    @EnvironmentObject var registerVM: RegisterViewModel
    
    var body: some View {
        VStack {
            
            VStack(spacing: 4) {
                Text("Bienvenido a ListAI")
                    .font(.title).bold()
                    .multilineTextAlignment(.center)
                Text("Organiza tus listas de forma inteligente")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            .padding(.top, 52)
            .accessibilityElement(children: .combine)
            .accessibilityLabel("Bienvenido a ListAI. Organiza tus listas de forma inteligente")
            
            Spacer()
            
            ZStack {
                if showRegister {
                    RegisterView(toggleForm: { showRegister = false })
                        .environmentObject(registerVM)
                        .transition(.asymmetric(insertion: .move(edge: .trailing).combined(with: .opacity),
                                                removal: .move(edge: .trailing).combined(with: .opacity)))
                } else {
                    LoginView(toggleForm: { showRegister = true })
                        .environmentObject(loginVM)
                        .transition(.asymmetric(insertion: .move(edge: .leading).combined(with: .opacity),
                                                removal: .move(edge: .leading).combined(with: .opacity)))
                }
            }
            .background(.ultraThinMaterial)
        }
        .animation(.spring(response: 0.5, dampingFraction: 0.85), value: showRegister)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemGroupedBackground).ignoresSafeArea())
    }
}
