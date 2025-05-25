import Foundation
import Combine

protocol AuthUseCaseProtocol {
    func login(email: String, password: String) -> AnyPublisher<String, Error>
    func register(email: String, password: String) -> AnyPublisher<String, Error>
    func logout() -> AnyPublisher<Void, Error>
    func getCurrentUserID() -> String?
    func deleteAccount() -> AnyPublisher<Void, Error>
    func getCurrentUserEmail() -> String?
    func sendPasswordReset(email: String) -> AnyPublisher<Void, Error>
}

final class AuthUseCase: AuthUseCaseProtocol {
    private let repository: AuthRepositoryProtocol

    init(repository: AuthRepositoryProtocol) {
        self.repository = repository
    }

    func login(email: String, password: String) -> AnyPublisher<String, Error> {
        repository.login(email: email, password: password)
    }

    func register(email: String, password: String) -> AnyPublisher<String, Error> {
        repository.register(email: email, password: password)
    }

    func logout() -> AnyPublisher<Void, Error> {
        repository.logout()
    }

    func getCurrentUserID() -> String? {
        repository.getCurrentUserID()
    }

    func deleteAccount() -> AnyPublisher<Void, Error> {
        repository.deleteAccount()
    }
    
    func getCurrentUserEmail() -> String? {
        repository.getCurrentUserEmail()
    }
    
    func sendPasswordReset(email: String) -> AnyPublisher<Void, Error> {
        repository.sendPasswordReset(email: email)
    }
}
