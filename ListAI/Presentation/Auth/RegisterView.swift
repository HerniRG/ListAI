import SwiftUI

struct RegisterView: View {
    @EnvironmentObject var viewModel: RegisterViewModel
    let toggleForm: () -> Void
    @FocusState private var focusedField: Field?
    
    enum Field {
        case email, password, confirmPassword
    }
    
    var body: some View {
        ZStack {
            Color(UIColor.systemGroupedBackground)
                .ignoresSafeArea()
                .onTapGesture {
                    UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                }
            
            VStack(spacing: 18) {
                
                Text("Registrarse")
                    .font(.title2)
                    .fontWeight(.semibold)
                    .padding(.bottom, 10)
                    .accessibilityLabel("Título: Registrarse")
                
                
                VStack(spacing: 16) {
                    TextField("Correo", text: $viewModel.email)
                        .textContentType(.emailAddress)
                        .keyboardType(.emailAddress)
                        .autocapitalization(.none)
                        .disableAutocorrection(true)
                        .padding(.horizontal, 12)
                        .frame(height: 44)
                        .frame(maxWidth: .infinity)
                        .background(
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(Color.secondary.opacity(0.22), lineWidth: 1.5)
                        )
                        .focused($focusedField, equals: .email)
                        .submitLabel(.next)
                        .onSubmit {
                            focusedField = .password
                        }
                    
                    SecureField("Contraseña", text: $viewModel.password)
                        .textContentType(.newPassword)
                        .autocapitalization(.none)
                        .disableAutocorrection(true)
                        .padding(.horizontal, 12)
                        .frame(height: 44)
                        .frame(maxWidth: .infinity)
                        .background(
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(Color.secondary.opacity(0.22), lineWidth: 1.5)
                        )
                        .focused($focusedField, equals: .password)
                        .submitLabel(.next)
                        .onSubmit {
                            focusedField = .confirmPassword
                        }
                    
                    SecureField("Confirmar contraseña", text: $viewModel.confirmPassword)
                        .textContentType(.newPassword)
                        .autocapitalization(.none)
                        .disableAutocorrection(true)
                        .padding(.horizontal, 12)
                        .frame(height: 44)
                        .frame(maxWidth: .infinity)
                        .background(
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(Color.secondary.opacity(0.22), lineWidth: 1.5)
                        )
                        .focused($focusedField, equals: .confirmPassword)
                        .submitLabel(.go)
                        .onSubmit {
                            viewModel.register()
                        }
                }
                
                if viewModel.isLoading {
                    ProgressView()
                        .frame(height: 44)
                        .frame(maxWidth: .infinity)
                } else {
                    Button(action: {
                        withAnimation(.spring(response: 0.32, dampingFraction: 0.6)) {
                            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                            viewModel.register()
                        }
                    }) {
                        Text("Registrarse")
                            .font(.system(size: 16, weight: .semibold, design: .rounded))
                            .frame(maxWidth: .infinity)
                            .frame(height: 44)
                    }
                    .buttonStyle(.borderedProminent)
                    .scaleEffect(viewModel.isLoading ? 0.98 : 1.0)
                    .animation(.spring(response: 0.32, dampingFraction: 0.6), value: viewModel.isLoading)
                }
                
                if let error = viewModel.errorMessage {
                    Text(error)
                        .font(.caption)
                        .foregroundColor(.red)
                        .padding(.horizontal)
                        .multilineTextAlignment(.center)
                        .lineLimit(nil)
                        .transition(.asymmetric(insertion: .move(edge: .top).combined(with: .opacity), removal: .opacity))
                        .animation(.easeInOut(duration: 0.3), value: viewModel.errorMessage)
                }
                
                Button(action: {
                    withAnimation(.spring(response: 0.32, dampingFraction: 0.7)) {
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                        toggleForm()
                    }
                }) {
                    Text("¿Ya tienes cuenta? Inicia sesión")
                        .font(.footnote)
                        .foregroundColor(.accentColor)
                        .frame(maxWidth: .infinity)
                        .background(Color.clear)
                }
                .buttonStyle(.plain)
                .padding(.top, 4)
                
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 18)
            .background(
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .fill(Color(UIColor.systemBackground))
                    .shadow(color: .black.opacity(0.12), radius: 18, x: 0, y: 6)
            )
            .onAppear {
                focusedField = .email
            }
            .padding(.horizontal, 24)
        }
    }
}
