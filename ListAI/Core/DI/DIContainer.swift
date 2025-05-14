import Foundation

final class DIContainer {
    
    // MARK: - Repositorios
    let authRepository: AuthRepositoryProtocol
    let listRepository: ListRepositoryProtocol
    let productRepository: ProductRepositoryProtocol
    let iaRepository: IARepositoryProtocol
    // let historialRepository: HistorialRepositoryProtocol

    // MARK: - Casos de uso
    let authUseCase: AuthUseCaseProtocol
    let listUseCase: ListUseCaseProtocol
    let productUseCase: ProductUseCaseProtocol
    let iaUseCase: IAUseCaseProtocol
    // puedes añadir los demás más adelante
    
    init(
        authRepository: AuthRepositoryProtocol,
        listRepository: ListRepositoryProtocol,
        productRepository: ProductRepositoryProtocol,
        iaRepository: IARepositoryProtocol,
        //historialRepository: HistorialRepositoryProtocol
    ) {
        self.authRepository = authRepository
        self.listRepository = listRepository
        self.productRepository = productRepository
        self.iaRepository = iaRepository
        // self.historialRepository = historialRepository
        
        // Casos de uso
        self.authUseCase = AuthUseCase(repository: authRepository)
        self.listUseCase = ListUseCase(repository: listRepository)
        self.productUseCase = ProductUseCase(repository: productRepository)
        self.iaUseCase = IAUseCase(repository: iaRepository)
    }
}

extension DIContainer {
    static let defaultValue: DIContainer = DIContainer(
        authRepository: AuthRepositoryImpl(),
        listRepository: ListRepositoryImpl(),
        productRepository: ProductRepositoryImpl(),
        iaRepository: IARepositoryImpl(),
        // historialRepository: HistorialRepositoryImpl()
    )
}
