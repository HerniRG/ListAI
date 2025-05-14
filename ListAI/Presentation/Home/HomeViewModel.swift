import Foundation
import Combine

final class HomeViewModel: ObservableObject {
    
    @Published var activeList: ShoppingListModel?
    @Published var lists: [ShoppingListModel] = []
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    @Published var products: [ProductModel] = []
    @Published var newProductName: String = ""
    @Published var newListName: String = ""
    
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
                self?.activeList = lists.first
                if let listID = self?.activeList?.id, let userID = self?.session.userID {
                    self?.loadProducts(userID: userID, listID: listID)
                }
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

              let group = DispatchGroup()

              newProducts.forEach { product in
                  group.enter()
                  self?.productUseCase.addProduct(userID: userID, listID: listID, product: product)
                      .sink(receiveCompletion: { _ in group.leave() },
                            receiveValue: { })
                      .store(in: &self!.cancellables)
              }

              group.notify(queue: .main) {
                  self?.products.append(contentsOf: newProducts)
                  self?.newProductName = ""
              }
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
}
