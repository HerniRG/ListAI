import Foundation
import Combine

final class HomeViewModel: ObservableObject {
    
    @Published var activeList: ShoppingListModel? {
        didSet {
            guard
                let listID = activeList?.id,
                let userID = session.userID
            else { return }
            loadProducts(userID: userID, listID: listID)
        }
    }
    @Published var lists: [ShoppingListModel] = []
    @Published var selectedContextForNewList: IAContext = .receta
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
    
    private let listUseCase: ListUseCaseProtocol
    private let productUseCase: ProductUseCaseProtocol
    private let iaUseCase: IAUseCaseProtocol
    private let session: SessionManager
    private var cancellables = Set<AnyCancellable>()
    
    private func isDuplicate(_ name: String) -> Bool {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        return products.contains {
            $0.nombre.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() == trimmed
        }
    }

    private func isDuplicate(_ name: String, excluding productID: String?) -> Bool {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        return products.contains {
            guard $0.id != productID else { return false }
            return $0.nombre.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() == trimmed
        }
    }
    
    init(listUseCase: ListUseCaseProtocol, productUseCase: ProductUseCaseProtocol, iaUseCase: IAUseCaseProtocol, session: SessionManager) {
        self.listUseCase = listUseCase
        self.productUseCase = productUseCase
        self.iaUseCase = iaUseCase
        self.session = session
        loadLists()
    }
    
