import SwiftUI

enum IAContext: String, CaseIterable, Identifiable, Codable {
    case receta = "RECETA"
    case evento = "EVENTO / PROYECTO"
    case compra = "COMPRA"

    var id: String { rawValue }

    var iconName: String {
        switch self {
        case .receta:
            return "fork.knife"
        case .evento:
            return "calendar"
        case .compra:
            return "cart"
        }
    }

    static func icon(for context: IAContext) -> Image {
        Image(systemName: context.iconName)
    }
}
