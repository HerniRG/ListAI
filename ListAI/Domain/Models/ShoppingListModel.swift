import FirebaseFirestore

struct ShoppingListModel: Identifiable, Codable, Hashable {
    @DocumentID var id: String?
    var nombre: String
    var fechaCreacion: Date
    var sharedWith: [String]? // correos de usuarios con acceso compartido
    /// Tipo de lista para que la IA sepa cómo actuar (receta, evento, compra…)
    var context: IAContext
}
