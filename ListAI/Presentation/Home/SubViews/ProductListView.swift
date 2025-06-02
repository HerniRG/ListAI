import SwiftUI

struct ProductListView: View {
    let list: ShoppingListModel
    @Binding var selectedPageIndex: Int
    @Binding var selectedProductID: String?
    @Binding var showDeleteProductAlert: Bool
    @Binding var showDeleteListAlert: Bool
    @Binding var editedName: String
    
    @State private var showDeleteSelectedAlert = false

    @EnvironmentObject var viewModel: HomeViewModel

    var body: some View {
        Group {
            VStack(spacing: 0) {
            HStack {
                Text("\(list.nombre)")
                    .font(.title3)
                    .fontWeight(.bold)
                // Indicador de lista compartida
                if let shared = list.sharedWith {
                    Image(systemName: "person.2.fill")
                        .foregroundColor(.accentColor)
                        .opacity(shared.count > 1 ? 1 : 0)
                        .scaleEffect(shared.count > 1 ? 1 : 0.8)
                        .animation(.easeInOut(duration: 0.35), value: shared.count)
                }
                Spacer()
                Text("Elementos: \(viewModel.products.count)")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Menu {
                    if let sharedWith = list.sharedWith, sharedWith.count > 1 {
                        Button(role: .destructive) {
                            viewModel.deleteList(listID: list.id ?? "")
                        } label: {
                            Label("Salir de la lista", systemImage: "rectangle.portrait.and.arrow.right")
                        }
                    } else {
                        Button(role: .destructive) {
                            viewModel.deleteList(listID: list.id ?? "")
                        } label: {
                            Label("Eliminar lista", systemImage: "trash")
                        }
                    }

                    Button {
                        viewModel.presentShareSheet(for: list)
                    } label: {
                        Label("Compartir lista", systemImage: "person.crop.circle.badge.plus")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                        .font(.title3)
                        .foregroundColor(.secondary)
                        .padding(.leading, 4)
                }
            }
            .padding(.horizontal, 12)
            .padding(.top, 8)
            .transition(.opacity.combined(with: .move(edge: .trailing)))
            
            // Barra de progreso que muestra productos comprados y total
            let total = viewModel.products.count
            let comprados = viewModel.products.filter { $0.esComprado }.count
            let progreso = total == 0 ? 0 : Double(comprados) / Double(total)

            HStack(spacing: 12) {
                Text("\(comprados)")
                    .font(.headline)
                    .frame(minWidth: 24, alignment: .trailing)

                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        Capsule()
                            .fill(Color(.systemGray5))
                            .frame(height: 8)
                        Capsule()
                            .fill(Color.accentColor)
                            .frame(width: geometry.size.width * CGFloat(progreso), height: 8)
                            .animation(.easeInOut(duration: 0.35), value: progreso)
                    }
                }
                .frame(height: 8)

                Text("/ \(total)")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .frame(minWidth: 28, alignment: .leading)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .transition(.opacity.combined(with: .move(edge: .trailing)))

            // Botón "Eliminar seleccionados" cuando hay productos comprados
            Group {
                if viewModel.products.contains(where: { $0.esComprado }) {
                    HStack {
                        Spacer()
                        Button(role: .destructive) {
                            showDeleteSelectedAlert = true
                        } label: {
                            Label("Eliminar seleccionados", systemImage: "trash")
                                .font(.subheadline)
                        }
                        .padding(.trailing, 16)
                        .padding(.vertical, 4)
                    }
                    .transition(.opacity.combined(with: .move(edge: .trailing)))
                }
            }
            .animation(.easeInOut(duration: 0.3), value: comprados)

                Group {
                    if viewModel.products.isEmpty {
                        Spacer()
                        EmptyListAnimatedView()
                        Spacer()
                    } else {
                        List {
                            ForEach(viewModel.products) { product in
                                ProductRowView(
                                    product: product,
                                    selectedProductID: $selectedProductID,
                                    showDeleteProductAlert: $showDeleteProductAlert,
                                    editedName: $editedName,
                                )
                            }
                            .onMove { indices, newOffset in
                                viewModel.moveProducts(from: indices, to: newOffset)
                            }
                        }
                        .listStyle(.plain)
                        .padding(.top, 8)
                        .padding(.bottom, 4)
                        .animation(.spring(response: 0.4, dampingFraction: 0.75), value: viewModel.products)
                        .transition(.opacity.combined(with: .move(edge: .trailing)))
                        .environment(\.editMode, .constant(.active))
                    }
                }
                .animation(.easeInOut(duration: 0.35), value: viewModel.products)
            }
        }
        .id(list.id)
        .animation(.easeInOut(duration: 0.35), value: list.id)
        .transition(.opacity.combined(with: .move(edge: .trailing)))
        .padding(.horizontal, 2)
        .frame(maxHeight: .infinity)
        .alert("¿Eliminar los elementos seleccionados?", isPresented: $showDeleteSelectedAlert) {
            Button("Eliminar", role: .destructive) {
                let seleccionados = viewModel.products.filter { $0.esComprado }
                seleccionados.forEach { viewModel.deleteProduct($0) }
            }
            Button("Cancelar", role: .cancel) { }
        } message: {
            Text("Esta acción eliminará todos los elementos que has marcado como realizados.")
        }
    }
}

struct EmptyListAnimatedView: View {
    @State private var appear = false
    
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "cart")
                .resizable()
                .scaledToFit()
                .frame(width: 70, height: 70)
                .foregroundColor(.accentColor.opacity(0.3))
                .scaleEffect(appear ? 1 : 0.8)
                .opacity(appear ? 1 : 0)
                .animation(.spring(response: 0.5, dampingFraction: 0.6), value: appear)
            Text("Tu lista está vacía")
                .font(.headline)
                .scaleEffect(appear ? 1 : 0.8)
                .opacity(appear ? 1 : 0)
                .animation(.spring(response: 0.7, dampingFraction: 0.7).delay(0.07), value: appear)
        }
        .onAppear { appear = true }
        .onDisappear { appear = false }
    }
}
