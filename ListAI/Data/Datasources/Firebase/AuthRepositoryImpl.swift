import Foundation
import FirebaseAuth
import Combine

final class AuthRepositoryImpl: AuthRepositoryProtocol {
    
    func login(email: String, password: String) -> AnyPublisher<String, Error> {
        Future { promise in
            Auth.auth().signIn(withEmail: email, password: password) { result, error in
                if let error = error {
                    return promise(.failure(error))
                }
                if let uid = result?.user.uid {
                    promise(.success(uid))
                } else {
                    promise(.failure(NSError(domain: "Auth", code: -1, userInfo: [NSLocalizedDescriptionKey: "No se pudo obtener el ID de usuario."])))
                }
            }
        }
        .eraseToAnyPublisher()
    }
    
    func register(email: String, password: String) -> AnyPublisher<String, Error> {
        Future { promise in
            Auth.auth().createUser(withEmail: email, password: password) { result, error in
                if let error = error {
                    return promise(.failure(error))
                }
                if let uid = result?.user.uid {
                    promise(.success(uid))
                } else {
                    promise(.failure(NSError(domain: "Auth", code: -1, userInfo: [NSLocalizedDescriptionKey: "No se pudo obtener el ID de usuario."])))
                }
            }
        }
        .eraseToAnyPublisher()
    }
    
    func logout() -> AnyPublisher<Void, Error> {
        Future { promise in
            do {
                try Auth.auth().signOut()
                promise(.success(()))
            } catch {
                promise(.failure(error))
            }
        }
        .eraseToAnyPublisher()
    }
    
    func getCurrentUserID() -> String? {
        return Auth.auth().currentUser?.uid
    }
}
