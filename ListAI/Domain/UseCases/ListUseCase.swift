import Combine

protocol ListUseCaseProtocol {
    func fetchLists(for userID: String) -> AnyPublisher<[ShoppingListModel], Error>
    func createList(for userID: String, name: String) -> AnyPublisher<ShoppingListModel, Error>
    func deleteList(for userID: String, listID: String) -> AnyPublisher<Void, Error>
}

final class ListUseCase: ListUseCaseProtocol {
    private let repository: ListRepositoryProtocol

    init(repository: ListRepositoryProtocol) {
        self.repository = repository
    }

    func fetchLists(for userID: String) -> AnyPublisher<[ShoppingListModel], Error> {
        repository.getAllLists(userID: userID)
    }

    func createList(for userID: String, name: String) -> AnyPublisher<ShoppingListModel, Error> {
        repository.createList(userID: userID, name: name)
    }

    func deleteList(for userID: String, listID: String) -> AnyPublisher<Void, Error> {
        repository.deleteList(userID: userID, listID: listID)
    }
}
