import Foundation

struct APIKeys {
    static var openRouterKey: String {
        guard let filePath = Bundle.main.path(forResource: "Secrets", ofType: "plist"),
              let plist = NSDictionary(contentsOfFile: filePath),
              let value = plist["OPENROUTER_API_KEY"] as? String else {
            fatalError("API Key not found")
        }
        return value
    }
}
