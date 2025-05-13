import FirebaseFirestore

struct ShoppingListModel: Identifiable, Codable {
    @DocumentID var id: String?
    var nombre: String
    var fechaCreacion: Date
    var esFavorita: Bool
}
