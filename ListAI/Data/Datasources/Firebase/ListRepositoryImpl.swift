import Foundation
import Combine
import FirebaseFirestore
import FirebaseAuth

final class ListRepositoryImpl: ListRepositoryProtocol {
    
    private lazy var db = Firestore.firestore()
    
    func getAllLists(userID: String) -> AnyPublisher<[ShoppingListModel], Error> {
        guard let email = Auth.auth().currentUser?.email else {
            return Fail(error: NSError(domain: "", code: 401, userInfo: [NSLocalizedDescriptionKey: "Usuario no autenticado"])).eraseToAnyPublisher()
        }
        return Future { promise in
            self.db.collection("lists").whereField("sharedWith", arrayContains: email).getDocuments { snapshot, error in
                if let error = error {
                    return promise(.failure(error))
                }
                
                let lists = snapshot?.documents.compactMap { doc -> ShoppingListModel? in
                    try? doc.data(as: ShoppingListModel.self)
                } ?? []
                
                promise(.success(lists))
            }
        }
        .eraseToAnyPublisher()
    }

    func shareList(listID: String, withEmail email: String) -> AnyPublisher<Void, Error> {
        let docRef = db.document("lists/\(listID)")
        return Future { promise in
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
    
    func createList(userID: String, name: String, context: IAContext) -> AnyPublisher<ShoppingListModel, Error> {
        guard let email = Auth.auth().currentUser?.email else {
            return Fail(error: NSError(domain: "", code: 401, userInfo: [NSLocalizedDescriptionKey: "Usuario no autenticado"])).eraseToAnyPublisher()
        }
        let newList = ShoppingListModel(
            id: UUID().uuidString,
            nombre: name,
            fechaCreacion: Date(),
            esFavorita: false,
            sharedWith: [email],
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
    
    func deleteList(userID: String, listID: String) -> AnyPublisher<Void, Error> {
        guard let email = Auth.auth().currentUser?.email else {
            return Fail(error: NSError(domain: "", code: 401, userInfo: [NSLocalizedDescriptionKey: "Usuario no autenticado"])).eraseToAnyPublisher()
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
