import Foundation
import Combine

final class IARepositoryImpl: IARepositoryProtocol {
    
    private struct OpenRouterRequest: Encodable {
        let model: String
        let messages: [Message]
        let temperature: Double

        struct Message: Encodable {
            let role: String
            let content: String
        }
    }
    
    func getIngredients(for dish: String) -> AnyPublisher<[String], Error> {
        let url = URL(string: "https://openrouter.ai/api/v1/chat/completions")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(APIKeys.openRouterKey)", forHTTPHeaderField: "Authorization")
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")

        // Mensajes para OpenRouter
        let systemMessage = OpenRouterRequest.Message(
            role: "system",
            content: "Eres un chef profesional. Responde únicamente con los ingredientes estrictamente necesarios, uno por línea, sin cantidades ni explicaciones adicionales."
        )
        
        let userPrompt = "Indica los ingredientes necesarios para preparar \(dish). Solo nombres de ingredientes, uno por línea."
        
        let messages = [
            systemMessage,
            OpenRouterRequest.Message(role: "user", content: userPrompt)
        ]
        let body = OpenRouterRequest(model: "mistralai/mistral-7b-instruct:free", messages: messages, temperature: 0.7)

        do {
            request.httpBody = try JSONEncoder().encode(body)
            #if DEBUG
            debugPrint("📤 Cabeceras que se envían:", request.allHTTPHeaderFields ?? [:])
            if let data = request.httpBody, let json = String(data: data, encoding: .utf8) {
                debugPrint("📤 Cuerpo:", json)
            }
            #endif
        } catch {
            return Fail(error: error).eraseToAnyPublisher()
        }

        return URLSession.shared.dataTaskPublisher(for: request)
            .tryMap { data, response in
                if let httpResponse = response as? HTTPURLResponse {
                    print("🔽 OpenRouter status code: \(httpResponse.statusCode)")
                }
                if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode != 200 {
                    throw URLError(.badServerResponse)
                }

                let text = String(data: data, encoding: .utf8) ?? "<sin decodificar>"
                print("🧾 Respuesta cruda de OpenRouter:\n\(text)")

                let result = try JSONDecoder().decode(OpenRouterResponse.self, from: data)
                let rawText = result.choices.first?.message.content ?? ""
                let ingredientesLimpios: [String] = rawText
                    .components(separatedBy: CharacterSet.newlines)
                    .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
                    .filter { !$0.isEmpty }
                    .reduce(into: [String]()) { result, item in
                        if !result.contains(where: { $0.caseInsensitiveCompare(item) == .orderedSame }) {
                            result.append(item)
                        }
                    }
                return ingredientesLimpios
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
