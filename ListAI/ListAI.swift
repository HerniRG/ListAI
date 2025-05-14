import SwiftUI
import FirebaseCore


class AppDelegate: NSObject, UIApplicationDelegate {
    
    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        FirebaseApp.configure()
        print("✅ Firebase configurado correctamente desde AppDelegate")
        return true
    }
}

@main
struct ListAI: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
    @StateObject private var session = SessionManager()
    
    // Create container as a standalone property
    private let container: DIContainer = .defaultValue

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(session)
                .environment(\.diContainer, container) // Pass container to environment
        }
    }
}
