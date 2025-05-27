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
    
    func getIngredients(for dish: String,
                        context: IAContext,
                        listName: String) -> AnyPublisher<[String], Error> {
        let url = URL(string: "https://openrouter.ai/api/v1/chat/completions")!
        // Lista de modelos gratuitos que probaremos en orden
        var candidateModels = [
            "meta-llama/llama-3.3-8b-instruct:free", // rápido y disponible (mayo‑25)
            "nousresearch/nous-capybara-7b:free",     // fallback 1
            "mistralai/mistral-7b-instruct:free"      // fallback 2
        ]
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(APIKeys.openRouterKey)", forHTTPHeaderField: "Authorization")
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let contextLine = """
        CATEGORÍA: \(context.rawValue)
        NOMBRE DE LA LISTA: "\(listName)" → Este nombre aporta información sobre el contenido o el objetivo de la lista. Utilízalo como referencia para generar ítems adecuados.
        Todos los ítems deben estar redactados en español de España, evitando regionalismos latinoamericanos. Por ejemplo, “patatas” en lugar de “papas”, “zumo” en lugar de “jugo”, etc.
        """
        // Mensajes para OpenRouter
        let systemMessage = OpenRouterRequest.Message(
            role: "system",
            content: contextLine + "\n\n" + """
Eres **LISTAI**, un asistente que devuelve listas **breves, limpias y prácticas**.

### CATEGORÍAS:
1. **RECETA** → Ingredientes genéricos (sin cantidades ni marcas).
2. **EVENTO / PROYECTO** → Objetos o tareas necesarias.
3. **COMPRA** → Componentes o accesorios del producto a comprar.

### INSTRUCCIONES IMPORTANTES
• Devuelve **solo los ítems**, **uno por línea**.  
• **No incluyas** saludos, introducciones, aclaraciones ni frases resumen.  
• **Prohibido** numeración, guiones, viñetas, emojis o signos “:”, “–”, “—”, “¡”, “?”.  
• Evita verbos como *comprar*, *preparar*, *cortar*, *organizar*, *recordar*, *felicitar*, etc.  
• Usa **sustantivos simples en singular**: “Globos”, “Piñata”, “Juegos”, “Queso crema”…  
• Máximo **20 líneas**.  Menos es perfecto.

Responde solo con la lista de ítems.
"""
        )

        let userPrompt = dish
        
        let messages = [
            systemMessage,
            OpenRouterRequest.Message(role: "user", content: userPrompt)
        ]

        // Helper que genera el cuerpo con el modelo indicado
        func makeBody(model: String) -> Data? {
            let body = OpenRouterRequest(
                model: model,
                messages: messages,
                temperature: 0.5
            )
            return try? JSONEncoder().encode(body)
        }

        // Seleccionamos el primer modelo
        request.httpBody = makeBody(model: candidateModels.removeFirst())

#if DEBUG
        debugPrint("📤 Cabeceras que se envían:", request.allHTTPHeaderFields ?? [:])
        if let data = request.httpBody, let json = String(data: data, encoding: .utf8) {
            debugPrint("📤 Cuerpo:", json)
        }
#endif

        func execute(_ req: URLRequest, remaining: [String]) -> AnyPublisher<[String], Error> {
            URLSession.shared.dataTaskPublisher(for: req)
                .tryCatch { error -> AnyPublisher<(data: Data, response: URLResponse), URLError> in
                    // En caso de fallo de red, reintenta con el siguiente modelo si lo hay
                    guard let next = remaining.first else { throw error }
                    var newReq = req
                    newReq.httpBody = makeBody(model: next)
                    return URLSession.shared.dataTaskPublisher(for: newReq)
                        .eraseToAnyPublisher()
                }
                .tryMap { data, response -> [String] in
                    if let http = response as? HTTPURLResponse, http.statusCode != 200 {
                        // Si status distinto de 200 y hay modelos restantes, reintentar
                        if let next = remaining.first {
                            var newReq = req
                            newReq.httpBody = makeBody(model: next)
                            throw URLError(.badServerResponse)
                        }
                        throw URLError(.badServerResponse)
                    }
                    
                    let text = String(data: data, encoding: .utf8) ?? "<sin decodificar>"
                    print("🧾 Respuesta cruda de OpenRouter:\n\(text)")
                    
                    let result = try JSONDecoder().decode(OpenRouterResponse.self, from: data)
                    let rawText = result.choices.first?.message.content ?? ""
                    let ingredientesLimpios: [String] = rawText
                        .components(separatedBy: CharacterSet.newlines)
                        .map { line -> String in
                            var clean = line.trimmingCharacters(in: .whitespacesAndNewlines)
                            if clean.hasPrefix("-") || clean.hasPrefix("•") {
                                clean = clean.dropFirst().trimmingCharacters(in: .whitespacesAndNewlines)
                            }
                            // Elimina verbos comunes si están al comienzo
                            let verbs = ["comprar ", "preparar ", "cortar ", "organizar ", "armar ",
                                         "recordar ", "felicitar ", "alta ", "hacer "]
                            for v in verbs {
                                if clean.lowercased().hasPrefix(v) {
                                    clean = clean.dropFirst(v.count).trimmingCharacters(in: .whitespacesAndNewlines)
                                    break
                                }
                            }
                            // Descarta líneas demasiado largas (≥6 palabras) o con caracteres no deseados
                            let invalidChars = [":", "¡", "!", "?"]
                            if clean.split(separator: " ").count >= 6 { return "" }
                            if invalidChars.contains(where: { clean.contains($0) }) { return "" }
                            if clean.lowercased().contains("lista") || clean.lowercased().contains("recuerda") {
                                return ""
                            }
                            return clean.capitalized
                        }
                        .filter { !$0.isEmpty }
                        .reduce(into: [String]()) { result, item in
                            if !result.contains(where: { $0.caseInsensitiveCompare(item) == .orderedSame }) {
                                result.append(item)
                            }
                        }
                    return ingredientesLimpios
                }
                .eraseToAnyPublisher()
        }

        // Ejecutamos con fallback
        return execute(request, remaining: candidateModels)
    }
    
    func analyzeList(name: String,
                     context: IAContext,
                     pending: [String],
                     done: [String]) -> AnyPublisher<AnalysisResult, Error> {

        let pendientesTexto = pending.isEmpty
            ? "—"
            : pending.map { "- \($0)" }.joined(separator: "\n")

        let compradosTexto = done.isEmpty
            ? "—"
            : done.map { "- \($0)" }.joined(separator: "\n")

        let url = URL(string: "https://openrouter.ai/api/v1/chat/completions")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(APIKeys.openRouterKey)", forHTTPHeaderField: "Authorization")
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")

        // Construir prompt
        let prompt = """
        Eres LISTAI, un asistente experto en organización de listas.

        LISTA: "\(name)"
        TIPO: \(context.rawValue)

        PENDIENTES (no repitas ninguno):
        \(pendientesTexto)

        COMPRADOS (no repitas ninguno):
        \(compradosTexto)

        Redacta todo en español de España, evitando regionalismos como “papas” o “jugo”.

        INSTRUCCIONES
        1. Devuelve **máx. 10 ítems NUEVOS** que no aparezcan en pendientes ni comprados, **uno por línea y sin guiones**.
        2. Después añade **1–2-3 consejos breves** (≤30 palabras cada uno), **uno por línea y sin guiones**.

        FORMATO EXACTO:
        SUGERENCIAS:
        […]

        CONSEJOS:
        […]

        Añade ítems útiles y redactados en español de España. No repitas ítems. Sigue estrictamente el formato solicitado.
        """

        let messages = [
            OpenRouterRequest.Message(role: "system", content: prompt)
        ]

        let body = OpenRouterRequest(model: "meta-llama/llama-3.3-8b-instruct:free",
                                     messages: messages,
                                     temperature: 0.5)
        request.httpBody = try? JSONEncoder().encode(body)

        return URLSession.shared.dataTaskPublisher(for: request)
            .tryMap { data, response -> AnalysisResult in
                guard let http = response as? HTTPURLResponse, http.statusCode == 200 else {
                    throw URLError(.badServerResponse)
                }
                let raw = try JSONDecoder().decode(OpenRouterResponse.self, from: data)
                    .choices.first?.message.content ?? ""

                // Parsear bloques
                let parts = raw.components(separatedBy: "\n\n")
                let sug = parts.first { $0.hasPrefix("SUGERENCIAS:") }?
                    .replacingOccurrences(of: "SUGERENCIAS:", with: "")
                    .components(separatedBy: CharacterSet.newlines)
                    .map { $0.trimmingCharacters(in: .whitespacesAndNewlines).replacingOccurrences(of: "^-\\s*", with: "", options: .regularExpression) }
                    .filter { !$0.isEmpty } ?? []

                let tips: [String]
                if let consejosRaw = parts.first(where: { $0.hasPrefix("CONSEJOS:") }) {
                    tips = consejosRaw
                        .replacingOccurrences(of: "CONSEJOS:", with: "")
                        .components(separatedBy: CharacterSet.newlines)
                        .map {
                            var tip = $0.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
                            if tip.hasPrefix("-") || tip.hasPrefix("•") {
                                tip = String(tip.dropFirst()).trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
                            }
                            return tip
                        }
                        .filter { !$0.isEmpty }
                } else {
                    tips = []
                }

                return AnalysisResult(suggestions: sug, tips: tips)
            }
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
