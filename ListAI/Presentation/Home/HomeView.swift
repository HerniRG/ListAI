import SwiftUI

struct HomeView: View {
    @EnvironmentObject var session: SessionManager
    @EnvironmentObject var viewModel: HomeViewModel

    @State private var selectedPageIndex: Int = 0
    @State private var showAddProductSheet = false
    @State private var showNewListSheet = false
    @State private var showIngredientSheet = false
    @State private var showDeleteListAlert = false
    @State private var showDeleteProductAlert = false
    @State private var newProductName = ""
    @State private var newListName = ""
    @State private var editedName = ""
    @State private var ingredientesSugeridos: [String] = []
    @State private var isFetchingIngredients = false
    @State private var selectedProductID: String? = nil
    @State private var fabRotation: Double = 0

    var body: some View {
        NavigationView {
            ZStack {
                Color(.systemGroupedBackground).ignoresSafeArea()

                VStack(spacing: 0) {
                    HomeHeaderView()
                        .padding(.horizontal)
                        .padding(.top, 12)

                    ListSelectorView(
                        selectedPageIndex: $selectedPageIndex,
                        showNewListSheet: { showNewListSheet = true }
                    )

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
                            EmptyListsAnimatedView {
                                showNewListSheet = true
                            }
                            Spacer()
                        } else {
                            ProductListView(
                                list: viewModel.lists[selectedPageIndex],
                                selectedPageIndex: $selectedPageIndex,
                                selectedProductID: $selectedProductID,
                                showDeleteProductAlert: $showDeleteProductAlert,
                                showDeleteListAlert: $showDeleteListAlert,
                                editedName: $editedName
                            )
                            .transition(.opacity.combined(with: .scale(scale: 0.95)))
                        }
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                }

                if !viewModel.lists.isEmpty {
                    VStack {
                        Spacer()
                        HStack {
                            Spacer()
                            FloatingAddButton(
                                fabRotation: $fabRotation,
                                showAddProductSheet: $showAddProductSheet
                            )
                            .padding(.bottom, 24)
                            .padding(.trailing, 16)
                        }
                    }
                    .transition(.scale)
                }
            }
            .sheet(isPresented: $showAddProductSheet) {
                AddElementSheet(
                    isPresented: $showAddProductSheet,
                    newProductName: $newProductName,
                    showIngredientSheet: $showIngredientSheet,
                    ingredientesSugeridos: $ingredientesSugeridos,
                    isFetchingIngredients: $isFetchingIngredients
                )
                .environmentObject(viewModel)
                .environmentObject(session)
            }
            .sheet(isPresented: $showIngredientSheet) {
                IngredientSuggestionsSheet(
                    showIngredientSheet: $showIngredientSheet,
                    newProductName: $newProductName,
                    ingredientesSugeridos: $ingredientesSugeridos
                )
                .environmentObject(viewModel)
            }
            .sheet(item: $viewModel.editingProduct) { _ in
                EditElementSheet(editedName: $editedName)
                    .environmentObject(viewModel)
                    .environmentObject(session)
            }
            .sheet(isPresented: $showNewListSheet) {
                NewListSheet(
                    showNewListSheet: $showNewListSheet,
                    newListName: $newListName
                )
                .environmentObject(viewModel)
            }
            .navigationBarHidden(true)
        }
        .onChange(of: viewModel.iaErrorMessage) { oldValue, newValue in
            if newValue != nil {
                showAddProductSheet = false
                showIngredientSheet = false
            }
        }
        .alert("Error al obtener sugerencias", isPresented: Binding<Bool>(
            get: { viewModel.iaErrorMessage != nil },
            set: { _ in viewModel.iaErrorMessage = nil }
        )) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(viewModel.iaErrorMessage ?? "Ha ocurrido un error al obtener las sugerencias.")
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
            Button("Cancelar", role: .cancel) {}
        } message: {
            Text("Esta acción eliminará la lista y todos sus elementos.")
        }
        .alert("¿Eliminar este elemento?", isPresented: $showDeleteProductAlert) {
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
            Text("Esta acción eliminará el elemento de tu lista.")
        }
    }
}

struct EmptyListsAnimatedView: View {
    @State private var appear = false
    let onCreate: () -> Void

    var body: some View {
        VStack(spacing: 24) {
            Image(systemName: "rectangle.stack.badge.plus")
                .resizable()
                .scaledToFit()
                .frame(width: 72, height: 72)
                .foregroundColor(.accentColor.opacity(0.3))
                .scaleEffect(appear ? 1 : 0.8)
                .opacity(appear ? 1 : 0)
                .animation(.spring(response: 0.5, dampingFraction: 0.6), value: appear)
            Text("No tienes listas todavía")
                .font(.title3.bold())
                .scaleEffect(appear ? 1 : 0.8)
                .opacity(appear ? 1 : 0)
                .animation(.spring(response: 0.7, dampingFraction: 0.7).delay(0.07), value: appear)
            Button("Crear primera lista") {
                onCreate()
            }
            .buttonStyle(.borderedProminent)
            .scaleEffect(appear ? 1 : 0.9)
            .opacity(appear ? 1 : 0)
            .animation(.spring(response: 0.8, dampingFraction: 0.7).delay(0.13), value: appear)
        }
        .padding(.top, 60)
        .onAppear { appear = true }
        .onDisappear { appear = false }
    }
}
