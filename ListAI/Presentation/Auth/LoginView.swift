import SwiftUI
import UIKit

struct LoginView: View {
    @EnvironmentObject var viewModel: LoginViewModel
    let toggleForm: () -> Void

    // Focus state for fields
    @FocusState private var isEmailFieldFocused: Bool
    @FocusState private var isPasswordFieldFocused: Bool
    // Animation state for button scale
    @State private var isLoginButtonPressed = false
    @State private var isRegisterButtonPressed = false

    // State for alerts
    @State private var showAlert = false
    @State private var alertMessage = ""


    // Función local para validar email con regex sencilla
    private func isValidEmail(_ email: String) -> Bool {
        let emailRegEx = #"^[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$"#
        let predicate = NSPredicate(format:"SELF MATCHES %@", emailRegEx)
        return predicate.evaluate(with: email)
    }

    var body: some View {
        ZStack {
            Color(.systemGroupedBackground).ignoresSafeArea()

            VStack {

                VStack(spacing: 18) {
                    Text("Iniciar Sesión")
                        .font(.title2)
                        .fontWeight(.semibold)
                        .padding(.bottom, 10)
                        .accessibilityLabel("Título: Iniciar Sesión")

                    VStack(spacing: 16) {
                        // Email TextField con borde personalizado y focus
                        TextField("Correo", text: $viewModel.email)
                            .textContentType(.username)
                            .keyboardType(.emailAddress)
                            .autocapitalization(.none)
                            .disableAutocorrection(true)
                            .frame(height: 44)
                            .frame(maxWidth: .infinity)
                            .focused($isEmailFieldFocused)
                            .submitLabel(.next)
                            .onSubmit { isPasswordFieldFocused = true }
                            .padding(.horizontal, 12)
                            .background(
                                RoundedRectangle(cornerRadius: 10)
                                    .stroke(Color.secondary.opacity(0.3), lineWidth: 1.5)
                            )

                        // SecureField con .textContentType(.password), borde personalizado y focus
                        SecureField("Contraseña", text: $viewModel.password)
                            .textContentType(.password)
                            .autocapitalization(.none)
                            .disableAutocorrection(true)
                            .frame(height: 44)
                            .frame(maxWidth: .infinity)
                            .focused($isPasswordFieldFocused)
                            .submitLabel(.go)
                            .onSubmit { viewModel.login() }
                            .padding(.horizontal, 12)
                            .background(
                                RoundedRectangle(cornerRadius: 10)
                                    .stroke(Color.secondary.opacity(0.3), lineWidth: 1.5)
                            )
                        
                        // Mostrar texto "¿Has olvidado tu contraseña?" solo si el email es válido
                        if isValidEmail(viewModel.email) {
                            Button(action: {
                                viewModel.recuperarPassword(email: viewModel.email)
                                alertMessage = "Si el correo existe, te hemos enviado un email para restablecer la contraseña."
                                showAlert = true
                            }) {
                                Text("¿Has olvidado tu contraseña?")
                                    .font(.footnote)
                                    .foregroundColor(Color.accentColor)
                            }
                            .padding(.top, 4)
                            .transition(.opacity.combined(with: .move(edge: .bottom)))
                        }

                        if viewModel.isLoading {
                            ProgressView()
                                .padding()
                        } else {
                            Button(action: {
                                // Haptic feedback ligero al pulsar
                                let generator = UIImpactFeedbackGenerator(style: .light)
                                generator.impactOccurred()
                                withAnimation(.spring(response: 0.2, dampingFraction: 0.5)) {
                                    isLoginButtonPressed = true
                                }
                                // Espera breve para la animación
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                                    withAnimation(.spring()) {
                                        isLoginButtonPressed = false
                                    }
                                    viewModel.login()
                                }
                            }) {
                                Text("Entrar")
                                    .font(.system(size: 16, weight: .semibold, design: .rounded))
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 44)
                            }
                            .accessibilityLabel("Botón Entrar")
                            .buttonStyle(.borderedProminent)
                            .animation(.spring(response: 0.32, dampingFraction: 0.6), value: viewModel.isLoading)
                        }
                    }
                    .animation(.easeInOut(duration: 0.3), value: isValidEmail(viewModel.email))
                    .padding(.horizontal)

                    if let error = viewModel.errorMessage {
                        Text(error)
                            .foregroundColor(.red)
                            .font(.caption)
                            .padding(.horizontal)
                            .transition(.move(edge: .top).combined(with: .opacity))
                            .animation(.easeInOut(duration: 0.3), value: viewModel.errorMessage)
                            .onAppear {
                                // Haptic feedback ligero al aparecer error
                                let generator = UINotificationFeedbackGenerator()
                                generator.notificationOccurred(.error)
                            }
                    }

                    Button(action: {
                        withAnimation(.easeInOut(duration: 0.15)) {
                            isRegisterButtonPressed = true
                        }
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.12) {
                            withAnimation(.easeInOut(duration: 0.12)) {
                                isRegisterButtonPressed = false
                            }
                            toggleForm()
                        }
                    }) {
                        Text("¿No tienes cuenta? Regístrate")
                            .foregroundColor(isRegisterButtonPressed ? Color.accentColor.opacity(0.7) : Color.accentColor)
                    }
                    .font(.footnote)
                    .padding(.top, 4)
                }
                .padding()
                // Fondo con mayor corner radius y sombra más suave
                .background(
                    RoundedRectangle(cornerRadius: 24)
                        .fill(Color(UIColor.systemBackground))
                        .shadow(color: .black.opacity(0.12), radius: 18, x: 0, y: 6)
                )
                .padding(.horizontal, 24)
                .animation(.easeInOut, value: viewModel.errorMessage)

            }

        }
        .alert(isPresented: $showAlert) {
            Alert(title: Text("Atención"), message: Text(alertMessage), dismissButton: .default(Text("OK")))
        }
        // Ocultar teclado al tocar fuera de los campos
        .onTapGesture {
            isEmailFieldFocused = false
            isPasswordFieldFocused = false
        }
        // Autofocus en email al aparecer la vista
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                isEmailFieldFocused = true
            }
        }
    }
}
