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
                if case .failure(let error) = completion {
                    self?.errorMessage = error.localizedDescription
                }
            } receiveValue: { [weak self] userID in
                self?.session.checkSession() // actualiza el estado global
            }
            .store(in: &cancellables)
    }
}
