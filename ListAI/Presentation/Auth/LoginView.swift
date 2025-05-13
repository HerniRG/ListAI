import SwiftUI

struct LoginView: View {
    @EnvironmentObject var viewModel: LoginViewModel
    let toggleForm: () -> Void
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Iniciar Sesión")
                .font(.largeTitle.bold())
            
            TextField("Correo", text: $viewModel.email)
                .textContentType(.emailAddress)
                .keyboardType(.emailAddress)
                .textFieldStyle(.roundedBorder)
            
            SecureField("Contraseña", text: $viewModel.password)
                .textFieldStyle(.roundedBorder)
            
            if let error = viewModel.errorMessage {
                Text(error).foregroundColor(.red)
            }
            
            if viewModel.isLoading {
                ProgressView()
            } else {
                Button("Entrar") {
                    viewModel.login()
                }
                .buttonStyle(.borderedProminent)
            }
            
            Button("¿No tienes cuenta? Regístrate") {
                toggleForm()
            }
        }
        .padding()
    }
}
