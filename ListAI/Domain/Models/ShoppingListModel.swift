import FirebaseFirestore

struct ShoppingListModel: Identifiable, Codable, Hashable {
    @DocumentID var id: String?
    var nombre: String
    var fechaCreacion: Date
    var esFavorita: Bool
    /// Tipo de lista para que la IA sepa cómo actuar (receta, evento, compra…)
    var context: IAContext
}
