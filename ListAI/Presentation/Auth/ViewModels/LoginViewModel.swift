import Foundation
import Combine
import FirebaseAuth

final class LoginViewModel: ObservableObject {
    
    // Entrada del usuario
    @Published var email: String = ""
    @Published var password: String = ""
    @Published var isPasswordVisible: Bool = false
    
    // Estado de carga y errores
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    @Published var needsEmailVerification: Bool = false
    
    private let authUseCase: AuthUseCaseProtocol
    private let session: SessionManager
    private var cancellables = Set<AnyCancellable>()
    
    init(authUseCase: AuthUseCaseProtocol, session: SessionManager) {
        self.authUseCase = authUseCase
        self.session = session
    }
    
    func login() {
        errorMessage = nil
        isLoading = true
        needsEmailVerification = false

        authUseCase.login(email: email, password: password)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] completion in
                self?.isLoading = false
                if case let .failure(error) = completion {
                    if let customError = error as NSError?,
                       customError.domain == "Auth",
                       customError.code == -2 {
                        self?.needsEmailVerification = true
                        self?.errorMessage = customError.localizedDescription
                        return
                    }

                    // Mostrar siempre el mismo mensaje para errores de autenticación
                    self?.errorMessage = "Credenciales incorrectas. Por favor, revisa el correo y la contraseña."
                }
            } receiveValue: { [weak self] userID in
                guard let self = self, let user = Auth.auth().currentUser else { return }

                if !user.isEmailVerified {
                    self.needsEmailVerification = true
                    self.isLoading = false 
                    self.errorMessage = "Debes verificar tu correo electrónico antes de iniciar sesión."
                    return
                }

                self.session.checkSession()
            }
            .store(in: &cancellables)
    }
    
    func recuperarPassword(email: String) {
        authUseCase.sendPasswordReset(email: email)
            .receive(on: DispatchQueue.main)
            .sink { _ in
                // En este flujo no hace falta gestionar errores, el feedback ya lo muestra la vista como alert genérico.
            } receiveValue: { _ in }
            .store(in: &cancellables)
    }
    
    func reenviarEmailVerificacion() {
        authUseCase.sendVerificationEmail()
            .receive(on: DispatchQueue.main)
            .sink { [weak self] completion in
                if case let .failure(error) = completion {
                    self?.errorMessage = "Error al reenviar verificación: \(error.localizedDescription)"
                }
            } receiveValue: { [weak self] in
                self?.errorMessage = "Correo de verificación reenviado correctamente."
            }
            .store(in: &cancellables)
    }
}
