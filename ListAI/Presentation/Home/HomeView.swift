import SwiftUI

struct HomeView: View {
    @EnvironmentObject var session: SessionManager
    @EnvironmentObject var viewModel: HomeViewModel

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

    // Floating action buttons for HomeView
    private var floatingButtons: some View {
        VStack {
            Spacer()
            HStack {
                // Botón IA: esquina inferior izquierda
                FloatingIAButton {
                    viewModel.analyzeActiveList()
                }
                .padding(.bottom, 24)
                .padding(.leading, 16)

                Spacer()

                // Botón Añadir: esquina inferior derecha
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

    var body: some View {
        NavigationView {
            ZStack {
                Color(.systemGroupedBackground).ignoresSafeArea()

                VStack(spacing: 0) {
                    HomeHeaderView()
                        .padding(.horizontal)
                        .padding(.top, 12)

                    ListSelectorView(
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
                                list: viewModel.lists[viewModel.selectedPageIndex],
                                selectedPageIndex: $viewModel.selectedPageIndex,
                                selectedProductID: $selectedProductID,
                                showDeleteProductAlert: $showDeleteProductAlert,
                                showDeleteListAlert: $showDeleteListAlert,
                                editedName: $editedName
                            )
                            .transition(.opacity.combined(with: .scale(scale: 0.95)))
                        }
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .ignoresSafeArea(edges: .bottom)
                }

                if !viewModel.lists.isEmpty {
                    // Animación de análisis IA (nuevo efecto visual)
                    if viewModel.isAnalyzing {
                        IAThinkingOverlay()
                            .transition(.asymmetric(insertion: .scale.combined(with: .opacity), removal: .opacity))
                    }
                    floatingButtons
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
            .sheet(item: $viewModel.analysis) { result in
                AnalysisSheetView(analysis: result)
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
            .sheet(isPresented: $viewModel.isShowingShareSheet) {
                ShareListSheet(isPresented: $viewModel.isShowingShareSheet) { email in
                    viewModel.shareActiveList(withEmail: email)
                }
            }
            .onAppear {
                viewModel.startListeningToLists()
            }
            .onDisappear {
                viewModel.stopListeningToLists()
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
                guard !viewModel.lists.isEmpty else { return }
                let listID = viewModel.lists[viewModel.selectedPageIndex].id
                if let listID {
                    viewModel.deleteList(listID: listID)
                }
                withAnimation {
                    if !viewModel.lists.isEmpty {
                        viewModel.selectedPageIndex = 0
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
