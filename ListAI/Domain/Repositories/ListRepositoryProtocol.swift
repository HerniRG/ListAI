import Foundation
import Combine

protocol ListRepositoryProtocol {
    func getAllLists(userID: String) -> AnyPublisher<[ShoppingListModel], Error>
    func createList(userID: String, name: String) -> AnyPublisher<ShoppingListModel, Error>
    func deleteList(userID: String, listID: String) -> AnyPublisher<Void, Error>
}
