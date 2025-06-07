import Foundation
import FirebaseAuth
import Combine

final class SessionManager: ObservableObject {
    
    @Published var isLoggedIn: Bool = false
    @Published var userID: String? = nil
    
    init() {
        checkSession()
    }
    
    func checkSession() {
        if let user = Auth.auth().currentUser {
            if user.isEmailVerified {
                self.userID = user.uid
                self.isLoggedIn = true
            } else {
                try? Auth.auth().signOut()
                self.userID = nil
                self.isLoggedIn = false
            }
        } else {
            self.userID = nil
            self.isLoggedIn = false
        }
    }
    
    func signOut() {
        do {
            try Auth.auth().signOut()
            self.userID = nil
            self.isLoggedIn = false
        } catch {
            debugPrint("❌ Error al cerrar sesión: \(error.localizedDescription)")
        }
    }
}
