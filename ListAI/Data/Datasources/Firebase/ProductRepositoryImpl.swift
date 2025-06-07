import Foundation
import FirebaseFirestore
import Combine
// NOTE: Updated to real‑time Combine publisher; requires Publishers.FirestoreSnapshot

final class ProductRepositoryImpl: ProductRepositoryProtocol {
    
    private lazy var db = Firestore.firestore()
    
    // Publisher en tiempo real de los productos de una lista
    func productsPublisher(listID: String) -> AnyPublisher<[ProductModel], Error> {
        let collection = db.collection("lists")
            .document(listID)
            .collection("products")
            .order(by: "orden")
        return Publishers.FirestoreSnapshot(collection)
            .map { snapshot in
                snapshot.documents.compactMap { try? $0.data(as: ProductModel.self) }
                    .sorted { ($0.orden ?? Int.max) < ($1.orden ?? Int.max) }
            }
            .eraseToAnyPublisher()
    }
    
    func addProduct(listID: String, product: ProductModel) -> AnyPublisher<Void, Error> {
        let path = "lists/\(listID)/products"
        return Future { promise in
            let docID = product.id ?? UUID().uuidString
            let docRef = self.db.collection(path).document(docID)

            do {
                try docRef.setData(from: product) { error in
                    if let error = error {
                        promise(.failure(error))
                    } else {
                        promise(.success(()))
                    }
                }
            } catch {
                promise(.failure(error))
            }
        }
        .eraseToAnyPublisher()
    }
    
    func updateProduct(listID: String, product: ProductModel) -> AnyPublisher<Void, Error> {
        let path = "lists/\(listID)/products"
        guard let id = product.id else {
            return Fail(error: NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Elemento sin ID"]))
                .eraseToAnyPublisher()
        }

        let docRef = self.db.collection(path).document(id)

        return Future { promise in
            do {
                try docRef.setData(from: product) { error in
                    if let error = error {
                        promise(.failure(error))
                    } else {
                        promise(.success(()))
                    }
                }
            } catch {
                promise(.failure(error))
            }
        }
        .eraseToAnyPublisher()
    }
    
    func deleteProduct(listID: String, productID: String) -> AnyPublisher<Void, Error> {
        let path = "lists/\(listID)/products/\(productID)"
        return Future { promise in
            self.db.document(path).delete { error in
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
