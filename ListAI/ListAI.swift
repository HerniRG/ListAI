import SwiftUI

@main
struct ListAIApp: App {
    
    @StateObject private var session = SessionManager()
    
    private var container: DIContainer = {
        DIContainer(
            authRepository: AuthRepositoryImpl(),
            listRepository: ListRepositoryImpl(),
            // productRepository: ProductRepositoryImpl(),
            // iaRepository: IARepositoryImpl(),
            // historialRepository: HistorialRepositoryImpl()
        )
    }()
    
    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(session)
                .environment(\.diContainer, container)
        }
    }
}
