import Foundation
import Combine

final class LoginViewModel: ObservableObject {
    
    // Entrada del usuario
    @Published var email: String = ""
    @Published var password: String = ""
    @Published var isPasswordVisible: Bool = false
    
    // Estado de carga y errores
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    
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
        
        authUseCase.login(email: email, password: password)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] completion in
                self?.isLoading = false
                if case .failure = completion {
                    self?.errorMessage = "Credenciales incorrectas. Por favor, revisa el correo y la contraseña."
                }
            } receiveValue: { [weak self] userID in
                self?.session.checkSession() // actualiza el estado global
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
}
