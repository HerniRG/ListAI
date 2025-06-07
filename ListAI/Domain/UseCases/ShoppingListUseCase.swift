import Foundation
import Combine

protocol ShoppingListUseCaseProtocol {
    func addProduct(name: String,
                    to listID: String,
                    existing: [ProductModel],
                    addedByIA: Bool,
                    dish: String?) -> AnyPublisher<Void, Error>

    func toggleComprado(product: ProductModel, in listID: String) -> AnyPublisher<ProductModel, Error>

    func editProduct(_ product: ProductModel,
                     in listID: String,
                     existing: [ProductModel]) -> AnyPublisher<ProductModel, Error>

    func deleteProduct(_ productID: String, from listID: String) -> AnyPublisher<Void, Error>

    func updateOrdenes(listID: String, products: [ProductModel]) -> AnyPublisher<Void, Error>

    func fetchUniqueIngredients(for dish: String,
                                context: IAContext,
                                listName: String,
                                existing: [ProductModel]) -> AnyPublisher<[String], Error>

    func addIngredientsFromIA(for dish: String,
                              list: ShoppingListModel,
                              existing: [ProductModel]) -> AnyPublisher<Void, Error>

    func analyzeList(_ list: ShoppingListModel,
                     products: [ProductModel]) -> AnyPublisher<AnalysisResult, Error>
}

enum ShoppingListError: Error {
    case duplicateItem
    case emptyName
}

final class ShoppingListUseCase: ShoppingListUseCaseProtocol {
    private let listUseCase: ListUseCaseProtocol
    private let productUseCase: ProductUseCaseProtocol
    private let iaUseCase: IAUseCaseProtocol

    init(listUseCase: ListUseCaseProtocol,
         productUseCase: ProductUseCaseProtocol,
         iaUseCase: IAUseCaseProtocol) {
        self.listUseCase = listUseCase
        self.productUseCase = productUseCase
        self.iaUseCase = iaUseCase
    }

    private func isDuplicate(_ name: String, existing: [ProductModel], excludingID: String? = nil) -> Bool {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        return existing.contains { product in
            if let excludingID = excludingID, product.id == excludingID { return false }
            return product.nombre.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() == trimmed
        }
    }

    func addProduct(name: String,
                    to listID: String,
                    existing: [ProductModel],
                    addedByIA: Bool,
                    dish: String?) -> AnyPublisher<Void, Error> {
        let trimmed = name.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return Fail(error: ShoppingListError.emptyName).eraseToAnyPublisher() }
        guard !isDuplicate(trimmed, existing: existing) else { return Fail(error: ShoppingListError.duplicateItem).eraseToAnyPublisher() }

        let nextOrden = (existing.compactMap(\.orden).max() ?? -1) + 1
        let product = ProductModel(id: UUID().uuidString,
                                   orden: nextOrden,
                                   nombre: trimmed,
                                   esComprado: false,
                                   añadidoPorIA: addedByIA,
                                   ingredientesDe: dish)
        return productUseCase.addProduct(listID: listID, product: product)
    }

    func toggleComprado(product: ProductModel, in listID: String) -> AnyPublisher<ProductModel, Error> {
        var updated = product
        updated.esComprado.toggle()
        return productUseCase.updateProduct(listID: listID, product: updated)
            .map { updated }
            .eraseToAnyPublisher()
    }

    func editProduct(_ product: ProductModel,
                     in listID: String,
                     existing: [ProductModel]) -> AnyPublisher<ProductModel, Error> {
        guard let id = product.id else { return Fail(error: ShoppingListError.emptyName).eraseToAnyPublisher() }
        guard !isDuplicate(product.nombre, existing: existing, excludingID: id) else {
            return Fail(error: ShoppingListError.duplicateItem).eraseToAnyPublisher()
        }
        return productUseCase.updateProduct(listID: listID, product: product)
            .map { product }
            .eraseToAnyPublisher()
    }

    func deleteProduct(_ productID: String, from listID: String) -> AnyPublisher<Void, Error> {
        productUseCase.deleteProduct(listID: listID, productID: productID)
    }

    func updateOrdenes(listID: String, products: [ProductModel]) -> AnyPublisher<Void, Error> {
        productUseCase.updateProductOrdenes(listID: listID, products: products)
    }

    func fetchUniqueIngredients(for dish: String,
                                context: IAContext,
                                listName: String,
                                existing: [ProductModel]) -> AnyPublisher<[String], Error> {
        iaUseCase.getIngredients(for: dish, context: context, listName: listName)
            .map { ingredients in
                ingredients.filter { !self.isDuplicate($0, existing: existing) }
            }
            .eraseToAnyPublisher()
    }

    func addIngredientsFromIA(for dish: String,
                              list: ShoppingListModel,
                              existing: [ProductModel]) -> AnyPublisher<Void, Error> {
        iaUseCase.getIngredients(for: dish, context: list.context, listName: list.nombre)
            .flatMap { [weak self] ingredients -> AnyPublisher<Void, Error> in
                guard let self = self else { return Empty().eraseToAnyPublisher() }
                let filtered = ingredients.filter { !self.isDuplicate($0, existing: existing) }
                let publishers = filtered.enumerated().map { index, name in
                    self.addProduct(name: name,
                                    to: list.id ?? "",
                                    existing: existing + filtered.prefix(index).map { element in
                                        ProductModel(id: UUID().uuidString,
                                                     orden: 0,
                                                     nombre: element,
                                                     esComprado: false,
                                                     añadidoPorIA: true,
                                                     ingredientesDe: dish)
                                    },
                                    addedByIA: true,
                                    dish: dish)
                }
                return Publishers.MergeMany(publishers)
                    .collect()
                    .map { _ in () }
                    .eraseToAnyPublisher()
            }
            .eraseToAnyPublisher()
    }

    func analyzeList(_ list: ShoppingListModel,
                     products: [ProductModel]) -> AnyPublisher<AnalysisResult, Error> {
        let pending = products.filter { !$0.esComprado }.map { $0.nombre }
        let done = products.filter { $0.esComprado }.map { $0.nombre }
        return iaUseCase.analyzeList(name: list.nombre,
                                     context: list.context,
                                     pending: pending,
                                     done: done)
            .map { [weak self] result in
                guard let self = self else { return result }
                let allNames = Set(products.map { $0.nombre.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() })
                var filtered = result
                filtered.suggestions = result.suggestions.filter {
                    !allNames.contains($0.trimmingCharacters(in: .whitespacesAndNewlines).lowercased())
                }
                return filtered
            }
            .eraseToAnyPublisher()
    }
}

