import SwiftUI

struct RootView: View {
    @EnvironmentObject private var session: SessionManager
    @Environment(\.diContainer) private var di
    
    var body: some View {
        Group {
            if session.isLoggedIn {
                HomeView()
                    .environmentObject(HomeViewModel(
                        listUseCase: di.listUseCase,
                        session: session
                    ))
            } else {
                AuthRouterView()
                    .environmentObject(LoginViewModel(authUseCase: di.authUseCase, session: session))
                    .environmentObject(RegisterViewModel(authUseCase: di.authUseCase, session: session))
            }
        }
    }
}
