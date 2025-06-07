import Foundation
import Combine

final class IARepositoryImpl: IARepositoryProtocol {
    
    // MARK: - Memoria corta: últimos ítems generados por lista
    private static var recentItemsByList: [String: [String]] = [:]

    // MARK: - Clasificador muy ligero de intención
    /// Devuelve un `IAContext` si detecta palabras clave que indiquen otro contexto.
    /// Si no hay coincidencias claras, devuelve nil y se usará el contexto de la lista.
    private func inferContext(from text: String) -> IAContext? {
        let lower = text.lowercased()
        if lower.contains("receta") || lower.contains("ingrediente") || lower.contains("ingredientes") {
            return .receta
        }
        if lower.contains("viaje") || lower.contains("equipaje") || lower.contains("maleta") {
            return .viaje
        }
        if lower.contains("evento") || lower.contains("cumple") || lower.contains("fiesta") {
            return .evento
        }
        if lower.contains("rutina") || lower.contains("mantenimiento") {
            return .rutina
        }
        if lower.contains("idea") || lower.contains("brainstorm") {
            return .ideas
        }
        // Por defecto nil → se mantiene el contexto original
        return nil
    }
    
    // MARK: - Context‑specific rules
    private func rules(for context: IAContext) -> String {
        switch context {
        case .receta:
            return "Devuelve ingredientes genéricos en singular y sin cantidades. Evita marcas comerciales."
        case .evento:
            return "Incluye objetos o tareas clave para preparar el evento, sin verbos (ej. 'Globos', 'Piñata', 'Altavoces')."
        case .compra:
            return "Lista accesorios, piezas o productos concretos a comprar; un sustantivo por línea."
        case .proyecto:
            return "Enumera materiales o hitos necesarios para completar el proyecto."
        case .viaje:
            return "Indica objetos esenciales de equipaje y documentos. Sustantivos en singular."
        case .ideas:
            return "Propón ideas o conceptos breves (1‑4 palabras) en mayúscula inicial."
        case .rutina:
            return "Detalla tareas de mantenimiento o reposición que se repiten periódicamente."
        }
    }
    
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
        // Lista de modelos gratuitos que probaremos en orden (actualizado)
        var candidateModels = [
            "meta-llama/llama-3.3-70b-instruct:free", // modelo principal actualizado
            "meta-llama/llama-3.3-8b-instruct:free",  // fallback 1
            "mistralai/mistral-7b-instruct:free"      // fallback 2
        ]
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(APIKeys.openRouterKey)", forHTTPHeaderField: "Authorization")
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        
        // --- NUEVO: decidir contexto final dinámicamente
        let inferred = inferContext(from: dish)
        let finalContext = inferred ?? context
        
        let contextLine = """
        CATEGORÍA: \(finalContext.rawValue)
        NOMBRE DE LA LISTA: "\(listName)" → Este nombre aporta información sobre el contenido o el objetivo de la lista. Utilízalo como referencia para generar ítems adecuados.
        Todos los ítems deben estar redactados en español de España, evitando regionalismos latinoamericanos. Por ejemplo, “patatas” en lugar de “papas”, “zumo” en lugar de “jugo”, etc.
        """
        // Ítems generados recientemente para esta lista → evitar repeticiones
        let recent = IARepositoryImpl.recentItemsByList[listName] ?? []
        let recentLine = recent.isEmpty
            ? ""
            : "\nEVITA repetir estos ítems: " + recent.joined(separator: ", ")
        // Mensajes para OpenRouter
        let systemMessage = OpenRouterRequest.Message(
            role: "system",
            content: contextLine + recentLine + "\n\n" + """
Eres **LISTAI**, un asistente que genera listas breves, útiles y bien adaptadas al contexto.

### CONTEXTO
\(rules(for: finalContext))

### FORMATO DE RESPUESTA
• Devuelve **solo ítems útiles**, **uno por línea**.  
• **No incluyas** saludos, introducciones ni explicaciones.  
• **Evita** símbolos, numeración, guiones, emojis o frases largas.  
• Usa **sustantivos o frases muy breves** (≤3 palabras), en singular.  
• **No repitas ítems** y limita la lista a **máximo 20 líneas**.

### PENSAMIENTO INTERNO
Piensa paso a paso para encontrar los ítems óptimos, pero **NO muestres tu razonamiento**; solo devuelve la lista final.

### EJEMPLO
Entrada: "Tortilla de patatas"
Respuesta correcta:
Patatas
Huevos
Cebolla
Aceite de oliva
Sal
"""
        )

