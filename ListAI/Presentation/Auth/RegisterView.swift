import SwiftUI

struct RegisterView: View {
    @EnvironmentObject var viewModel: RegisterViewModel
    let toggleForm: () -> Void
    
    var body: some View {
        ZStack {
            Color(.systemGroupedBackground)
                .ignoresSafeArea()
            
            VStack {
                Spacer()
                
                VStack(spacing: 20) {
                    Text("Crear Cuenta")
                        .font(.largeTitle.bold())
                    
                    TextField("Correo", text: $viewModel.email)
                        .textContentType(.emailAddress)
                        .keyboardType(.emailAddress)
                        .autocapitalization(.none)
                        .disableAutocorrection(true)
                        .textFieldStyle(.roundedBorder)

                    HStack {
                        if viewModel.isPasswordVisible {
                            TextField("Contraseña", text: $viewModel.password)
                                .textFieldStyle(.roundedBorder)
                                .autocapitalization(.none)
                                .disableAutocorrection(true)
                        } else {
                            SecureField("Contraseña", text: $viewModel.password)
                                .textFieldStyle(.roundedBorder)
                                .autocapitalization(.none)
                                .disableAutocorrection(true)
                        }
                        Button(action: {
                            viewModel.isPasswordVisible.toggle()
                        }) {
                            Image(systemName: viewModel.isPasswordVisible ? "eye.slash.fill" : "eye.fill")
                                .foregroundColor(.gray)
                        }
                    }

                    HStack {
                        if viewModel.isConfirmPasswordVisible {
                            TextField("Confirmar Contraseña", text: $viewModel.confirmPassword)
                                .textFieldStyle(.roundedBorder)
                                .autocapitalization(.none)
                                .disableAutocorrection(true)
                        } else {
                            SecureField("Confirmar Contraseña", text: $viewModel.confirmPassword)
                                .textFieldStyle(.roundedBorder)
                                .autocapitalization(.none)
                                .disableAutocorrection(true)
                        }
                        Button(action: {
                            viewModel.isConfirmPasswordVisible.toggle()
                        }) {
                            Image(systemName: viewModel.isConfirmPasswordVisible ? "eye.slash.fill" : "eye.fill")
                                .foregroundColor(.gray)
                        }
                    }

                    if let error = viewModel.errorMessage {
                        Text(error)
                            .foregroundColor(.red)
                            .font(.callout)
                            .multilineTextAlignment(.center)
                            .padding(.top, 4)
                    }

                    if viewModel.isLoading {
                        ProgressView()
                    } else {
                        Button("Registrarse") {
                            viewModel.register()
                        }
                        .buttonStyle(.borderedProminent)
                    }

                    Button(action: toggleForm) {
                        Text("¿Ya tienes cuenta? Inicia sesión")
                            .font(.footnote)
                            .foregroundColor(.accentColor)
                    }
                    .padding(.top, 8)
                }
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .fill(Color(.systemBackground))
                        .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 4)
                )
                .padding(.horizontal, 32)
                
                Spacer()
            }
        }
    }
}
