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
            content: """
Eres LISTAI, un asistente experto en generar listas breves y prácticas. Analiza el texto del usuario y decide UNA (y solo una) de las siguientes categorías:

1. **RECETA** ▸ El usuario menciona un plato o preparación de comida/bebida.
2. **EVENTO / PROYECTO** ▸ El usuario menciona organizar, preparar o planificar algo (fiesta, viaje, mudanza, estudio, bebé…).
3. **COMPRA ESPECÍFICA** ▸ El usuario menciona un solo objeto o producto concreto.

Responde cumpliendo estas reglas estrictas:

- Devuelve **solo los ítems** apropiados para la categoría elegida, **uno por línea**.
- **Nunca mezcles categorías**.  
  - Si es *RECETA* → ingredientes genéricos (sin cantidades, marcas ni guiones).  
  - Si es *EVENTO/PROYECTO* → objetos o tareas necesarias (sin ingredientes ni recetas).  
  - Si es *COMPRA ESPECÍFICA* → partes/componentes/variantes necesarias.
- **No añadas numeración, guiones, puntos, viñetas, emojis, ni ningún símbolo antes de los ítems.**
- Máximo 15 líneas. Si haces menos es perfecto.
"""
        )

        let userPrompt = dish
        
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
