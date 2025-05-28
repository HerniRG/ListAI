import SwiftUI

struct ShareListSheet: View {
    @Binding var isPresented: Bool
    var onShare: (String) -> Void

    @State private var email: String = ""

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Correo del colaborador")) {
                    TextField("usuario@ejemplo.com", text: $email)
                        .keyboardType(.emailAddress)
                        .autocapitalization(.none)
                }
            }
            .navigationTitle("Compartir lista")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Enviar") {
                        onShare(email)
                    }.disabled(email.isEmpty)
                }
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancelar") { isPresented = false }
                }
            }
        }
    }
}
