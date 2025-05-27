import Foundation
import Combine

protocol IAUseCaseProtocol {
    func getIngredients(for dish: String,
                        context: IAContext,
                        listName: String) -> AnyPublisher<[String], Error>
    func analyzeList(name: String,
                     context: IAContext,
                     pending: [String],
                     done: [String]) -> AnyPublisher<AnalysisResult, Error>
}

final class IAUseCase: IAUseCaseProtocol {
    private let repository: IARepositoryProtocol

    init(repository: IARepositoryProtocol) {
        self.repository = repository
    }

    func getIngredients(for dish: String,
                        context: IAContext,
                        listName: String) -> AnyPublisher<[String], Error> {
        repository.getIngredients(for: dish, context: context, listName: listName)
    }
    
    func analyzeList(name: String,
                     context: IAContext,
                     pending: [String],
                     done: [String]) -> AnyPublisher<AnalysisResult, Error> {
        repository.analyzeList(name: name, context: context, pending: pending, done: done)
    }
}
