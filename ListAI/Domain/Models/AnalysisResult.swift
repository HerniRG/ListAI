import Foundation

struct AnalysisResult: Codable, Identifiable {
    var id = UUID()
    var suggestions: [String]   // Ítems que faltan
    var tips: [String]          // Consejos breves
}
