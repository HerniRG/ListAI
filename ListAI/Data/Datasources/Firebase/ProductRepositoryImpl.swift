
import Foundation
import FirebaseFirestore
import Combine

final class ProductRepositoryImpl: ProductRepositoryProtocol {
    
    private lazy var db = Firestore.firestore()
    
    func getProducts(userID: String, listID: String) -> AnyPublisher<[ProductModel], Error> {
        let path = "lists/\(listID)/products"
        return Future { promise in
            self.db.collection(path).getDocuments { snapshot, error in
                if let error = error {
                    return promise(.failure(error))
                }
                
                let products = snapshot?.documents.compactMap { doc -> ProductModel? in
                    try? doc.data(as: ProductModel.self)
                } ?? []
                
                promise(.success(products))
            }
        }
        .eraseToAnyPublisher()
    }
    
    func addProduct(userID: String, listID: String, product: ProductModel) -> AnyPublisher<Void, Error> {
        let path = "lists/\(listID)/products"
        return Future { promise in
            do {
                try self.db.collection(path).document(product.id ?? UUID().uuidString).setData(from: product) { error in
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
    
    func updateProduct(userID: String, listID: String, product: ProductModel) -> AnyPublisher<Void, Error> {
        let path = "lists/\(listID)/products"
        guard let id = product.id else {
            return Fail(error: NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Elemento sin ID"]))
                .eraseToAnyPublisher()
        }
        return Future { promise in
            do {
                try self.db.collection(path).document(id).setData(from: product) { error in
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
    
    func deleteProduct(userID: String, listID: String, productID: String) -> AnyPublisher<Void, Error> {
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
