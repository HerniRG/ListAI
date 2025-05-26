import Foundation

struct AnalysisResult: Codable, Identifiable {
    var id = UUID()
    let suggestions: [String]   // Ítems que faltan
    let tips: [String]          // Consejos breves
}
