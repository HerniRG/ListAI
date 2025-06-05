import Foundation
import Combine

protocol ProductRepositoryProtocol {
    /// Publisher en tiempo real con los productos de una lista
    func productsPublisher(listID: String) -> AnyPublisher<[ProductModel], Error>

    /// Añade un nuevo producto
    func addProduct(listID: String, product: ProductModel) -> AnyPublisher<Void, Error>

    /// Actualiza un producto existente
    func updateProduct(listID: String, product: ProductModel) -> AnyPublisher<Void, Error>

    /// Elimina un producto
    func deleteProduct(listID: String, productID: String) -> AnyPublisher<Void, Error>
}
