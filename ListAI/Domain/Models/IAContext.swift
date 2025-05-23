enum IAContext: String, CaseIterable, Identifiable {
    case receta = "RECETA"
    case evento = "EVENTO / PROYECTO"
    case compra = "COMPRA ESPECÍFICA"
    var id: String { rawValue }
}
