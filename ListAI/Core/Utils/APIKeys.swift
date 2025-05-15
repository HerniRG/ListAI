import Foundation

struct APIKeys {
    private static let _openRouterKey: String = {
        guard let filePath = Bundle.main.path(forResource: "Secrets", ofType: "plist"),
              let plist = NSDictionary(contentsOfFile: filePath),
              let value = plist["OPENROUTER_API_KEY"] as? String?
        else {
            fatalError("OPENROUTER_API_KEY no encontrada en Secrets.plist")
        }
        let trimmed = value?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        assert(!trimmed.isEmpty, "OPENROUTER_API_KEY está vacía")
        return trimmed
    }()

    static var openRouterKey: String { _openRouterKey }
}
