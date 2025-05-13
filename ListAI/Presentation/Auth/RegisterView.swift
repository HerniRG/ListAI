import SwiftUI

struct RegisterView: View {
    @EnvironmentObject var viewModel: RegisterViewModel
    let toggleForm: () -> Void
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Crear Cuenta")
                .font(.largeTitle.bold())
            
            TextField("Correo", text: $viewModel.email)
                .textContentType(.emailAddress)
                .keyboardType(.emailAddress)
                .textFieldStyle(.roundedBorder)
            
            SecureField("Contraseña", text: $viewModel.password)
                .textFieldStyle(.roundedBorder)
            
            SecureField("Confirmar Contraseña", text: $viewModel.confirmPassword)
                .textFieldStyle(.roundedBorder)
            
            if let error = viewModel.errorMessage {
                Text(error).foregroundColor(.red)
            }
            
            if viewModel.isLoading {
                ProgressView()
            } else {
                Button("Registrarse") {
                    viewModel.register()
                }
                .buttonStyle(.borderedProminent)
            }
            
            Button("¿Ya tienes cuenta? Inicia sesión") {
                toggleForm()
            }
        }
        .padding()
    }
}
