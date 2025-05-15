import SwiftUI

struct HomeView: View {
    @EnvironmentObject var session: SessionManager
    @EnvironmentObject var viewModel: HomeViewModel
    
    @State private var ingredientesSugeridos: [String] = []
    @State private var showIngredientSheet = false

    var body: some View {
        NavigationView {
            VStack(alignment: .leading, spacing: 16) {
                
                if viewModel.isLoading {
                    ProgressView("Cargando lista...")
                } else if let error = viewModel.errorMessage {
                    Text("❌ \(error)").foregroundColor(.red)
                } else if let activeList = viewModel.activeList {
                    Text("📝 Lista: \(activeList.nombre)")
                        .font(.title2.bold())
                    
                    List(viewModel.products) { product in
                        HStack {
                            Text(product.nombre)
                            Spacer()
                            if product.esComprado {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(.green)
                            }
                        }
                    }

                    HStack {
                        TextField("Añadir producto o plato", text: $viewModel.newProductName)
                            .textFieldStyle(RoundedBorderTextFieldStyle())

                        Button("Usar IA") {
                            let dish = viewModel.newProductName.trimmingCharacters(in: .whitespaces)
                            viewModel.fetchIngredients(for: dish) { ingredientes in
                                withAnimation {
                                    self.ingredientesSugeridos = ingredientes
                                    self.showIngredientSheet = true
                                }
                            }
                        }
                        .disabled(viewModel.newProductName.trimmingCharacters(in: .whitespaces).isEmpty)
                        .buttonStyle(.bordered)
                    }

                    Button("Añadir") {
                        viewModel.addProductManually()
                    }
                    .buttonStyle(.borderedProminent)
                } else {
                    VStack(spacing: 16) {
                        Text("No tienes listas creadas todavía.")
                            .font(.headline)

                        TextField("Nombre de nueva lista", text: $viewModel.newListName)
                            .textFieldStyle(.roundedBorder)

                        Button("Crear lista") {
                            viewModel.createInitialList()
                        }
                        .buttonStyle(.borderedProminent)
                    }
                }
            }
            .padding()
            .navigationTitle("ListAI")
            .animation(.easeInOut, value: showIngredientSheet)
        }
        .sheet(isPresented: $showIngredientSheet, content: {
            NavigationView {
                List {
                    ForEach(ingredientesSugeridos, id: \.self) { ingrediente in
                        HStack {
                            Text(ingrediente)
                            Spacer()
                            Button(action: {
                                viewModel.addIngredientManually(ingrediente, from: viewModel.newProductName)
                            }) {
                                Image(systemName: "plus.circle.fill")
                                    .foregroundColor(.blue)
                            }
                        }
                    }
                }
                .animation(.easeInOut, value: ingredientesSugeridos)
                .navigationTitle("Ingredientes sugeridos")
            }
            .transition(.move(edge: .bottom).combined(with: .opacity))
        })
    }
}
