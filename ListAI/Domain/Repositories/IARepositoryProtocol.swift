import Combine

protocol IARepositoryProtocol {
    func getIngredients(for dish: String) -> AnyPublisher<[String], Error>
}