    func loadLists() {
        guard let userID = session.userID else {
            errorMessage = "Usuario no encontrado"
            return
        }
        
        isLoading = true
        listUseCase.fetchLists(for: userID)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] completion in
                self?.isLoading = false
                if case let .failure(error) = completion {
                    self?.errorMessage = error.localizedDescription
                }
            } receiveValue: { [weak self] lists in
                self?.lists = lists
                self?.activeList = lists.first      // didSet se encargará de cargar los productos
            }
            .store(in: &cancellables)
    }
    
    private func loadProducts(userID: String, listID: String) {
        productUseCase.getProducts(userID: userID, listID: listID)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] completion in
                if case let .failure(error) = completion {
                    self?.errorMessage = error.localizedDescription
                }
            } receiveValue: { [weak self] products in
                self?.products = products.sorted(by: { ($0.orden ?? 0) < ($1.orden ?? 0) })
            }
            .store(in: &cancellables)
    }
    
    func addProductManually() {
        guard let userID = session.userID,
              let listID = activeList?.id,
              !newProductName.trimmingCharacters(in: .whitespaces).isEmpty else {
            return
        }
        
        let nextOrden: Int
        if products.isEmpty {
            nextOrden = 0
        } else {
            nextOrden = (products.map { $0.orden ?? 0 }.max() ?? (products.count - 1)) + 1
        }
        
        let newProduct = ProductModel(
            id: UUID().uuidString,
            orden: nextOrden,
            nombre: newProductName.trimmingCharacters(in: .whitespaces),
            esComprado: false,
            añadidoPorIA: false,
            ingredientesDe: nil
        )
        
        productUseCase.addProduct(userID: userID, listID: listID, product: newProduct)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] completion in
                if case let .failure(error) = completion {
                    self?.errorMessage = error.localizedDescription
                }
            } receiveValue: { [weak self] in
                self?.products.append(newProduct)
                self?.newProductName = ""
            }
            .store(in: &cancellables)
    }
    
    func addProduct(named name: String) {
        guard let userID = session.userID,
              let listID = activeList?.id,
              !name.trimmingCharacters(in: .whitespaces).isEmpty else {
            return
        }

        if isDuplicate(name) {
            manualDuplicateDetected = true
            return
        }

        let nextOrden: Int
        if products.isEmpty {
            nextOrden = 0
        } else {
            nextOrden = (products.map { $0.orden ?? 0 }.max() ?? (products.count - 1)) + 1
        }

        let newProduct = ProductModel(
            id: UUID().uuidString,
            orden: nextOrden,
            nombre: name.trimmingCharacters(in: .whitespaces),
            esComprado: false,
            añadidoPorIA: false,
            ingredientesDe: nil
        )

        productUseCase.addProduct(userID: userID, listID: listID, product: newProduct)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] completion in
                if case let .failure(error) = completion {
                    self?.errorMessage = error.localizedDescription
                }
            } receiveValue: { [weak self] in
                self?.products.append(newProduct)
            }
            .store(in: &cancellables)
    }
    
    func toggleComprado(for product: ProductModel) {
        guard let userID = session.userID,
              let listID = activeList?.id,
              let index = products.firstIndex(where: { $0.id == product.id }) else {
            return
        }

        products[index].esComprado.toggle()
        let updatedProduct = products[index]

        // Actualiza el producto en la base de datos
        productUseCase.updateProduct(userID: userID, listID: listID, product: updatedProduct)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] completion in
                if case let .failure(error) = completion {
                    self?.errorMessage = error.localizedDescription
                }
            } receiveValue: { _ in }
            .store(in: &cancellables)
    }
    
    func useIAForProductName() {
        guard let userID = session.userID,
              let listID = activeList?.id,
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
                let baseOrden = self.products.isEmpty ? 0 : (self.products.map { $0.orden ?? 0 }.max() ?? (self.products.count - 1)) + 1

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
                    self.productUseCase.addProduct(userID: userID, listID: listID, product: product)
                        .sink(receiveCompletion: { _ in }, receiveValue: { })
                        .store(in: &self.cancellables)
                }
                
                self.products.append(contentsOf: newProducts)
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
    
    func addIngredientManually(_ nombre: String, from plato: String) {
        guard let userID = session.userID,
              let listID = activeList?.id else { return }
        
        let product = ProductModel(
            id: UUID().uuidString,
            nombre: nombre,
            esComprado: false,
            añadidoPorIA: true,
            ingredientesDe: plato
        )
        
        productUseCase.addProduct(userID: userID, listID: listID, product: product)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] completion in
                if case let .failure(error) = completion {
                    self?.errorMessage = error.localizedDescription
                }
            } receiveValue: { [weak self] in
                self?.products.append(product)
            }
            .store(in: &cancellables)
    }
    
    func createInitialList() {
        guard let userID = session.userID,
              !newListName.trimmingCharacters(in: .whitespaces).isEmpty else {
            return
        }
        
        isLoading = true
        errorMessage = nil
        
        listUseCase.createList(
            for: userID,
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
                self?.lists.append(list)
                self?.activeList = list
                self?.newListName = ""
                self?.loadProducts(userID: userID, listID: list.id ?? "")
            }
            .store(in: &cancellables)
    }
    func deleteProduct(_ product: ProductModel) {
        guard let userID = session.userID,
              let listID = activeList?.id,
              let productID = product.id else { return }
        
        productUseCase.deleteProduct(userID: userID, listID: listID, productID: productID)
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
        guard let userID = session.userID,
              let listID = activeList?.id else { return }

        if isDuplicate(product.nombre, excluding: product.id) {
            editDuplicateDetected = true
            return
        }

        productUseCase.updateProduct(userID: userID, listID: listID, product: product)
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
    
    // Permite añadir listas nuevas en cualquier momento reutilizando listUseCase.createList
    func addNewList(nombre: String) {
        guard let userID = session.userID,
              !nombre.trimmingCharacters(in: .whitespaces).isEmpty else {
            return
        }
        
        listUseCase.createList(
            for: userID,
            name: nombre.trimmingCharacters(in: .whitespaces),
            context: selectedContextForNewList
        )
        .receive(on: DispatchQueue.main)
        .sink { [weak self] completion in
            if case let .failure(error) = completion {
                self?.errorMessage = error.localizedDescription
            }
        } receiveValue: { [weak self] newList in
            self?.lists.append(newList)
            self?.activeList = newList
        }
        .store(in: &cancellables)
    }
    
    
    func deleteCurrentList() {
        guard let userID = session.userID,
              let list = activeList else { return }
        guard let listID = list.id else { return }

        listUseCase.deleteList(for: userID, listID: listID)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] completion in
                if case let .failure(error) = completion {
                    self?.errorMessage = error.localizedDescription
                }
            } receiveValue: { [weak self] in
                self?.lists.removeAll { $0.id == list.id }
                self?.products = []
                self?.activeList = self?.lists.first
                // If selection needs to be handled, do it in the View, not here.
            }
            .store(in: &cancellables)
    }
    
    func moveProducts(from source: IndexSet, to destination: Int) {
        _ = source.map { products[$0] }
        products.move(fromOffsets: source, toOffset: destination)

        guard let userID = session.userID, let listID = activeList?.id else { return }

        // Guardar nuevo orden en Firebase
        for (index, product) in products.enumerated() {
            var updatedProduct = product
            updatedProduct.orden = index

            productUseCase.updateProduct(userID: userID, listID: listID, product: updatedProduct)
                .sink(receiveCompletion: { _ in }, receiveValue: { })
                .store(in: &cancellables)
        }
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
