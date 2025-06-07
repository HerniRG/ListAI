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
    private let shoppingUseCase: ShoppingListUseCaseProtocol
    private let session: SessionManager
    private let authUseCase: AuthUseCaseProtocol
    private var cancellables = Set<AnyCancellable>()
    
    
    // MARK: - Helpers
    
    init(listUseCase: ListUseCaseProtocol,
         productUseCase: ProductUseCaseProtocol,
         shoppingUseCase: ShoppingListUseCaseProtocol,
         session: SessionManager,
         authUseCase: AuthUseCaseProtocol) {
        self.listUseCase = listUseCase
        self.productUseCase = productUseCase
        self.shoppingUseCase = shoppingUseCase
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
        guard let listID = activeList?.id else { return }
        shoppingUseCase.addProduct(name: newProductName,
                                   to: listID,
                                   existing: products,
                                   addedByIA: false,
                                   dish: nil)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] completion in
                if case let .failure(error) = completion {
                    if let listError = error as? ShoppingListError,
                       listError == .duplicateItem {
                        self?.manualDuplicateDetected = true
                    } else {
                        self?.errorMessage = error.localizedDescription
                    }
                }
            } receiveValue: { [weak self] in
                self?.newProductName = ""
            }
            .store(in: &cancellables)
    }

    func addProduct(named name: String) {
        guard let listID = activeList?.id else { return }
        shoppingUseCase.addProduct(name: name,
                                   to: listID,
                                   existing: products,
                                   addedByIA: false,
                                   dish: nil)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] completion in
                if case let .failure(error) = completion {
                    if let listError = error as? ShoppingListError,
                       listError == .duplicateItem {
                        self?.manualDuplicateDetected = true
                    } else {
                        self?.errorMessage = error.localizedDescription
                    }
                }
            } receiveValue: { _ in }
            .store(in: &cancellables)
    }

    func toggleComprado(for product: ProductModel) {
        guard let listID = activeList?.id,
              let index = products.firstIndex(where: { $0.id == product.id }) else {
            return
        }

        let product = products[index]
        shoppingUseCase.toggleComprado(product: product, in: listID)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] completion in
                if case let .failure(error) = completion {
                    self?.errorMessage = error.localizedDescription
                }
            } receiveValue: { [weak self] updated in
                self?.products[index] = updated
            }
            .store(in: &cancellables)
    }

    func deleteProduct(_ product: ProductModel) {
        guard let listID = activeList?.id,
              let productID = product.id else { return }

        shoppingUseCase.deleteProduct(productID, from: listID)
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

        shoppingUseCase.editProduct(product, in: listID, existing: products)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] completion in
                if case let .failure(error) = completion {
                    if let listError = error as? ShoppingListError,
                       listError == .duplicateItem {
                        self?.editDuplicateDetected = true
                    } else {
                        self?.errorMessage = error.localizedDescription
                    }
                }
            } receiveValue: { [weak self] updated in
                guard let index = self?.products.firstIndex(where: { $0.id == updated.id }) else { return }
                self?.products[index] = updated
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

        shoppingUseCase.updateOrdenes(listID: listID, products: products)
            .sink(receiveCompletion: { _ in }, receiveValue: { })
            .store(in: &cancellables)
    }

    func addIngredientManually(_ nombre: String, from plato: String) {
        guard let listID = activeList?.id else { return }
        shoppingUseCase.addProduct(name: nombre,
                                   to: listID,
                                   existing: products,
                                   addedByIA: true,
                                   dish: plato)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] completion in
                if case let .failure(error) = completion {
                    self?.errorMessage = error.localizedDescription
                }
            } receiveValue: { _ in }
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
        guard let list = activeList else { return }
        shoppingUseCase.addIngredientsFromIA(for: dish,
                                             list: list,
                                             existing: products)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] completion in
                guard let self = self else { return }
                self.isUsingIA = false
                if case let .failure(error) = completion {
                    self.iaErrorMessage = error.localizedDescription
                }
            } receiveValue: { [weak self] in
                self?.newProductName = ""
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

        shoppingUseCase.fetchUniqueIngredients(for: dish,
                                               context: context,
                                               listName: listName,
                                               existing: products)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] completionResult in
                if case let .failure(error) = completionResult {
                    self?.iaErrorMessage = error.localizedDescription
                    self?.isUsingIA = false
                    completion([])
                }
            } receiveValue: { ingredientes in
                completion(ingredientes)
            }
            .store(in: &cancellables)
    }

    func analyzeActiveList() {
        guard let list = activeList else { return }
        isAnalyzing = true
        shoppingUseCase.analyzeList(list,
                                    products: products)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] completion in
                self?.isAnalyzing = false
                if case let .failure(error) = completion {
                    self?.iaErrorMessage = error.localizedDescription
                }
            } receiveValue: { [weak self] result in
                self?.analysis = result
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

