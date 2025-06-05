import Foundation
import Combine

protocol ListRepositoryProtocol {
    /// Publisher en tiempo real con las listas compartidas con el usuario actual
    func listsPublisher() -> AnyPublisher<[ShoppingListModel], Error>

    /// Crea una nueva lista
    func createList(name: String, context: IAContext) -> AnyPublisher<ShoppingListModel, Error>

    /// Elimina (o abandona) una lista
    func deleteList(listID: String) -> AnyPublisher<Void, Error>

    /// Comparte una lista con otro usuario por email
    func shareList(listID: String, withEmail email: String) -> AnyPublisher<Void, Error>
}
