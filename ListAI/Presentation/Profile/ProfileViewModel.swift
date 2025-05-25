import Foundation
import Combine

final class ProfileViewModel: ObservableObject {
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    @Published var successMessage: String?

    private let authUseCase: AuthUseCaseProtocol
    private var cancellables = Set<AnyCancellable>()

    init(authUseCase: AuthUseCaseProtocol) {
        self.authUseCase = authUseCase
    }

    var userEmail: String {
        authUseCase.getCurrentUserEmail() ?? "Sin correo"
    }

    func logout() {
        isLoading = true
        authUseCase.logout()
            .receive(on: DispatchQueue.main)
            .sink { [weak self] completion in
                self?.isLoading = false
                if case let .failure(error) = completion {
                    self?.errorMessage = error.localizedDescription
                }
            } receiveValue: { [weak self] in
                self?.successMessage = "Sesión cerrada correctamente."
            }
            .store(in: &cancellables)
    }

    func deleteAccount() {
        isLoading = true
        authUseCase.deleteAccount()
            .receive(on: DispatchQueue.main)
            .sink { [weak self] completion in
                self?.isLoading = false
                if case let .failure(error) = completion {
                    self?.errorMessage = error.localizedDescription
                }
            } receiveValue: { [weak self] in
                self?.successMessage = "Cuenta eliminada correctamente."
            }
            .store(in: &cancellables)
    }
    
    func sendPasswordReset() {
        isLoading = true
        guard let email = authUseCase.getCurrentUserEmail() else {
            self.errorMessage = "No se pudo obtener el correo del usuario."
            self.isLoading = false
            return
        }

        authUseCase.sendPasswordReset(email: email)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] completion in
                self?.isLoading = false
                if case let .failure(error) = completion {
                    self?.errorMessage = error.localizedDescription
                }
            } receiveValue: { [weak self] in
                self?.successMessage = "Se ha enviado un correo para restablecer tu contraseña."
            }
            .store(in: &cancellables)
    }
}
