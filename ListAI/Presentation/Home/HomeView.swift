import SwiftUI

struct HomeView: View {
    @EnvironmentObject var session: SessionManager
    @EnvironmentObject var viewModel: HomeViewModel
    
    @State private var ingredientesSugeridos: [String] = []
    @State private var showIngredientSheet = false
    @State private var editedName: String = ""
    @State private var showNewListSheet = false
    @State private var newListName: String = ""
    @State private var selectedPageIndex: Int = 0

    var body: some View {
        NavigationView {
            content
                .padding(.horizontal)
                .toolbar {
                    ToolbarItem(placement: .principal) {
                        Text("ListAI")
                            .font(.headline)
                    }
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button(action: {
                            showNewListSheet = true
                        }) {
                            Image(systemName: "plus")
                        }
                    }
                }
                .animation(.easeInOut, value: showIngredientSheet)
        }
        .sheet(isPresented: $showIngredientSheet, content: {
            ingredientSheet
        })
        .sheet(item: $viewModel.editingProduct) { _ in
            editSheet
        }
        .sheet(isPresented: $showNewListSheet) {
            VStack(spacing: 16) {
                Text("Nueva lista").font(.title2.bold())
                TextField("Nombre de la lista", text: $newListName)
                    .textFieldStyle(.roundedBorder)
                Button("Crear") {
                    viewModel.addNewList(nombre: newListName)
                    newListName = ""
                    showNewListSheet = false
                }
                .buttonStyle(.borderedProminent)
                .disabled(newListName.trimmingCharacters(in: .whitespaces).isEmpty)

                Button("Cancelar", role: .cancel) {
                    showNewListSheet = false
                    newListName = ""
                }
                .buttonStyle(.bordered)
            }
            .padding()
        }
    }

    private var content: some View {
        VStack(spacing: 0) {
            if viewModel.isLoading {
                ProgressView("Cargando listas...")
            } else if let error = viewModel.errorMessage {
                Text("❌ \(error)").foregroundColor(.red)
            } else if viewModel.lists.isEmpty {
                emptyState
                    .frame(maxHeight: .infinity)
            } else {
                TabView(selection: $selectedPageIndex) {
                    ForEach(Array(viewModel.lists.enumerated()), id: \.element.id) { index, list in
                        listSection(for: list)
                            .tag(index)
                            .padding(.horizontal)
                    }

                    // Página final con "+" para añadir nueva lista
                    VStack {
                        Button {
                            showNewListSheet = true
                        } label: {
                            VStack(spacing: 12) {
                                Image(systemName: "plus.circle.fill")
                                    .resizable()
                                    .frame(width: 50, height: 50)
                                    .foregroundColor(.accentColor)
                                Text("Crear nueva lista")
                                    .font(.headline)
                            }
                        }
                    }
                    .tag(viewModel.lists.count)
                }
                .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
                .frame(maxHeight: .infinity)
                .onChange(of: selectedPageIndex) { oldIndex, newIndex in
                    if newIndex < viewModel.lists.count {
                        viewModel.activeList = viewModel.lists[newIndex]
                    }
                }

                HStack(spacing: 8) {
                    ForEach(0..<(viewModel.lists.count + 1), id: \.self) { index in
                        if index == viewModel.lists.count {
                            Image(systemName: "plus")
                                .resizable()
                                .frame(width: 8, height: 8)
                                .foregroundColor(index == selectedPageIndex ? Color.accentColor : Color.gray.opacity(0.4))
                        } else {
                            Circle()
                                .fill(index == selectedPageIndex ? Color.accentColor : Color.gray.opacity(0.4))
                                .frame(width: 8, height: 8)
                        }
                    }
                }
                .padding(.vertical, 8)
            }
        }
        .frame(maxHeight: .infinity, alignment: .top)
    }

    private func listSection(for list: ShoppingListModel) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("📝 Lista: \(list.nombre)")
                .font(.title2.bold())

            List {
                if viewModel.products.isEmpty {
                    Text("Tu lista está vacía")
                        .foregroundColor(.gray)
                } else {
                    ForEach(viewModel.products) { product in
                        HStack {
                            Button(action: {
                                viewModel.toggleComprado(for: product)
                            }) {
                                Image(systemName: product.esComprado ? "checkmark.circle.fill" : "circle")
                                    .foregroundColor(product.esComprado ? .green : .gray)
                            }

                            Text(product.nombre)
                                .foregroundColor(product.esComprado ? .gray : .primary)
                        }
                        .swipeActions(edge: .trailing) {
                            Button(role: .destructive) {
                                viewModel.deleteProduct(product)
                            } label: {
                                Label("Eliminar", systemImage: "trash")
                            }

                            Button {
                                editedName = product.nombre
                                viewModel.editingProduct = product
                            } label: {
                                Label("Editar", systemImage: "pencil")
                            }
                            .tint(.blue)
                        }
                    }
                }
            }
        

            Spacer()

            HStack {
                TextField("Añadir producto o plato", text: $viewModel.newProductName)
                    .textFieldStyle(RoundedBorderTextFieldStyle())

                Button {
                    let dish = viewModel.newProductName.trimmingCharacters(in: .whitespaces)
                    viewModel.fetchIngredients(for: dish) { ingredientes in
                        withAnimation {
                            self.ingredientesSugeridos = ingredientes
                            self.showIngredientSheet = true
                        }
                    }
                } label: {
                    Label("Usar IA", systemImage: "wand.and.stars")
                }
                .disabled(viewModel.newProductName.trimmingCharacters(in: .whitespaces).isEmpty)
                .buttonStyle(.borderedProminent)
            }

            Button {
                viewModel.addProductManually()
            } label: {
                Label("Añadir", systemImage: "plus")
            }
            .buttonStyle(.borderedProminent)
        }
        .frame(maxHeight: .infinity, alignment: .top)
        .padding(.bottom, 16)
    }

    private var emptyState: some View {
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

    private var ingredientSheet: some View {
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
    }

    private var editSheet: some View {
        VStack(spacing: 16) {
            if let product = viewModel.editingProduct {

                Text("Editar producto").font(.headline)

                TextField("Nombre del producto", text: $editedName)
                    .textFieldStyle(.roundedBorder)

                Button("Guardar") {
                    var updated = product
                    updated.nombre = editedName
                    viewModel.editProduct(updated)
                    viewModel.editingProduct = nil
                }
                .buttonStyle(.borderedProminent)
                .frame(maxWidth: .infinity)

                Button("Cancelar", role: .cancel) {
                    viewModel.editingProduct = nil
                }
                .buttonStyle(.bordered)
                .frame(maxWidth: .infinity)

            } else {
                Text("No hay producto seleccionado.")
                    .foregroundColor(.gray)
            }
        }
        .padding()
    }
}
