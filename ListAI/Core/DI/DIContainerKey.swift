import SwiftUI

private struct DIContainerKey: EnvironmentKey {
    // Provide a safe default implementation instead of fatalError
    static let defaultValue: DIContainer = .defaultValue
}

extension EnvironmentValues {
    var diContainer: DIContainer {
        get { self[DIContainerKey.self] }
        set { self[DIContainerKey.self] = newValue }
    }
}
