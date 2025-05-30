import SwiftUI

struct LoginView: View {
    @EnvironmentObject var viewModel: LoginViewModel
    let toggleForm: () -> Void
    
    var body: some View {
        ZStack {
            Color(.systemGroupedBackground).ignoresSafeArea()
            
            VStack {
                Spacer()
                
                VStack(spacing: 20) {
                    Text("Iniciar Sesión")
                        .font(.title)
                        .fontWeight(.semibold)
                        .padding(.bottom, 10)
                    
                    TextField("Correo", text: $viewModel.email)
                        .textContentType(.emailAddress)
                        .keyboardType(.emailAddress)
                        .autocapitalization(.none)
                        .disableAutocorrection(true)
                        .textFieldStyle(.roundedBorder)
                        .padding(.horizontal)
                    
                    HStack {
                        Group {
                            if viewModel.isPasswordVisible {
                                TextField("Contraseña", text: $viewModel.password)
                            } else {
                                SecureField("Contraseña", text: $viewModel.password)
                            }
                        }
                        .textFieldStyle(.roundedBorder)

                        Button(action: {
                            viewModel.isPasswordVisible.toggle()
                        }) {
                            Image(systemName: viewModel.isPasswordVisible ? "eye.slash.fill" : "eye.fill")
                                .foregroundColor(.gray)
                        }
                    }
                    .padding(.horizontal)
                    
                    if let error = viewModel.errorMessage {
                        Text(error)
                            .foregroundColor(.red)
                            .font(.caption)
                            .padding(.horizontal)
                    }
                    
                    if viewModel.isLoading {
                        ProgressView()
                            .padding()
                    } else {
                        Button("Entrar") {
                            viewModel.login()
                        }
                        .buttonStyle(.borderedProminent)
                        .frame(maxWidth: .infinity)
                        .padding(.horizontal)
                    }
                    
                    Button("¿No tienes cuenta? Regístrate") {
                        toggleForm()
                    }
                    .font(.footnote)
                    .padding(.top, 10)
                }
                .padding()
                .background(RoundedRectangle(cornerRadius: 16)
                    .fill(Color.white)
                    .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 4))
                .padding(.horizontal, 24)
                
                Spacer()
            }
        }
    }
}
