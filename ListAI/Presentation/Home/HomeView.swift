import SwiftUI
import UIKit
// MARK: - Haptic Feedback Helper
enum Haptic {
    static func light() {
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.impactOccurred()
    }
}

struct HomeView: View {
    @EnvironmentObject var session: SessionManager
    @EnvironmentObject var viewModel: HomeViewModel

    @State private var showAddProductSheet = false
    @State private var newProductName = ""
    @State private var showNewListSheet = false
    @State private var newListName: String = ""
    @State private var selectedPageIndex: Int = 0
    @State private var showIngredientSheet = false
    @State private var ingredientesSugeridos: [String] = []
    @State private var editedName: String = ""
    @State private var fabRotation: Double = 0
    @State private var selectedProductID: String? = nil
    @State private var showDeleteListAlert = false

    var body: some View {
        NavigationView {
            ZStack {
                Color(.systemGroupedBackground).ignoresSafeArea()
                VStack(spacing: 0) {
                    // Header
                    headerSection
                        .padding(.horizontal)
                        .padding(.top, 12)
                    
                    // Lista de listas (selector tipo “pill”)
                    if !viewModel.lists.isEmpty {
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 8) {
                                Spacer().frame(width: 8) // Padding a la izquierda
                                ForEach(viewModel.lists.indices, id: \.self) { idx in
                                    Button(action: {
                                        selectedPageIndex = idx
                                        Haptic.light()
                                        withAnimation { viewModel.activeList = viewModel.lists[idx] }
                                    }) {
                                        Text(viewModel.lists[idx].nombre)
                                            .fontWeight(selectedPageIndex == idx ? .bold : .regular)
                                            .scaleEffect(selectedPageIndex == idx ? 1.05 : 1.0)
                                            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: selectedPageIndex)
                                            .padding(.horizontal, 16)
                                            .padding(.vertical, 8)
                                            .lineLimit(1)
                                            .truncationMode(.tail)
                                            .background(
                                                Capsule()
                                                    .strokeBorder(selectedPageIndex == idx ? Color.accentColor : Color.gray.opacity(0.3), lineWidth: 2)
                                                    .background(
                                                        Capsule()
                                                            .fill(selectedPageIndex == idx ? Color.accentColor.opacity(0.15) : Color.clear)
                                                    )
                                                    .shadow(color: selectedPageIndex == idx ? Color.accentColor.opacity(0.18) : .clear, radius: 7, x: 0, y: 3)
                                            )
                                            .foregroundColor(selectedPageIndex == idx ? .accentColor : .secondary)
                                    }
                                }
                                Button(action: { showNewListSheet = true }) {
                                    Image(systemName: "plus.circle.fill")
                                        .font(.title2)
                                        .foregroundColor(.accentColor)
                                }
                                Spacer().frame(width: 8) // Padding a la derecha
                            }
                        }
                        .padding(.vertical, 10)
                        .padding(.horizontal, 4)
                        .background(.ultraThinMaterial)
                        .cornerRadius(20)
                        .padding(.bottom, 8)
                    }
                    
                    // Estado: cargando, error, vacío
                    Group {
                        if viewModel.isLoading {
                            Spacer()
                            ProgressView("Cargando tus listas…").padding()
                            Spacer()
                        } else if let error = viewModel.errorMessage {
                            Spacer()
                            Text("❌ \(error)").foregroundColor(.red)
                            Spacer()
                        } else if viewModel.lists.isEmpty {
                            emptyState
                            Spacer()
                        } else {
                            productListSection(for: viewModel.lists[selectedPageIndex])
                                .transition(.asymmetric(
                                    insertion: .opacity.combined(with: .scale(scale: 0.95)),
                                    removal: .opacity.combined(with: .scale(scale: 1.05))
                                ))
                                .animation(.easeInOut(duration: 0.25), value: selectedPageIndex)
                        }
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                }

                // Floating action button (Añadir producto)
                if !viewModel.lists.isEmpty {
                    VStack {
                        Spacer()
                        HStack {
                            Spacer()
                            addProductButton
                                .padding(.bottom, 24)
                                .padding(.trailing, 16)
                        }
                    }
                    .transition(.scale)
                }
            }
            .sheet(isPresented: $showIngredientSheet, content: { ingredientSheet })
            .sheet(item: $viewModel.editingProduct) { _ in editSheet }
            .sheet(isPresented: $showNewListSheet) { newListSheet }
            .navigationBarHidden(true)
        }
        .alert("¿Eliminar esta lista?", isPresented: $showDeleteListAlert) {
            Button("Eliminar", role: .destructive) {
                viewModel.deleteCurrentList()
                withAnimation {
                    if !viewModel.lists.isEmpty {
                        selectedPageIndex = 0
                    }
                }
            }
            Button("Cancelar", role: .cancel) { }
        } message: {
            Text("Esta acción eliminará la lista y todos sus productos.")
        }
    }

    // MARK: - Header
    private var headerSection: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text("ListAI").font(.largeTitle.bold())
                Text("Organiza tus compras de forma inteligente")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            Spacer()
            ProfileIconView() // Crea un pequeño componente para el avatar/perfil
        }
    }

    // MARK: - Lista de productos con tarjetas y swipe actions NATIVOS
    private func productListSection(for list: ShoppingListModel) -> some View {
        VStack(spacing: 0) {
            HStack {
                Text("📝 \(list.nombre)")
                    .font(.title3)
                    .fontWeight(.bold)
                Spacer()
                Text("Productos: \(viewModel.products.count)")
                    .font(.caption)
                    .foregroundColor(.secondary)

                Menu {
                    Button(role: .destructive) {
                        showDeleteListAlert = true
                    } label: {
                        Label("Eliminar lista", systemImage: "trash")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                        .font(.title3)
                        .foregroundColor(.secondary)
                        .padding(.leading, 4)
                }
            }
            .padding(.horizontal, 12)
            .padding(.top, 8)

            if viewModel.products.isEmpty {
                Spacer()
                VStack(spacing: 16) {
                    Image(systemName: "cart")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 70, height: 70)
                        .foregroundColor(.accentColor.opacity(0.3))
                    Text("Tu lista está vacía").font(.headline)
                }
                Spacer()
            } else {
                List {
                    ForEach(viewModel.products) { product in
                        HStack(spacing: 16) {
                            Button(action: {
                                withAnimation(.spring()) {
                                    viewModel.toggleComprado(for: product)
                                }
                                Haptic.light()
                            }) {
                                Image(systemName: product.esComprado ? "checkmark.circle.fill" : "circle")
                                    .font(.title2)
                                    .foregroundColor(product.esComprado ? .green : .gray.opacity(0.6))
                                    .scaleEffect(product.esComprado ? 1.1 : 1)
                            }
                            .buttonStyle(.plain)

                            VStack(alignment: .leading, spacing: 2) {
                                Text(product.nombre)
                                    .font(.body)
                                    .strikethrough(product.esComprado, color: .gray)
                                    .foregroundColor(product.esComprado ? .gray : .primary)
                                    .animation(.easeInOut, value: product.esComprado)
                            }
                            Spacer()
                        }
                        .padding(.vertical, 10)
                        .listRowSeparator(.hidden)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(selectedProductID == product.id ? Color.accentColor.opacity(0.08) : Color.clear)
                        )
                        .onTapGesture {
                            withAnimation(.easeInOut(duration: 0.12)) {
                                selectedProductID = product.id
                            }
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.18) {
                                withAnimation { selectedProductID = nil }
                            }
                        }
                        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                            Button(role: .destructive) {
                                withAnimation { viewModel.deleteProduct(product) }
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
                        .transition(.asymmetric(
                            insertion: .scale.combined(with: .opacity),
                            removal: .scale(scale: 0.9).combined(with: .opacity)
                        ))
                    }
                    .onDelete { indices in
                        indices.map { viewModel.products[$0] }.forEach { product in
                            withAnimation { viewModel.deleteProduct(product) }
                        }
                    }
                }
                .listStyle(.plain)
                .padding(.top, 8)
                .padding(.bottom, 4)
                .animation(.spring(response: 0.4, dampingFraction: 0.75), value: viewModel.products)
            }
        }
        .padding(.horizontal, 2)
        .frame(maxHeight: .infinity)
    }

    // MARK: - Card para producto (con swipe actions)
    private func productCard(_ product: ProductModel) -> some View {
        HStack(spacing: 16) {
            Button(action: { viewModel.toggleComprado(for: product) }) {
                Image(systemName: product.esComprado ? "checkmark.circle.fill" : "circle")
                    .font(.title2)
                    .foregroundColor(product.esComprado ? .green : .gray.opacity(0.6))
                    .scaleEffect(product.esComprado ? 1.12 : 1)
                    .animation(.spring(), value: product.esComprado)
            }
            .buttonStyle(.plain)

            VStack(alignment: .leading, spacing: 2) {
                Text(product.nombre)
                    .font(.body)
                    .strikethrough(product.esComprado, color: .gray)
                    .foregroundColor(product.esComprado ? .gray : .primary)
            }

            Spacer()
        }
        .padding()
        .background(Color.white)
        .cornerRadius(18)
        .shadow(color: .black.opacity(0.04), radius: 4, x: 0, y: 2)
        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
            Button(role: .destructive) { viewModel.deleteProduct(product) } label: {
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

    // MARK: - Botón flotante para añadir producto
    private var addProductButton: some View {
        Button {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.5)) {
                fabRotation += 90
            }
            Haptic.light()
            showAddProductSheet = true
        } label: {
            ZStack {
                Circle()
                    .fill(Color.accentColor)
                    .frame(width: 56, height: 56)
                    .shadow(color: .accentColor.opacity(0.16), radius: 8, x: 0, y: 4)
                Image(systemName: "plus")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundColor(.white)
                    .rotationEffect(.degrees(fabRotation))
                    .animation(.spring(response: 0.3, dampingFraction: 0.5), value: fabRotation)
            }
        }
        .accessibilityLabel("Añadir producto o plato")
        .sheet(isPresented: $showAddProductSheet) {
            addProductSheet
        }
    }
    // MARK: - Sheet para añadir producto
    private var addProductSheet: some View {
        VStack(spacing: 32) {
            Text("Añadir producto o plato")
                .font(.title2.bold())
                .multilineTextAlignment(.center)
            HStack(spacing: 16) {
                Image(systemName: "tag")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 28, height: 28)
                    .foregroundColor(.accentColor)
                TextField("Nombre del producto o plato", text: $newProductName)
                    .font(.title3)
            }
            .padding(18)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(Color(.secondarySystemBackground))
            )
            .frame(maxWidth: .infinity)

            HStack(spacing: 16) {
                Button {
                    viewModel.addProduct(named: newProductName)
                    newProductName = ""
                    showAddProductSheet = false
                } label: {
                    Label("Añadir manualmente", systemImage: "plus")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .disabled(newProductName.trimmingCharacters(in: .whitespaces).isEmpty)

                Button {
                    viewModel.fetchIngredients(for: newProductName) { ingredientes in
                        withAnimation {
                            self.ingredientesSugeridos = ingredientes
                            self.showIngredientSheet = true
                            self.showAddProductSheet = false
                        }
                    }
                } label: {
                    Label("Usar IA", systemImage: "wand.and.stars")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .tint(.gray)
                .disabled(newProductName.trimmingCharacters(in: .whitespaces).isEmpty)
            }
            .frame(maxWidth: .infinity)

            Button("Cancelar", role: .cancel) {
                showAddProductSheet = false
                newProductName = ""
            }
            .frame(maxWidth: .infinity)
            .buttonStyle(.bordered)
            .padding(.top, 4)
        }
        .padding(.horizontal, 28)
        .padding(.vertical, 32)
        .frame(maxWidth: 480)
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
    }

    // MARK: - Empty State
    private var emptyState: some View {
        VStack(spacing: 24) {
            Image(systemName: "rectangle.stack.badge.plus")
                .resizable()
                .scaledToFit()
                .frame(width: 72, height: 72)
                .foregroundColor(.accentColor.opacity(0.3))
            Text("No tienes listas todavía").font(.title3.bold())
            Button("Crear primera lista") { showNewListSheet = true }
                .buttonStyle(.borderedProminent)
        }
        .padding(.top, 60)
    }

    // MARK: - Sheet nueva lista
    private var newListSheet: some View {
        VStack(spacing: 32) {
            Text("Crear nueva lista")
                .font(.title2.bold())
                .multilineTextAlignment(.center)
            HStack(spacing: 16) {
                Image(systemName: "list.bullet.rectangle")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 28, height: 28)
                    .foregroundColor(.accentColor)
                TextField("Nombre de la lista", text: $newListName)
                    .font(.title3)
            }
            .padding(18)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(Color(.secondarySystemBackground))
            )
            .frame(maxWidth: .infinity)
            HStack(spacing: 16) {
                Button {
                    viewModel.addNewList(nombre: newListName)
                    newListName = ""
                    showNewListSheet = false
                } label: {
                    Label("Crear lista", systemImage: "plus")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .disabled(newListName.trimmingCharacters(in: .whitespaces).isEmpty)
                Button("Cancelar", role: .cancel) {
                    showNewListSheet = false
                    newListName = ""
                }
                .frame(maxWidth: .infinity)
                .buttonStyle(.bordered)
            }
            .frame(maxWidth: .infinity)
        }
        .padding(.horizontal, 28)
        .padding(.vertical, 32)
        .frame(maxWidth: 480)
        .presentationDetents([.medium])
        .presentationDragIndicator(.visible)
    }

    // MARK: - Sheet ingredientes sugeridos
    private var ingredientSheet: some View {
        NavigationView {
            VStack(spacing: 18) {
                // Cabecera con icono
                HStack(spacing: 14) {
                    Image(systemName: "wand.and.stars")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 32, height: 32)
                        .foregroundColor(.accentColor)
                    Text("Ingredientes sugeridos")
                        .font(.title2.weight(.bold))
                        .foregroundColor(.primary)
                }
                .frame(maxWidth: .infinity)
                .padding(.top, 16)
                List {
                    ForEach(ingredientesSugeridos, id: \.self) { ingrediente in
                        Button(action: {
                            viewModel.addIngredientManually(ingrediente, from: viewModel.newProductName)
                        }) {
                            HStack {
                                Text(ingrediente)
                                    .font(.body)
                                Spacer()
                                Image(systemName: "plus.circle.fill")
                                    .font(.title2)
                                    .foregroundColor(.accentColor)
                            }
                            .padding(.vertical, 8)
                            .frame(maxWidth: .infinity, alignment: .leading)
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(Color.accentColor.opacity(0.13))
                        .listRowInsets(EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0))
                    }
                }
                .listStyle(.insetGrouped)
                .padding(.top, 8)
                .animation(.easeInOut, value: ingredientesSugeridos)
            }
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cerrar") { showIngredientSheet = false }
                }
            }
        }
        .transition(.move(edge: .bottom).combined(with: .opacity))
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
    }

    // MARK: - Sheet editar producto
    private var editSheet: some View {
        VStack(spacing: 32) {
            if let product = viewModel.editingProduct {
                Text("Editar producto")
                    .font(.title2.bold())
                    .multilineTextAlignment(.center)
                HStack(spacing: 16) {
                    Image(systemName: "pencil")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 28, height: 28)
                        .foregroundColor(.accentColor)
                    TextField("Nombre del producto", text: $editedName)
                        .font(.title3)
                }
                .padding(18)
                .background(
                    RoundedRectangle(cornerRadius: 14)
                        .fill(Color(.secondarySystemBackground))
                )
                .frame(maxWidth: .infinity)
                HStack(spacing: 16) {
                    Button("Guardar") {
                        var updated = product
                        updated.nombre = editedName
                        viewModel.editProduct(updated)
                        viewModel.editingProduct = nil
                    }
                    .frame(maxWidth: .infinity)
                    .buttonStyle(.borderedProminent)
                    .disabled(editedName.trimmingCharacters(in: .whitespaces).isEmpty)
                    Button("Cancelar", role: .cancel) {
                        viewModel.editingProduct = nil
                    }
                    .frame(maxWidth: .infinity)
                    .buttonStyle(.bordered)
                }
                .frame(maxWidth: .infinity)
            }
        }
        .padding(.horizontal, 28)
        .padding(.vertical, 32)
        .frame(maxWidth: 480)
        .presentationDetents([.medium])
        .presentationDragIndicator(.visible)
    }
}

// Puedes crear este pequeño componente para el avatar
struct ProfileIconView: View {
    var body: some View {
        Image(systemName: "person.circle.fill")
            .resizable()
            .frame(width: 36, height: 36)
            .foregroundColor(.accentColor)
            .background(Circle().fill(.white).shadow(radius: 3))
            .padding(2)
            .accessibilityLabel("Perfil")
    }
}
