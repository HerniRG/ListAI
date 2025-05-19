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
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    @Published var products: [ProductModel] = []
    @Published var newProductName: String = ""
    @Published var newListName: String = ""
    @Published var editingProduct: ProductModel?
    
    private let listUseCase: ListUseCaseProtocol
    private let productUseCase: ProductUseCaseProtocol
    private let iaUseCase: IAUseCaseProtocol
    private let session: SessionManager
    private var cancellables = Set<AnyCancellable>()
    
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
                self?.products = products
            }
            .store(in: &cancellables)
    }
    
    func addProductManually() {
        guard let userID = session.userID,
              let listID = activeList?.id,
              !newProductName.trimmingCharacters(in: .whitespaces).isEmpty else {
            return
        }
        
        let newProduct = ProductModel(
            id: UUID().uuidString,
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

        let newProduct = ProductModel(
            id: UUID().uuidString,
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
        if let index = products.firstIndex(where: { $0.id == product.id }) {
            products[index].esComprado.toggle()
        }
    }
    
    func useIAForProductName() {
        guard let userID = session.userID,
              let listID = activeList?.id,
              !newProductName.trimmingCharacters(in: .whitespaces).isEmpty else {
            return
        }
        
        let dish = newProductName.trimmingCharacters(in: .whitespaces)
        
        iaUseCase.getIngredients(for: dish)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] completion in
                if case let .failure(error) = completion {
                    self?.errorMessage = error.localizedDescription
                }
            } receiveValue: { [weak self] ingredients in
                let newProducts = ingredients.map {
                    ProductModel(
                        id: UUID().uuidString,
                        nombre: $0,
                        esComprado: false,
                        añadidoPorIA: true,
                        ingredientesDe: dish
                    )
                }
                
                newProducts.forEach { product in
                    self?.productUseCase.addProduct(userID: userID, listID: listID, product: product)
                        .sink(receiveCompletion: { _ in }, receiveValue: { })
                        .store(in: &self!.cancellables)
                }
                
                self?.products.append(contentsOf: newProducts)
                self?.newProductName = ""
            }
            .store(in: &cancellables)
    }
    
    func fetchIngredients(for dish: String, completion: @escaping ([String]) -> Void) {
        iaUseCase.getIngredients(for: dish)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] completionResult in
                if case let .failure(error) = completionResult {
                    self?.errorMessage = error.localizedDescription
                    completion([])
                }
            } receiveValue: { ingredientes in
                completion(ingredientes)
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
        
        listUseCase.createList(for: userID, name: newListName.trimmingCharacters(in: .whitespaces))
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
        
        listUseCase.createList(for: userID, name: nombre.trimmingCharacters(in: .whitespaces))
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
}
