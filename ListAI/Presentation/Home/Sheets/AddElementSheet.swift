import SwiftUI

struct AddElementSheet: View {
    @EnvironmentObject var viewModel: HomeViewModel
    @Binding var isPresented: Bool
    @Binding var newProductName: String
    @Binding var showIngredientSheet: Bool
    @Binding var ingredientesSugeridos: [String]
    @Binding var isFetchingIngredients: Bool

    var body: some View {
        VStack(spacing: 24) {
            // Cabecera
            Text("Añadir elemento a la lista")
                .font(.title2.bold())
                .multilineTextAlignment(.center)
                .padding(.top, 8)

            // Campo de texto con icono
            HStack(spacing: 12) {
                Image(systemName: "tag")
                    .foregroundColor(.accentColor)
                TextField("Nombre del elemento", text: $newProductName)
                    .font(.body)
                    .textInputAutocapitalization(.sentences)
            }
            .padding()
            .background(Color(.secondarySystemBackground))
            .cornerRadius(12)

            // Botones alineados
            HStack(spacing: 12) {
                Button {
                    withAnimation(.spring(response: 0.45, dampingFraction: 0.8)) {
                        viewModel.addProduct(named: newProductName)
                    }
                    newProductName = ""
                    isPresented = false
                } label: {
                    Label("Añadir", systemImage: "plus")
                        .frame(maxWidth: .infinity, minHeight: 48)
                }
                .buttonStyle(.borderedProminent)
                .disabled(newProductName.trimmingCharacters(in: .whitespaces).isEmpty)

                Button {
                    isFetchingIngredients = true
                    viewModel.fetchIngredients(for: newProductName) { ingredientes in
                        self.ingredientesSugeridos = ingredientes
                        isFetchingIngredients = false
                        withAnimation {
                            self.showIngredientSheet = true
                            self.isPresented = false
                        }
                    }
                } label: {
                    if isFetchingIngredients {
                        HStack {
                            ProgressView()
                            Text("Pensando…")
                        }
                        .frame(maxWidth: .infinity, minHeight: 48)
                    } else {
                        Label("Sugerencias IA", systemImage: "sparkles")
                            .frame(maxWidth: .infinity, minHeight: 48)
                    }
                }
                .buttonStyle(.borderedProminent)
                .tint(.indigo)
                .disabled(isFetchingIngredients || newProductName.trimmingCharacters(in: .whitespaces).isEmpty)
            }

            // Texto explicativo IA
            Text("La IA sugiere elementos según lo que escribas: platos, viajes, fiestas o cualquier otra idea.")
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)

            // Botón cancelar
            Button("Cancelar", role: .destructive) {
                isPresented = false
                newProductName = ""
            }
            .frame(maxWidth: .infinity, minHeight: 44)
            .buttonStyle(.bordered)
            .tint(.red)
            .controlSize(.regular)
            .padding(.top, 8)
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 32)
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
    }
}
