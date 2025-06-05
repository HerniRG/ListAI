import Foundation
import Combine
// NOTE: Updated for real-time publishers; removed userID parameter.

protocol ProductUseCaseProtocol {
    /// Publisher en tiempo real con los productos de una lista
    func productsStream(listID: String) -> AnyPublisher<[ProductModel], Error>

    /// Añade un nuevo producto
    func addProduct(listID: String, product: ProductModel) -> AnyPublisher<Void, Error>

    /// Actualiza un producto existente
    func updateProduct(listID: String, product: ProductModel) -> AnyPublisher<Void, Error>

    /// Elimina un producto
    func deleteProduct(listID: String, productID: String) -> AnyPublisher<Void, Error>

    /// Actualiza los campos `orden` de varios productos (re‑ordenación masiva)
    func updateProductOrdenes(listID: String, products: [ProductModel]) -> AnyPublisher<Void, Error>
}

final class ProductUseCase: ProductUseCaseProtocol {
    private let repository: ProductRepositoryProtocol
    
    init(repository: ProductRepositoryProtocol) {
        self.repository = repository
    }
    
    func productsStream(listID: String) -> AnyPublisher<[ProductModel], Error> {
        repository.productsPublisher(listID: listID)
    }
    
    func addProduct(listID: String, product: ProductModel) -> AnyPublisher<Void, Error> {
        repository.addProduct(listID: listID, product: product)
    }
    
    func updateProduct(listID: String, product: ProductModel) -> AnyPublisher<Void, Error> {
        repository.updateProduct(listID: listID, product: product)
    }
    
    func deleteProduct(listID: String, productID: String) -> AnyPublisher<Void, Error> {
        repository.deleteProduct(listID: listID, productID: productID)
    }
    
    func updateProductOrdenes(listID: String, products: [ProductModel]) -> AnyPublisher<Void, Error> {
        let updates = products.map {
            repository.updateProduct(listID: listID, product: $0)
        }

        return Publishers.MergeMany(updates)
            .collect()
            .map { _ in () }
            .eraseToAnyPublisher()
    }
}