        let userPrompt = dish
        
        let messages = [
            systemMessage,
            OpenRouterRequest.Message(role: "user", content: userPrompt)
        ]

        // Ajustar temperatura según contexto
        let dynamicTemp: Double = (finalContext == .ideas ? 0.8 : 0.5)

        // Helper que genera el cuerpo con el modelo indicado
        func makeBody(model: String) -> Data? {
            let body = OpenRouterRequest(
                model: model,
                messages: messages,
                temperature: dynamicTemp
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
                    guard let next = remaining.first else { throw IAError.serviceUnavailable }
                    var newReq = req
                    newReq.httpBody = makeBody(model: next)
                    return URLSession.shared.dataTaskPublisher(for: newReq)
                        .eraseToAnyPublisher()
                }
                .tryMap { data, response -> [String] in
                    guard let http = response as? HTTPURLResponse, http.statusCode == 200 else {
                        throw IAError.serviceUnavailable
                    }
                    
                    let text = String(data: data, encoding: .utf8) ?? "<sin decodificar>"
                    debugPrint("🧾 Respuesta cruda de OpenRouter:\n\(text)")
                    
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
                    // Guardar en la memoria corta máximo 30 ítems
                    var history = IARepositoryImpl.recentItemsByList[listName] ?? []
                    history.append(contentsOf: ingredientesLimpios)
                    if history.count > 30 { history = Array(history.suffix(30)) }
                    IARepositoryImpl.recentItemsByList[listName] = history
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

        _ = pending.isEmpty
            ? "—"
            : pending.map { "- \($0)" }.joined(separator: "\n")

        _ = done.isEmpty
            ? "—"
            : done.map { "- \($0)" }.joined(separator: "\n")

        let url = URL(string: "https://openrouter.ai/api/v1/chat/completions")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(APIKeys.openRouterKey)", forHTTPHeaderField: "Authorization")
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")

        // Construir prompt
        let prompt = """
Eres **LISTAI**, un asistente experto en organización de listas en español de España.

### OBJETIVO
- Proponer hasta **10 ítems NUEVOS** que no aparezcan en pendientes ni comprados.
- Incluir **1‑3 consejos breves** para mejorar la lista o la compra.

### CONTEXTO DE LA LISTA
• Nombre: "\(name)"
• Tipo: \(context.rawValue)
• Pendientes: \(pending.isEmpty ? "—" : pending.joined(separator: ", "))
• Comprados: \(done.isEmpty ? "—" : done.joined(separator: ", "))
• Evita duplicar con: \(IARepositoryImpl.recentItemsByList[name]?.joined(separator: ", ") ?? "—")

### REGLAS SEGÚN TIPO
\(rules(for: context))

### FORMATO DE RESPUESTA
SUGERENCIAS:
<máx 10 ítems, uno por línea, sin guiones, sin numeración>

CONSEJOS:
<1‑3 frases cortas (≤30 palabras), una por línea, sin guiones>

### PENSAMIENTO INTERNO
Piensa paso a paso, pero **no muestres tu razonamiento**; entrega solo la respuesta final con la estructura exacta indicada.
"""

        let messages = [
            OpenRouterRequest.Message(role: "system", content: prompt)
        ]

        let body = OpenRouterRequest(model: "meta-llama/llama-3.3-70b-instruct:free",
                                     messages: messages,
                                     temperature: 0.5)
        request.httpBody = try? JSONEncoder().encode(body)

        return URLSession.shared.dataTaskPublisher(for: request)
            .tryMap { data, response -> AnalysisResult in
                guard let http = response as? HTTPURLResponse, http.statusCode == 200 else {
                    throw IAError.serviceUnavailable
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

enum IAError: LocalizedError {
    case serviceUnavailable

    var errorDescription: String? {
        switch self {
        case .serviceUnavailable:
            return "La inteligencia artificial no está disponible en este momento. Inténtalo más tarde."
        }
    }
}
