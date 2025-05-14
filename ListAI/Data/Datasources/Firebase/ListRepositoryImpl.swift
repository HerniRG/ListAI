import Foundation
import Combine
import FirebaseFirestore

final class ListRepositoryImpl: ListRepositoryProtocol {
    
    private lazy var db = Firestore.firestore()
    
    func getAllLists(userID: String) -> AnyPublisher<[ShoppingListModel], Error> {
        let path = "users/\(userID)/lists"
        return Future { promise in
            self.db.collection(path).getDocuments { snapshot, error in
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
    
    func createList(userID: String, name: String) -> AnyPublisher<ShoppingListModel, Error> {
        let path = "users/\(userID)/lists"
        let newList = ShoppingListModel(
            id: UUID().uuidString,
            nombre: name,
            fechaCreacion: Date(),
            esFavorita: false
        )
        
        return Future { promise in
            do {
                try self.db.collection(path).document(newList.id ?? UUID().uuidString).setData(from: newList) {
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
        let path = "users/\(userID)/lists/\(listID)"
        return Future { promise in
            self.db.document(path).delete { error in
                if let error = error {
                    return promise(.failure(error))
                }
                promise(.success(()))
            }
        }
        .eraseToAnyPublisher()
    }
}
