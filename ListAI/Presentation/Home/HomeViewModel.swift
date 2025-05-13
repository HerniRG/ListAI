import Foundation
import Combine

final class HomeViewModel: ObservableObject {
    
    @Published var activeList: ShoppingListModel?
    @Published var lists: [ShoppingListModel] = []
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    @Published var products: [ProductModel] = []
    
    private let listUseCase: ListUseCaseProtocol
    private let productUseCase: ProductUseCaseProtocol
    private let session: SessionManager
    private var cancellables = Set<AnyCancellable>()
    
    init(listUseCase: ListUseCaseProtocol, productUseCase: ProductUseCaseProtocol, session: SessionManager) {
        self.listUseCase = listUseCase
        self.productUseCase = productUseCase
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
}
