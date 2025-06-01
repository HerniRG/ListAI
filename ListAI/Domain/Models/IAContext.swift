import SwiftUI

enum IAContext: String, CaseIterable, Identifiable, Codable {
    case receta = "RECETA"
    case evento = "EVENTO"
    case compra = "COMPRA"
    case proyecto = "PROYECTO"
    case viaje = "VIAJE"
    case ideas = "IDEAS"
    case rutina = "RUTINA"

    var id: String { rawValue }

    var iconName: String {
        switch self {
        case .receta:
            return "fork.knife"
        case .evento:
            return "calendar"
        case .compra:
            return "cart"
        case .proyecto:
            return "hammer"
        case .viaje:
            return "airplane"
        case .ideas:
            return "lightbulb"
        case .rutina:
            return "repeat"
        }
    }

    var subtitle: String {
        switch self {
        case .receta:
            return "Lista de ingredientes para preparar una receta. Sin cantidades ni marcas."
        case .evento:
            return "Prepara todo lo necesario para fiestas, celebraciones o escapadas en grupo."
        case .compra:
            return "Componentes, accesorios o artículos que necesitas comprar."
        case .proyecto:
            return "Organiza los pasos y materiales para realizar un proyecto concreto."
        case .viaje:
            return "Elementos esenciales para hacer la maleta y gestionar un viaje."
        case .ideas:
            return "Lluvia de ideas creativas para cualquier objetivo o situación."
        case .rutina:
            return "Tareas que repites con frecuencia: limpieza, mantenimiento, etc."
        }
    }

    static func icon(for context: IAContext) -> Image {
        Image(systemName: context.iconName)
    }
}
