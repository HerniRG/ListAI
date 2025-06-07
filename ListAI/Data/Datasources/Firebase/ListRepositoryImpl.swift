import Foundation
import Combine
import FirebaseFirestore
import FirebaseAuth
// NOTE: Updated to real-time Combine publisher; requires Publishers.FirestoreSnapshot

final class ListRepositoryImpl: ListRepositoryProtocol {
    
    private lazy var db = Firestore.firestore()
    
    // Publisher en tiempo real para las listas compartidas con el usuario actual
    func listsPublisher() -> AnyPublisher<[ShoppingListModel], Error> {
        guard let rawEmail = Auth.auth().currentUser?.email else {
            return Fail(error: NSError(domain: "", code: 401,
                                       userInfo: [NSLocalizedDescriptionKey: "Usuario no autenticado"]))
            .eraseToAnyPublisher()
        }
        let email = rawEmail.lowercased()

        let query = db.collection("lists").whereField("sharedWith", arrayContains: email)
        return Publishers.FirestoreSnapshot(query)
            .map { snapshot in
                snapshot.documents.compactMap { try? $0.data(as: ShoppingListModel.self) }
                    .sorted { $0.fechaCreacion < $1.fechaCreacion }
            }
            .eraseToAnyPublisher()
    }

    func shareList(listID: String, withEmail rawEmail: String) -> AnyPublisher<Void, Error> {
        let email = rawEmail.lowercased()
        let docRef = db.document("lists/\(listID)")
        return Future { promise in
            let userDoc = self.db.collection("users").document(email)

            userDoc.setData([
                "email": email,
                "createdAt": FieldValue.serverTimestamp()
            ], merge: true) { err in
                if let err { print("⚠️ No se pudo crear user stub:", err) }
            }

            docRef.updateData([
                "sharedWith": FieldValue.arrayUnion([email])
            ]) { error in
                if let error = error {
                    return promise(.failure(error))
                }
                promise(.success(()))
            }
        }
        .eraseToAnyPublisher()
    }
    
    func createList(name: String, context: IAContext) -> AnyPublisher<ShoppingListModel, Error> {
        guard let email = Auth.auth().currentUser?.email else {
            return Fail(error: NSError(domain: "", code: 401, userInfo: [NSLocalizedDescriptionKey: "Usuario no autenticado"])).eraseToAnyPublisher()
        }
        let newList = ShoppingListModel(
            id: UUID().uuidString,
            nombre: name,
            fechaCreacion: Date(),
            sharedWith: [email.lowercased()],
            context: context
        )
        
        return Future { promise in
            do {
                try self.db.collection("lists").document(newList.id ?? UUID().uuidString).setData(from: newList) {
                    if let error = $0 {
                        return promise(.failure(error))
                    }
                    promise(.success(newList))
                }
            } catch {
                promise(.failure(error))
            }
        }
        .eraseToAnyPublisher()
    }
    
    func deleteList(listID: String) -> AnyPublisher<Void, Error> {
        guard let email = Auth.auth().currentUser?.email else {
            return Fail(error: NSError(domain: "", code: 401,
                                       userInfo: [NSLocalizedDescriptionKey: "Usuario no autenticado"]))
            .eraseToAnyPublisher()
        }

        let docRef = db.document("lists/\(listID)")

        return Future { promise in
            docRef.getDocument { document, error in
                if let error = error {
                    return promise(.failure(error))
                }
                guard let data = document?.data(),
                      var shared = data["sharedWith"] as? [String] else {
                    return promise(.failure(NSError(domain: "", code: 404, userInfo: [NSLocalizedDescriptionKey: "Lista no encontrada o corrupta"])))
                }

                shared.removeAll { $0 == email }

                if shared.isEmpty {
                    docRef.delete { error in
                        if let error = error {
                            return promise(.failure(error))
                        }
                        promise(.success(()))
                    }
                } else {
                    docRef.updateData(["sharedWith": shared]) { error in
                        if let error = error {
                            return promise(.failure(error))
                        }
                        promise(.success(()))
                    }
                }
            }
        }
        .eraseToAnyPublisher()
    }
}
