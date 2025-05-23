import Combine

protocol IARepositoryProtocol {
    func getIngredients(for dish: String,
                        context: IAContext) -> AnyPublisher<[String], Error>
}
