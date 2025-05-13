import Foundation
import Combine

protocol ProductUseCaseProtocol {
    func getProducts(userID: String, listID: String) -> AnyPublisher<[ProductModel], Error>
    func addProduct(userID: String, listID: String, product: ProductModel) -> AnyPublisher<Void, Error>
    func updateProduct(userID: String, listID: String, product: ProductModel) -> AnyPublisher<Void, Error>
    func deleteProduct(userID: String, listID: String, productID: String) -> AnyPublisher<Void, Error>
}

final class ProductUseCase: ProductUseCaseProtocol {
    private let repository: ProductRepositoryProtocol
    
    init(repository: ProductRepositoryProtocol) {
        self.repository = repository
    }
    
    func getProducts(userID: String, listID: String) -> AnyPublisher<[ProductModel], Error> {
        repository.getProducts(userID: userID, listID: listID)
    }
    
    func addProduct(userID: String, listID: String, product: ProductModel) -> AnyPublisher<Void, Error> {
        repository.addProduct(userID: userID, listID: listID, product: product)
    }
    
    func updateProduct(userID: String, listID: String, product: ProductModel) -> AnyPublisher<Void, Error> {
        repository.updateProduct(userID: userID, listID: listID, product: product)
    }
    
    func deleteProduct(userID: String, listID: String, productID: String) -> AnyPublisher<Void, Error> {
        repository.deleteProduct(userID: userID, listID: listID, productID: productID)
    }
}
