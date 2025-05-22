import SwiftUI

struct IngredientSuggestionsSheet: View {
    @EnvironmentObject var viewModel: HomeViewModel
    @Binding var showIngredientSheet: Bool
    @Binding var newProductName: String
    @Binding var ingredientesSugeridos: [String]

    var body: some View {
        NavigationView {
            VStack(spacing: 12) {
                Spacer().frame(height: 8)
                VStack(spacing: 6) {
                    Image(systemName: "sparkles")
                        .font(.system(size: 34, weight: .medium))
                        .foregroundColor(.accentColor)
                    Text("Elementos sugeridos")
                        .font(.title2.bold())
                        .foregroundColor(.primary)
                    Text("Basado en lo que escribiste")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)

                List {
                    ForEach(ingredientesSugeridos, id: \.self) { ingrediente in
                        if !ingrediente.isEmpty {
                            HStack {
                                Image(systemName: "plus.circle")
                                    .foregroundColor(.accentColor)
                                    .font(.system(size: 18, weight: .medium))
                                Text(ingrediente)
                                    .font(.body)
                                Spacer()
                            }
                            .padding(.vertical, 4)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .listRowSeparator(.hidden)
                            .contentShape(Rectangle())
                            .onTapGesture {
                                Haptic.light()
                                if let index = ingredientesSugeridos.firstIndex(of: ingrediente) {
                                    withAnimation(.easeInOut(duration: 0.2)) {
                                        ingredientesSugeridos[index] += " (añadido)"
                                    }
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                                        withAnimation {
                                            viewModel.addIngredientManually(
                                                ingrediente.replacingOccurrences(of: " (añadido)", with: ""),
                                                from: newProductName
                                            )
                                            ingredientesSugeridos.remove(at: index)
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
                .listStyle(.plain)
                .animation(.easeInOut(duration: 0.3), value: ingredientesSugeridos)
                .onChange(of: ingredientesSugeridos) { oldValue, newValue in
                    if newValue.isEmpty {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                            showIngredientSheet = false
                        }
                    }
                }
            }
            .padding(.top, 0)
            .background(Color(.systemGroupedBackground).ignoresSafeArea())
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cerrar") {
                        showIngredientSheet = false
                    }
                }
            }
        }
        .transition(.move(edge: .bottom).combined(with: .opacity))
        .presentationDetents([.large])
        .presentationDragIndicator(.visible)
    }
}
