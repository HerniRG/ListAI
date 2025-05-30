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
            self.userID = user.uid
            self.isLoggedIn = true
        } else {
            self.isLoggedIn = false
        }
    }
    
    func signOut() {
        do {
            try Auth.auth().signOut()
            self.userID = nil
            self.isLoggedIn = false
        } catch {
            print("❌ Error al cerrar sesión: \(error.localizedDescription)")
        }
    }
}
