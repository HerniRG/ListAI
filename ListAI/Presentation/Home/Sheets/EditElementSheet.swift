import SwiftUI

struct EditElementSheet: View {
    @EnvironmentObject var viewModel: HomeViewModel
    @Binding var editedName: String
    @State private var showEditDuplicateAlert = false

    var body: some View {
        VStack(spacing: 24) {
            if let product = viewModel.editingProduct {
                // Cabecera solo texto
                Text("Editar elemento")
                    .font(.title2.bold())
                    .multilineTextAlignment(.center)
                    .padding(.top, 8)

                // Campo de texto con icono
                HStack(spacing: 12) {
                    Image(systemName: "tag")
                        .foregroundColor(.accentColor)
                    TextField("Nombre del elemento", text: $editedName)
                        .font(.body)
                }
                .padding()
                .background(Color(.secondarySystemBackground))
                .cornerRadius(12)

                // Botón principal (todo el ancho)
                Button {
                    var updated = product
                    updated.nombre = editedName
                    viewModel.editProduct(updated)
                    if !viewModel.editDuplicateDetected {
                        viewModel.editingProduct = nil
                    }
                } label: {
                    Label("Guardar cambios", systemImage: "checkmark")
                        .frame(maxWidth: .infinity, minHeight: 48)
                }
                .buttonStyle(.borderedProminent)
                .disabled(editedName.trimmingCharacters(in: .whitespaces).isEmpty)

                // Explicación breve
                Text("Modifica el nombre del elemento y guarda los cambios.")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)

                // Botón cancelar (todo el ancho, rojo)
                Button("Cancelar", role: .destructive) {
                    viewModel.editingProduct = nil
                }
                .frame(maxWidth: .infinity, minHeight: 44)
                .buttonStyle(.bordered)
                .tint(.red)
                .controlSize(.regular)
                .padding(.top, 8)
            }
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 32)
        .frame(maxWidth: 480)
        .presentationDetents([.medium])
        .presentationDragIndicator(.visible)
        .onChange(of: viewModel.editDuplicateDetected) { oldValue, newValue in
            if newValue {
                showEditDuplicateAlert = true
                viewModel.editDuplicateDetected = false
            }
        }
        .alert("Este nombre ya existe", isPresented: $showEditDuplicateAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text("Ya tienes un elemento con ese nombre en tu lista.")
        }
    }
}
