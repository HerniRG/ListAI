import Foundation
import Combine

protocol AuthRepositoryProtocol {
    func login(email: String, password: String) -> AnyPublisher<String, Error>
    func register(email: String, password: String) -> AnyPublisher<String, Error>
    func logout() -> AnyPublisher<Void, Error>
    func getCurrentUserID() -> String?
    func deleteAccount() -> AnyPublisher<Void, Error>
    func getCurrentUserEmail() -> String?
    func sendPasswordReset(email: String) -> AnyPublisher<Void, Error>
}
