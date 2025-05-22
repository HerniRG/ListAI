import SwiftUI

struct ProductListView: View {
    let list: ShoppingListModel
    @Binding var selectedPageIndex: Int
    @Binding var selectedProductID: String?
    @Binding var showDeleteProductAlert: Bool
    @Binding var showDeleteListAlert: Bool
    @Binding var editedName: String

    @EnvironmentObject var viewModel: HomeViewModel

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text("📝 \(list.nombre)")
                    .font(.title3)
                    .fontWeight(.bold)
                Spacer()
                Text("Productos: \(viewModel.products.count)")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Menu {
                    Button(role: .destructive) {
                        showDeleteListAlert = true
                    } label: {
                        Label("Eliminar lista", systemImage: "trash")
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

            Group {
                if viewModel.products.isEmpty {
                    Spacer()
                    VStack(spacing: 16) {
                        Image(systemName: "cart")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 70, height: 70)
                            .foregroundColor(.accentColor.opacity(0.3))
                        Text("Tu lista está vacía").font(.headline)
                    }
                    .transition(.opacity.combined(with: .scale))
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
        .padding(.horizontal, 2)
        .frame(maxHeight: .infinity)
    }
}
