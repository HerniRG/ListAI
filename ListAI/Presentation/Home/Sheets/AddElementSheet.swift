import SwiftUI

struct AddElementSheet: View {
    @EnvironmentObject var viewModel: HomeViewModel
    @Binding var isPresented: Bool
    @Binding var newProductName: String
    @Binding var showIngredientSheet: Bool
    @Binding var ingredientesSugeridos: [String]
    @Binding var isFetchingIngredients: Bool
    @State private var showManualDuplicateAlert = false

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
                    if !viewModel.manualDuplicateDetected {
                        newProductName = ""
                        isPresented = false
                    }
                } label: {
                    Label("Añadir", systemImage: "plus")
                        .frame(maxWidth: .infinity, minHeight: 48)
                }
                .buttonStyle(.borderedProminent)
                .disabled(newProductName.trimmingCharacters(in: .whitespaces).isEmpty)

                Button {
                    guard let ctx = viewModel.activeList?.context else { return }

                    isFetchingIngredients = true
                    let trimmedName = newProductName.trimmingCharacters(in: .whitespacesAndNewlines)
                    DispatchQueue.main.asyncAfter(deadline: .now() + 15) {
                        if isFetchingIngredients {
                            isFetchingIngredients = false
                            isPresented = false
                            viewModel.iaErrorMessage = "La IA ha tardado demasiado en responder."
                        }
                    }
                    viewModel.fetchIngredients(for: trimmedName,
                                               context: ctx) { ingredientes in
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
                .disabled(isFetchingIngredients ||
                          newProductName.trimmingCharacters(in: .whitespaces).isEmpty)
            }

            // Texto explicativo IA
            Text("La IA sugiere elementos según lo que escribas y el tipo de lista que has creado, como recetas, eventos o compras.")
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
        .onAppear {
            newProductName = ""
        }
        .onChange(of: viewModel.manualDuplicateDetected) { oldValue, newValue in
            if newValue {
                showManualDuplicateAlert = true
                viewModel.manualDuplicateDetected = false
            }
        }
        .alert("Este elemento ya existe", isPresented: $showManualDuplicateAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text("Ya tienes un elemento con ese nombre en la lista.")
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
    }
}
