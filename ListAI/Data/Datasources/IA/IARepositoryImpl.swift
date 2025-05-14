

import Foundation
import Combine

final class IARepositoryImpl: IARepositoryProtocol {
    
    func getIngredients(for dish: String) -> AnyPublisher<[String], Error> {
        let url = URL(string: "https://openrouter.ai/api/v1/chat/completions")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("Bearer \(APIKeys.openRouterKey)", forHTTPHeaderField: "Authorization")
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")

        let prompt = """
        Dame solo los ingredientes necesarios, en una lista de texto plano, para preparar el plato "\(dish)". No incluyas explicaciones ni cantidades. Solo los nombres de los ingredientes.
        """

        let body: [String: Any] = [
            "model": "mistral-7b-instruct",
            "messages": [
                ["role": "user", "content": prompt]
            ],
            "temperature": 0.7
        ]

        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: body)
        } catch {
            return Fail(error: error).eraseToAnyPublisher()
        }

        return URLSession.shared.dataTaskPublisher(for: request)
            .tryMap { data, _ in
                let result = try JSONDecoder().decode(OpenRouterResponse.self, from: data)
                let rawText = result.choices.first?.message.content ?? ""
                return rawText
                    .components(separatedBy: .newlines)
                    .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
                    .filter { !$0.isEmpty }
            }
            .receive(on: DispatchQueue.main)
            .eraseToAnyPublisher()
    }
}

private struct OpenRouterResponse: Decodable {
    struct Choice: Decodable {
        struct Message: Decodable {
            let content: String
        }
        let message: Message
    }
    let choices: [Choice]
}
