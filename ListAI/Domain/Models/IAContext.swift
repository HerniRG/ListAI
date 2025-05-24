enum IAContext: String, CaseIterable, Identifiable {
    case receta = "RECETA"
    case evento = "EVENTO / PROYECTO"
    case compra = "COMPRA"
    var id: String { rawValue }
}
