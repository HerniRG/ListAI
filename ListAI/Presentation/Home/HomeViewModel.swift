import Foundation
import Combine


@MainActor
final class HomeViewModel: ObservableObject {
    private var listStreamCancellable: AnyCancellable?
    private var productStreamCancellable: AnyCancellable?
    
    @Published var activeList: ShoppingListModel? {
        didSet {
            productStreamCancellable?.cancel()
            products = []

            guard let listID = activeList?.id else { return }

            productStreamCancellable = productUseCase
                .productsStream(listID: listID)
                .receive(on: DispatchQueue.main)
                .sink { [weak self] completion in
                    if case let .failure(error) = completion {
                        self?.errorMessage = error.localizedDescription
                    }
                } receiveValue: { [weak self] products in
                    self?.products = products
                }
        }
    }
    @Published var lists: [ShoppingListModel] = [] {
        didSet {
            if selectedPageIndex >= lists.count {
                selectedPageIndex = max(0, lists.count - 1)
            }
        }
    }
    @Published var selectedContextForNewList: IAContext = .evento
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    @Published var products: [ProductModel] = []
    @Published var newProductName: String = ""
    @Published var newListName: String = ""
    @Published var editingProduct: ProductModel?
    @Published var isUsingIA: Bool = false
    @Published var iaErrorMessage: String?
    @Published var ignoredDuplicateNames: [String] = []
    @Published var manualDuplicateDetected: Bool = false
    @Published var editDuplicateDetected: Bool = false
    @Published var analysis: AnalysisResult? = nil
    @Published var isAnalyzing: Bool = false
    @Published var isShowingShareSheet = false
    @Published var listIDToShare: String?
    @Published var selectedPageIndex: Int = 0

    
    private let listUseCase: ListUseCaseProtocol
    private let productUseCase: ProductUseCaseProtocol
    private let iaUseCase: IAUseCaseProtocol
    private let session: SessionManager
    private let authUseCase: AuthUseCaseProtocol
    private var cancellables = Set<AnyCancellable>()
    private var nextOrden: Int {
        (products.compactMap(\.orden).max() ?? -1) + 1
    }
    
    // MARK: - Duplicate detection
    /// Devuelve `true` si `name` ya existe en `products`.
    /// - Parameter excludingID: Si se pasa, ignora el producto con ese ID (útil para edición).
    private func isDuplicate(_ name: String, excludingID: String? = nil) -> Bool {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        return products.contains {
            // Si se indica un ID a excluir, lo saltamos
            if let excludingID = excludingID, $0.id == excludingID { return false }
            return $0.nombre.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() == trimmed
        }
    }
    
    // MARK: - Helpers
    
    init(listUseCase: ListUseCaseProtocol,
         productUseCase: ProductUseCaseProtocol,
         iaUseCase: IAUseCaseProtocol,
         session: SessionManager,
         authUseCase: AuthUseCaseProtocol) {
        self.listUseCase = listUseCase
        self.productUseCase = productUseCase
        self.iaUseCase = iaUseCase
        self.session = session
        self.authUseCase = authUseCase
        bindLists()
    }
    
}

// MARK: - List Management
extension HomeViewModel {
    private func bindLists() {
        isLoading = true
        listStreamCancellable = listUseCase.listsStream()
            .receive(on: DispatchQueue.main)
            .sink { [weak self] completion in
                self?.isLoading = false
                if case let .failure(error) = completion {
                    self?.errorMessage = error.localizedDescription
                }
            } receiveValue: { [weak self] lists in
                self?.lists = lists
                self?.selectedPageIndex = 0
                self?.activeList = lists.first
                self?.isLoading = false             // ← deja de mostrar el spinner
            }
    }
    
    func createInitialList() {
        guard !newListName.trimmingCharacters(in: .whitespaces).isEmpty else {
            return
        }

        isLoading = true
        errorMessage = nil

        listUseCase.createList(
            name: newListName.trimmingCharacters(in: .whitespaces),
            context: selectedContextForNewList
        )
            .receive(on: DispatchQueue.main)
            .sink { [weak self] completion in
                self?.isLoading = false
                if case let .failure(error) = completion {
                    self?.errorMessage = error.localizedDescription
                }
            } receiveValue: { [weak self] list in
                self?.activeList = list          // el listener añadirá la lista al array
                self?.newListName = ""
            }
            .store(in: &cancellables)
    }

    func addNewList(nombre: String) {
        guard !nombre.trimmingCharacters(in: .whitespaces).isEmpty else {
            return
        }

        listUseCase.createList(
            name: nombre.trimmingCharacters(in: .whitespaces),
            context: selectedContextForNewList
        )
        .receive(on: DispatchQueue.main)
        .sink { [weak self] completion in
            if case let .failure(error) = completion {
                self?.errorMessage = error.localizedDescription
            }
        } receiveValue: { [weak self] newList in
            self?.activeList = newList
        }
        .store(in: &cancellables)
    }

