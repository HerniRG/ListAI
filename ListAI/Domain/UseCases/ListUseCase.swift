// NOTE: Updated for real-time publishers; removed userID parameter.
import Combine

protocol ListUseCaseProtocol {
    /// Publisher en tiempo real con las listas del usuario actual
    func listsStream() -> AnyPublisher<[ShoppingListModel], Error>

    /// Crea una lista nueva
    func createList(name: String, context: IAContext) -> AnyPublisher<ShoppingListModel, Error>

    /// Elimina una lista (saldrá de `sharedWith`; si queda vacío, se borra el doc)
    func deleteList(listID: String) -> AnyPublisher<Void, Error>

    /// Comparte una lista con otro correo
    func shareList(listID: String, withEmail email: String) -> AnyPublisher<Void, Error>
}

final class ListUseCase: ListUseCaseProtocol {
    private let repository: ListRepositoryProtocol

    init(repository: ListRepositoryProtocol) {
        self.repository = repository
    }

    func listsStream() -> AnyPublisher<[ShoppingListModel], Error> {
        repository.listsPublisher()
    }

    func createList(name: String, context: IAContext) -> AnyPublisher<ShoppingListModel, Error> {
        repository.createList(name: name, context: context)
    }

    func deleteList(listID: String) -> AnyPublisher<Void, Error> {
        repository.deleteList(listID: listID)
    }

    func shareList(listID: String, withEmail email: String) -> AnyPublisher<Void, Error> {
        repository.shareList(listID: listID, withEmail: email)
    }
}
