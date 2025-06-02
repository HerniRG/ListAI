import SwiftUI

struct ShareListSheet: View {
    @Binding var isPresented: Bool
    var onShare: (String, @escaping (Result<Void, Error>) -> Void) -> Void

    @State private var email: String = ""
    @State private var errorMessage: String?

    private func isValidEmail(_ email: String) -> Bool {
        let emailRegEx = #"^[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$"#
        let predicate = NSPredicate(format:"SELF MATCHES %@", emailRegEx)
        return predicate.evaluate(with: email)
    }

    var body: some View {
        VStack(spacing: 24) {
            // Cabecera consistente con el resto de sheets
            Text("Compartir lista")
                .font(.title2.bold())
                .multilineTextAlignment(.center)
                .padding(.top, 8)

            // Campo correo con icono
            HStack(spacing: 12) {
                Image(systemName: "envelope")
                    .foregroundColor(.accentColor)
                TextField("Correo", text: $email)
                    .font(.body)
                    .keyboardType(.emailAddress)
                    .foregroundColor(.primary)
                    .autocapitalization(.none)
                    .disableAutocorrection(true)
            }
            .padding()
            .background(Color(.secondarySystemBackground))
            .cornerRadius(12)

            if let error = errorMessage {
                HStack(spacing: 8) {
                    Image(systemName: "xmark.octagon.fill")
                    Text(error)
                }
                .font(.footnote)
                .foregroundColor(.red)
                .multilineTextAlignment(.center)
                .transition(.opacity.combined(with: .move(edge: .top)))
            }

            // Botón principal (todo el ancho)
            Button {
                let trimmed = email.trimmingCharacters(in: .whitespacesAndNewlines)
                onShare(trimmed) { result in
                    switch result {
                    case .success:
                        isPresented = false
                    case .failure(let error):
                        withAnimation {
                            errorMessage = error.localizedDescription
                        }
                    }
                }
            } label: {
                Label("Enviar invitación", systemImage: "paperplane.fill")
                    .frame(maxWidth: .infinity, minHeight: 48)
            }
            .buttonStyle(.borderedProminent)
            .disabled(!isValidEmail(email.trimmingCharacters(in: .whitespacesAndNewlines)))

            // Explicación breve
            Text("Introduce el correo electrónico de la persona con la que quieres compartir la lista. Podrá verla y editarla.")
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)

            // Botón cancelar (todo el ancho, rojo)
            Button("Cancelar", role: .destructive) {
                isPresented = false
            }
            .frame(maxWidth: .infinity, minHeight: 44)
            .buttonStyle(.bordered)
            .controlSize(.regular)
            .tint(.red)
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 32)
        // Mismo tratamiento que otros sheets -> medium + indicador
        .presentationDetents([.medium])
        .presentationDragIndicator(.visible)
    }
}
