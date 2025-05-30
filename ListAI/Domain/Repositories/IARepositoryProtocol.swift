import Combine

protocol IARepositoryProtocol {
    func getIngredients(for dish: String,
                        context: IAContext,
                        listName: String) -> AnyPublisher<[String], Error>
    func analyzeList(name: String,
                     context: IAContext,
                     pending: [String],
                     done: [String]) -> AnyPublisher<AnalysisResult, Error>
}
