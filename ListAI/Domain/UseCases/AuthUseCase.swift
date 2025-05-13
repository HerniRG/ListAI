import Foundation
import Combine

protocol AuthUseCaseProtocol {
    func login(email: String, password: String) -> AnyPublisher<String, Error>
    func register(email: String, password: String) -> AnyPublisher<String, Error>
    func logout() -> AnyPublisher<Void, Error>
    func getCurrentUserID() -> String?
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
}
