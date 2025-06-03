import Foundation
import Combine

final class RegisterViewModel: ObservableObject {
    
    // Entrada del usuario
    @Published var email: String = ""
    @Published var password: String = ""
    @Published var confirmPassword: String = ""
    @Published var isPasswordVisible: Bool = false
    @Published var isConfirmPasswordVisible: Bool = false
    
    // Estado
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    @Published var isSuccessMessage: Bool = false
    
    private let authUseCase: AuthUseCaseProtocol
    private let session: SessionManager
    private var cancellables = Set<AnyCancellable>()
    
    init(authUseCase: AuthUseCaseProtocol, session: SessionManager) {
        self.authUseCase = authUseCase
        self.session = session
    }
    
    func register() {
        guard password == confirmPassword else {
            errorMessage = "Las contraseñas no coinciden."
            return
        }
        
        errorMessage = nil
        isSuccessMessage = false
        isLoading = true
        
        authUseCase.register(email: email, password: password)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] completion in
                self?.isLoading = false
                if case .failure(let error) = completion {
                    let errorMessage = error.localizedDescription
                    if errorMessage.contains("6 characters") || errorMessage.contains("Password should be at least 6 characters") {
                        self?.errorMessage = "La contraseña debe tener al menos 6 caracteres."
                    } else {
                        self?.errorMessage = "No se ha podido registrar. Por favor, revisa los datos e inténtalo de nuevo."
                    }
                    self?.isSuccessMessage = false
                }
            } receiveValue: { [weak self] userID in
                self?.authUseCase.sendVerificationEmail()
                    .receive(on: DispatchQueue.main)
                    .sink { _ in } receiveValue: { [weak self] in
                        self?.errorMessage = "Hemos enviado un correo. Revisa tu bandeja antes de iniciar sesión."
                        self?.isSuccessMessage = true
                    }
                    .store(in: &self!.cancellables)
            }
            .store(in: &cancellables)
    }
}
