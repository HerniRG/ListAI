import Foundation
import Combine

protocol ListRepositoryProtocol {
    func getAllLists(userID: String) -> AnyPublisher<[ShoppingListModel], Error>
    func createList(userID: String, name: String, context: IAContext) -> AnyPublisher<ShoppingListModel, Error>
    func deleteList(userID: String, listID: String) -> AnyPublisher<Void, Error>
    func shareList(listID: String, withEmail email: String) -> AnyPublisher<Void, Error>
}
