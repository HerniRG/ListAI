import Foundation
import Combine

protocol IAUseCaseProtocol {
    func getIngredients(for dish: String) -> AnyPublisher<[String], Error>
}

final class IAUseCase: IAUseCaseProtocol {
    private let repository: IARepositoryProtocol

    init(repository: IARepositoryProtocol) {
        self.repository = repository
    }

    func getIngredients(for dish: String) -> AnyPublisher<[String], Error> {
        repository.getIngredients(for: dish)
    }
}
