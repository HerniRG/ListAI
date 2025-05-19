import FirebaseFirestore

struct ProductModel: Identifiable, Codable, Equatable {
    @DocumentID var id: String? // autogestionado por Firestore
    var nombre: String
    var esComprado: Bool
    var añadidoPorIA: Bool
    var ingredientesDe: String?
}
