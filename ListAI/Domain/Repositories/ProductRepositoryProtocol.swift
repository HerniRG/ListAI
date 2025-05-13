import Foundation
import Combine

protocol ProductRepositoryProtocol {
    func getProducts(userID: String, listID: String) -> AnyPublisher<[ProductModel], Error>
    func addProduct(userID: String, listID: String, product: ProductModel) -> AnyPublisher<Void, Error>
    func updateProduct(userID: String, listID: String, product: ProductModel) -> AnyPublisher<Void, Error>
    func deleteProduct(userID: String, listID: String, productID: String) -> AnyPublisher<Void, Error>
}
