import SwiftUI

struct ProductRowView: View {
    let product: ProductModel
    @Binding var selectedProductID: String?
    @Binding var showDeleteProductAlert: Bool
    @Binding var editedName: String

    @EnvironmentObject var viewModel: HomeViewModel

    var body: some View {
        HStack(spacing: 16) {
            Button(action: {
                withAnimation(.spring()) {
                    viewModel.toggleComprado(for: product)
                }
                Haptic.light()
            }) {
                Image(systemName: product.esComprado ? "checkmark.circle.fill" : "circle")
                    .font(.title2)
                    .foregroundColor(product.esComprado ? .green : .gray.opacity(0.6))
                    .scaleEffect(product.esComprado ? 1.1 : 1)
            }
            .buttonStyle(.plain)

            VStack(alignment: .leading, spacing: 2) {
                Text(product.nombre)
                    .font(.body)
                    .strikethrough(product.esComprado, color: .gray)
                    .foregroundColor(product.esComprado ? .gray : .primary)
                    .animation(.easeInOut, value: product.esComprado)
                    .onTapGesture(count: 2) {
                        editedName = product.nombre
                        viewModel.editingProduct = product
                    }
            }
            Spacer()
        }
        .padding(.vertical, 10)
        .listRowSeparator(.hidden)
        .background(
            RoundedRectangle(cornerRadius: 12).fill(Color.clear)
        )
        .onTapGesture {
            withAnimation(.easeInOut(duration: 0.12)) {
                selectedProductID = product.id
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.18) {
                withAnimation { selectedProductID = nil }
            }
        }
        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
            Button(role: .destructive) {
                selectedProductID = product.id
                showDeleteProductAlert = true
            } label: {
                Label("Eliminar", systemImage: "trash")
            }

            Button {
                editedName = product.nombre
                viewModel.editingProduct = product
            } label: {
                Label("Editar", systemImage: "pencil")
            }
            .tint(.blue)
        }
        .transition(.asymmetric(
            insertion: .scale.combined(with: .opacity),
            removal: .scale(scale: 0.9).combined(with: .opacity)
        ))
    }
}