    /// Elimina o abandona una lista concreta según el número de usuarios que la comparten.
    /// - Parameter listID: Identificador de la lista a eliminar/salir.
    func deleteList(listID: String) {
        listUseCase.deleteList(listID: listID)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] completion in
                if case let .failure(error) = completion {
                    self?.errorMessage = error.localizedDescription
                }
            } receiveValue: { [weak self] in
                guard let self = self else { return }

                // Quitamos la lista localmente
                self.lists.removeAll { $0.id == listID }

                // Si era la lista activa, detenemos el listener y limpiamos productos
                if self.activeList?.id == listID {
                    self.productStreamCancellable?.cancel()
                    self.products = []
                    self.activeList = self.lists.first
                }

                self.selectedPageIndex = min(self.selectedPageIndex, max(0, self.lists.count - 1))
            }
            .store(in: &cancellables)
    }
}

// MARK: - Product Management
extension HomeViewModel {
    func addProductManually() {
        guard let listID = activeList?.id,
              !newProductName.trimmingCharacters(in: .whitespaces).isEmpty else {
            return
        }
        let nextOrden = nextOrden

        let newProduct = ProductModel(
            id: UUID().uuidString,
            orden: nextOrden,
            nombre: newProductName.trimmingCharacters(in: .whitespaces),
            esComprado: false,
            añadidoPorIA: false,
            ingredientesDe: nil
        )

        productUseCase.addProduct(listID: listID, product: newProduct)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] completion in
                if case let .failure(error) = completion {
                    self?.errorMessage = error.localizedDescription
                }
            } receiveValue: { [weak self] in
                self?.newProductName = ""
            }
            .store(in: &cancellables)
    }

    func addProduct(named name: String) {
        guard let listID = activeList?.id,
              !name.trimmingCharacters(in: .whitespaces).isEmpty else {
            return
        }

        if isDuplicate(name) {
            manualDuplicateDetected = true
            return
        }

        let nextOrden = nextOrden

        let newProduct = ProductModel(
            id: UUID().uuidString,
            orden: nextOrden,
            nombre: name.trimmingCharacters(in: .whitespaces),
            esComprado: false,
            añadidoPorIA: false,
            ingredientesDe: nil
        )

        productUseCase.addProduct(listID: listID, product: newProduct)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] completion in
                if case let .failure(error) = completion {
                    self?.errorMessage = error.localizedDescription
                }
            } receiveValue: { _ in
            }
            .store(in: &cancellables)
    }

    func toggleComprado(for product: ProductModel) {
        guard let listID = activeList?.id,
              let index = products.firstIndex(where: { $0.id == product.id }) else {
            return
        }

        products[index].esComprado.toggle()
        let updatedProduct = products[index]

        // Actualiza el producto en la base de datos
        productUseCase.updateProduct(listID: listID, product: updatedProduct)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] completion in
                if case let .failure(error) = completion {
                    self?.errorMessage = error.localizedDescription
                }
            } receiveValue: { _ in }
            .store(in: &cancellables)
    }

    func deleteProduct(_ product: ProductModel) {
        guard let listID = activeList?.id,
              let productID = product.id else { return }

        productUseCase.deleteProduct(listID: listID, productID: productID)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] completion in
                if case let .failure(error) = completion {
                    self?.errorMessage = error.localizedDescription
                }
            } receiveValue: { [weak self] in
                self?.products.removeAll { $0.id == productID }
            }
            .store(in: &cancellables)
    }

    func editProduct(_ product: ProductModel) {
        guard let listID = activeList?.id else { return }

        if isDuplicate(product.nombre, excludingID: product.id) {
            editDuplicateDetected = true
            return
        }

        productUseCase.updateProduct(listID: listID, product: product)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] completion in
                if case let .failure(error) = completion {
                    self?.errorMessage = error.localizedDescription
                }
            } receiveValue: { [weak self] in
                guard let index = self?.products.firstIndex(where: { $0.id == product.id }) else { return }
                self?.products[index] = product
                self?.editingProduct = nil
            }
            .store(in: &cancellables)
    }

    func moveProducts(from source: IndexSet, to destination: Int) {
        products.move(fromOffsets: source, toOffset: destination)

        guard let listID = activeList?.id else { return }

        for (index, _) in products.enumerated() {
            products[index].orden = index
        }

        productUseCase.updateProductOrdenes(listID: listID, products: products)
            .sink(receiveCompletion: { _ in }, receiveValue: { })
            .store(in: &cancellables)
    }

    func addIngredientManually(_ nombre: String, from plato: String) {
        guard let listID = activeList?.id else { return }

        let product = ProductModel(
            id: UUID().uuidString,
            nombre: nombre,
            esComprado: false,
            añadidoPorIA: true,
            ingredientesDe: plato
        )

        productUseCase.addProduct(listID: listID, product: product)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] completion in
                if case let .failure(error) = completion {
                    self?.errorMessage = error.localizedDescription
                }
            } receiveValue: { _ in
            }
            .store(in: &cancellables)
    }

}

