import SwiftUI

struct AddElementSheet: View {
    @EnvironmentObject var viewModel: HomeViewModel
    @Binding var isPresented: Bool
    @Binding var newProductName: String
    @Binding var showIngredientSheet: Bool
    @Binding var ingredientesSugeridos: [String]
    @Binding var isFetchingIngredients: Bool
    @State private var selectedContext: IAContext? = nil
    @State private var showContextPicker: Bool = false

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
                    if !showContextPicker {
                        // Mostrar el selector de contexto
                        withAnimation(.easeInOut) {
                            showContextPicker = true
                        }
                        return
                    }

                    // Necesitamos un contexto válido para llamar a la IA
                    guard let ctx = selectedContext else { return }

                    isFetchingIngredients = true
                    let trimmedName = newProductName.trimmingCharacters(in: .whitespacesAndNewlines)
                    viewModel.fetchIngredients(for: trimmedName,
                                               context: ctx) { ingredientes in
                        self.ingredientesSugeridos = ingredientes
                        isFetchingIngredients = false
                        withAnimation {
                            self.showIngredientSheet = true
                            self.isPresented = false
                            // Reset selector
                            self.showContextPicker = false
                            self.selectedContext = nil
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
                .disabled(isFetchingIngredients ||
                          newProductName.trimmingCharacters(in: .whitespaces).isEmpty ||
                          (showContextPicker && selectedContext == nil))
            }

            if showContextPicker {
                VStack(spacing: 8) {
                    Text("Selecciona un contexto")
                        .font(.subheadline)
                        .foregroundColor(.secondary)

                    Picker("Tipo", selection: $selectedContext) {
                        ForEach(IAContext.allCases) { ctx in
                            Text(ctx.rawValue).tag(ctx as IAContext?)
                        }
                    }
                    .pickerStyle(.segmented)
                }
                .transition(.move(edge: .top).combined(with: .opacity))
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
