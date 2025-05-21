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
    
    @Namespace private var chipNamespace

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
    @State private var showDeleteProductAlert = false
    @State private var isFetchingIngredients = false

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
                            HStack(spacing: 14) {
                                Spacer().frame(width: 8) // Padding a la izquierda
                                ForEach(viewModel.lists.indices, id: \.self) { idx in
                                    Button(action: {
                                        selectedPageIndex = idx
                                        Haptic.light()
                                        withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                                            viewModel.activeList = viewModel.lists[idx]
                                        }
                                    }) {
                                        Text(viewModel.lists[idx].nombre)
                                            .fontWeight(selectedPageIndex == idx ? .bold : .regular)
                                            .foregroundColor(selectedPageIndex == idx ? .white : .accentColor)
                                            .padding(.horizontal, 20)
                                            .padding(.vertical, 8)
                                            .lineLimit(1)
                                            .truncationMode(.tail)
                                            .background(
                                                Group {
                                                    if selectedPageIndex == idx {
                                                        Capsule()
                                                            .fill(Color.accentColor)
                                                            .matchedGeometryEffect(id: "chip", in: chipNamespace)
                                                    } else {
                                                        Capsule()
                                                            .fill(Color.accentColor.opacity(0.12))
                                                    }
                                                }
                                            )                                    }
                                    .buttonStyle(.plain) // evita el resaltado azul de los botones por defecto
                                    .animation(.spring(response: 0.35, dampingFraction: 0.8), value: selectedPageIndex)
                                }
                                Button(action: { showNewListSheet = true }) {
                                    Image(systemName: "plus.circle.fill")
                                        .font(.title2)
                                        .foregroundColor(.accentColor)
                                }
                                Spacer().frame(width: 8) // Padding a la derecha
                            }
                        }
                        .padding(.vertical, 14)
                        //.padding(.horizontal, 8)
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
        .alert("¿Eliminar este producto?", isPresented: $showDeleteProductAlert) {
            Button("Eliminar", role: .destructive) {
                if let id = selectedProductID,
                   let product = viewModel.products.first(where: { $0.id == id }) {
                    withAnimation(.easeInOut) {
                        viewModel.deleteProduct(product)
                    }
                }
                selectedProductID = nil
            }
            Button("Cancelar", role: .cancel) {
                selectedProductID = nil
            }
        } message: {
            Text("Esta acción eliminará el producto de tu lista.")
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
        .padding(.bottom, 12)
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
            
            Group {
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
                    .transition(.opacity.combined(with: .scale))
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
                                        .onTapGesture(count: 2) {
                                            editedName = product.nombre
                                            viewModel.editingProduct = product
                                        }
                                }
                                Spacer()
                            }
                            .padding(.vertical, 10)
                            .listRowSeparator(.hidden)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color.clear)
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
                                    selectedProductID = product.id
                                    showDeleteProductAlert = true
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
                        .onMove { indices, newOffset in
                            viewModel.moveProducts(from: indices, to: newOffset)
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
                    .transition(.opacity.combined(with: .move(edge: .trailing)))
                    .environment(\.editMode, .constant(.active))
                }
            }
            .animation(.easeInOut(duration: 0.35), value: viewModel.products)
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
        .accessibilityLabel("Añadir elemento")
        .sheet(isPresented: $showAddProductSheet) {
            addProductSheet
        }
    }
    // MARK: - Sheet para añadir producto (nuevo diseño profesional)
    private var addProductSheet: some View {
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
                    showAddProductSheet = false
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
                            self.showAddProductSheet = false
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
                showAddProductSheet = false
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

    // MARK: - Sheet nueva lista (nuevo diseño profesional y homogéneo)
    private var newListSheet: some View {
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
            Text("Puedes crear listas para organizar diferentes tipos de compras.")
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

    // MARK: - Sheet ingredientes sugeridos
    private var ingredientSheet: some View {
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
                // Lista limpia, sin separadores, animada
                List {
                    ForEach(ingredientesSugeridos, id: \.self) { ingrediente in
                        if !ingrediente.isEmpty {
                            HStack {
                                Text(ingrediente)
                                    .font(.body)
                                Spacer()
                                Button {
                                    withAnimation(.spring(response: 0.45, dampingFraction: 0.8)) {
                                        viewModel.addIngredientManually(ingrediente, from: viewModel.newProductName)
                                        if let index = ingredientesSugeridos.firstIndex(of: ingrediente) {
                                            ingredientesSugeridos.remove(at: index)
                                        }
                                        Haptic.light()
                                    }
                                } label: {
                                    Image(systemName: "checkmark.circle.fill")
                                        .font(.system(size: 26, weight: .medium))
                                        .foregroundColor(.green)
                                }
                                .buttonStyle(.plain)
                                .frame(width: 44, height: 44)
                                .contentShape(Rectangle())
                            }
                            .padding(.vertical, 4)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .listRowSeparator(.hidden)
                        }
                    }
                }
                .listStyle(.plain)
                .animation(.easeInOut(duration: 0.3), value: ingredientesSugeridos)
            }
            .padding(.top, 0)
            .background(Color(.systemGroupedBackground).ignoresSafeArea())
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cerrar") { showIngredientSheet = false }
                }
            }
        }
        .transition(.move(edge: .bottom).combined(with: .opacity))
        .presentationDetents([.large])
        .presentationDragIndicator(.visible)
    }

    // MARK: - Sheet editar producto
    private var editSheet: some View {
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
                    viewModel.editingProduct = nil
                } label: {
                    Label("Guardar cambios", systemImage: "checkmark")
                        .frame(maxWidth: .infinity, minHeight: 48)
                }
                .buttonStyle(.borderedProminent)
                .disabled(editedName.trimmingCharacters(in: .whitespaces).isEmpty)
                // Explicación breve
                Text("Modifica el nombre del producto y guarda los cambios.")
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