// MARK: - IA Features
extension HomeViewModel {
    func useIAForProductName() {
        guard let listID = activeList?.id,
              let context = activeList?.context,
              !newProductName.trimmingCharacters(in: .whitespaces).isEmpty else {
            return
        }

        isUsingIA = true
        iaErrorMessage = nil

        let dish = newProductName.trimmingCharacters(in: .whitespaces)

        iaUseCase.getIngredients(for: dish, context: context, listName: activeList?.nombre ?? "")
            .receive(on: DispatchQueue.main)
            .sink { [weak self] completion in
                guard let self = self else { return }
                self.isUsingIA = false
                if case let .failure(error) = completion {
                    self.iaErrorMessage = "Ocurrió un error al usar la IA: \(error.localizedDescription)"
                }
            } receiveValue: { [weak self] ingredients in
                guard let self = self else { return }
                let baseOrden = self.nextOrden

                let filtered = ingredients.filter { !self.isDuplicate($0) }
                self.ignoredDuplicateNames = ingredients.filter { self.isDuplicate($0) }

                let newProducts = filtered.enumerated().map { (index, ingredient) in
                    ProductModel(
                        id: UUID().uuidString,
                        orden: baseOrden + index,
                        nombre: ingredient,
                        esComprado: false,
                        añadidoPorIA: true,
                        ingredientesDe: dish
                    )
                }

                newProducts.forEach { product in
                    self.productUseCase.addProduct(listID: listID, product: product)
                        .sink(receiveCompletion: { _ in }, receiveValue: { })
                        .store(in: &self.cancellables)
                }

                self.newProductName = ""
            }
            .store(in: &cancellables)
    }

    func fetchIngredients(for dish: String,
                          context: IAContext,
                          completion: @escaping ([String]) -> Void) {
        
        guard let listName = activeList?.nombre else {
            iaErrorMessage = "Falta el nombre de la lista"
            completion([])
            return
        }

        iaUseCase.getIngredients(for: dish, context: context, listName: listName)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] completionResult in
                if case .failure(_) = completionResult {
                    self?.iaErrorMessage = "Ocurrió un error al usar la IA"
                    self?.isUsingIA = false
                    completion([])
                }
            } receiveValue: { [weak self] ingredientes in
                guard let self = self else {
                    completion([])
                    return
                }
                let nuevos = ingredientes.filter { !self.isDuplicate($0) }
                completion(nuevos)
            }
            .store(in: &cancellables)
    }

    func analyzeActiveList() {
        guard let list = activeList else { return }
        let pending = products.filter { !$0.esComprado }.map { $0.nombre }
        let done = products.filter { $0.esComprado }.map { $0.nombre }

        isAnalyzing = true
        iaUseCase.analyzeList(name: list.nombre,
                              context: list.context,
                              pending: pending,
                              done: done)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] completion in
                self?.isAnalyzing = false
                if case let .failure(error) = completion {
                    self?.iaErrorMessage = error.localizedDescription
                }
            } receiveValue: { [weak self] result in
                guard let self = self else { return }
                // Filter out suggestions that are already present in either pending or done
                let allNames = Set(self.products.map { $0.nombre.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() })
                let filteredSuggestions = result.suggestions.filter {
                    !allNames.contains($0.trimmingCharacters(in: .whitespacesAndNewlines).lowercased())
                }
                var filteredResult = result
                filteredResult.suggestions = filteredSuggestions
                self.analysis = filteredResult
            }
            .store(in: &cancellables)
    }
}

// MARK: - Share Features
extension HomeViewModel {
    /// Abre el sheet de compartir y guarda la lista que se va a compartir
    func presentShareSheet(for list: ShoppingListModel) {
        listIDToShare = list.id                    // guardamos el ID
        isShowingShareSheet = true                 // activamos el sheet
    }

    /// Envía la invitación a compartir la lista con el email indicado.
    /// El resultado se devuelve por completion.
    func shareActiveList(withEmail email: String, completion: @escaping (Result<Void, Error>) -> Void) {
        // Usa el ID guardado; si por algún motivo es nulo, intenta el de activeList
        guard let listID = listIDToShare ?? activeList?.id else { return }
        
        listUseCase.shareList(listID: listID, withEmail: email)
            .receive(on: DispatchQueue.main)
            .sink { completionResult in
                switch completionResult {
                case .failure(let error):
                    completion(.failure(error))
                case .finished:
                    break
                }
            } receiveValue: { _ in
                completion(.success(()))
            }
            .store(in: &cancellables)
    }
}

