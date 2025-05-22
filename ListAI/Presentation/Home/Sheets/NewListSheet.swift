import SwiftUI

struct NewListSheet: View {
    @EnvironmentObject var viewModel: HomeViewModel
    @Binding var showNewListSheet: Bool
    @Binding var newListName: String

    var body: some View {
        VStack(spacing: 24) {
            // Cabecera solo texto, sin icono grande
            Text("Crear nueva lista")
                .font(.title2.bold())
                .multilineTextAlignment(.center)
                .padding(.top, 8)

            // Campo con icono
            HStack(spacing: 12) {
                Image(systemName: "list.bullet.rectangle")
                    .foregroundColor(.accentColor)
                TextField("Nombre de la lista", text: $newListName)
                    .font(.body)
                    .textInputAutocapitalization(.sentences)
            }
            .padding()
            .background(Color(.secondarySystemBackground))
            .cornerRadius(12)

            // Botón principal (todo el ancho)
            Button {
                viewModel.addNewList(nombre: newListName)
                newListName = ""
                showNewListSheet = false
            } label: {
                Label("Crear lista", systemImage: "plus")
                    .frame(maxWidth: .infinity, minHeight: 48)
            }
            .buttonStyle(.borderedProminent)
            .disabled(newListName.trimmingCharacters(in: .whitespaces).isEmpty)

            // Explicación breve
            Text("Puedes crear listas para organizar tus ideas, compras, eventos o cualquier cosa que necesites.")
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)

            // Botón cancelar, igual ancho y separado
            Button("Cancelar", role: .destructive) {
                showNewListSheet = false
                newListName = ""
            }
            .frame(maxWidth: .infinity, minHeight: 44)
            .buttonStyle(.bordered)
            .tint(.red)
            .controlSize(.regular)
            .padding(.top, 8)
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 32)
        .presentationDetents([.medium])
        .presentationDragIndicator(.visible)
    }
}
