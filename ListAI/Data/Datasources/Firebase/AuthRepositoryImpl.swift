import Foundation
import FirebaseAuth
import FirebaseFirestore
import Combine

final class AuthRepositoryImpl: AuthRepositoryProtocol {
    
    
    
    func login(email: String, password: String) -> AnyPublisher<String, Error> {
        Future { promise in
            Auth.auth().signIn(withEmail: email, password: password) { result, error in
                if let error = error {
                    return promise(.failure(error))
                }
                guard let user = result?.user else {
                    return promise(.failure(NSError(domain: "Auth", code: -1, userInfo: [NSLocalizedDescriptionKey: "No se pudo obtener el usuario."])))
                }
                
                if !user.isEmailVerified {
                    // try? Auth.auth().signOut()
                    return promise(.failure(NSError(domain: "Auth", code: -2, userInfo: [NSLocalizedDescriptionKey: "Correo no verificado. Por favor, confirma tu cuenta."])))
                }
                let uid = user.uid
                promise(.success(uid))
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
                result?.user.sendEmailVerification(completion: { error in
                    if let error = error {
                        print("⚠️ Error al enviar correo de verificación: \(error.localizedDescription)")
                    } else {
                        print("📧 Correo de verificación enviado.")
                    }
                })
                if let uid = result?.user.uid {
                    promise(.success(uid))
                    let db = Firestore.firestore()
                    db.collection("users").document(uid).setData([
                        "email": email,
                        "createdAt": FieldValue.serverTimestamp()
                    ]) { error in
                        if let error = error {
                            print("⚠️ Error al crear el documento de usuario: \(error.localizedDescription)")
                        }
                    }
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
    
    func deleteAccount() -> AnyPublisher<Void, Error> {
        Future { promise in
            guard let user = Auth.auth().currentUser else {
                return promise(.failure(NSError(domain: "Auth", code: -1, userInfo: [NSLocalizedDescriptionKey: "Usuario no autenticado."])))
            }
            user.delete { error in
                if let error = error {
                    promise(.failure(error))
                } else {
                    do {
                        try Auth.auth().signOut()
                    } catch {
                        print("⚠️ Error al cerrar sesión tras eliminar cuenta: \(error.localizedDescription)")
                    }
                    promise(.success(()))
                }
            }
        }
        .eraseToAnyPublisher()
    }
    
    func getCurrentUserEmail() -> String? {
        return Auth.auth().currentUser?.email
    }
    
    func sendPasswordReset(email: String) -> AnyPublisher<Void, Error> {
        Future { promise in
            Auth.auth().sendPasswordReset(withEmail: email) { error in
                if let error = error {
                    promise(.failure(error))
                } else {
                    promise(.success(()))
                }
            }
        }
        .eraseToAnyPublisher()
    }
    
    func sendVerificationEmail() -> AnyPublisher<Void, Error> {
        Future { promise in
            guard let user = Auth.auth().currentUser else {
                return promise(.failure(NSError(domain: "Auth", code: -1, userInfo: [NSLocalizedDescriptionKey: "No hay usuario autenticado."])))
            }
            
            user.sendEmailVerification { error in
                if let error = error {
                    promise(.failure(error))
                } else {
                    promise(.success(()))
                }
            }
        }
        .eraseToAnyPublisher()
    }
}
