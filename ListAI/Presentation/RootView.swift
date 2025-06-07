import SwiftUI

struct RootView: View {
    @State private var showSplash = true
    @EnvironmentObject private var session: SessionManager
    @Environment(\.diContainer) private var di
    
    var body: some View {
        Group {
            if showSplash {
                SplashScreenView()
            } else {
                if session.isLoggedIn {
                    HomeView()
                        .environmentObject(HomeViewModel(
                            listUseCase: di.listUseCase,
                            productUseCase: di.productUseCase,
                            shoppingUseCase: di.shoppingListUseCase,
                            session: session,
                            authUseCase: di.authUseCase
                        ))
                        .environmentObject(ProfileViewModel(
                            authUseCase: di.authUseCase
                        ))
                } else {
                    AuthRouterView()
                        .environmentObject(LoginViewModel(authUseCase: di.authUseCase, session: session))
                        .environmentObject(RegisterViewModel(authUseCase: di.authUseCase, session: session))
                }
            }
        }
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                withAnimation {
                    showSplash = false
                }
            }
        }
    }
}
