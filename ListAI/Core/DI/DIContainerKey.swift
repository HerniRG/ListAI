import SwiftUI

private struct DIContainerKey: EnvironmentKey {
    static let defaultValue: DIContainer = {
        fatalError("DIContainer has not been set.")
    }()
}

extension EnvironmentValues {
    var diContainer: DIContainer {
        get { self[DIContainerKey.self] }
        set { self[DIContainerKey.self] = newValue }
    }
}
