import SwiftUI

struct ListSelectorView: View {
    @EnvironmentObject var viewModel: HomeViewModel
    var showNewListSheet: () -> Void

    @Namespace private var chipNamespace
    @State private var appear = false

    var body: some View {
        if !viewModel.lists.isEmpty {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 14) {
                    Spacer().frame(width: 8)
                    ForEach(viewModel.lists.indices, id: \.self) { idx in
                        Button(action: {
                            viewModel.selectedPageIndex = idx
                            Haptic.light()
                            withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                                viewModel.activeList = viewModel.lists[idx]
                            }
                        }) {
                            Text(viewModel.lists[idx].nombre)
                                .fontWeight(viewModel.selectedPageIndex == idx ? .bold : .regular)
                                .foregroundColor(viewModel.selectedPageIndex == idx ? .white : .accentColor)
                                .padding(.horizontal, 20)
                                .padding(.vertical, 8)
                                .lineLimit(1)
                                .truncationMode(.tail)
                                .background(
                                    Group {
                                        if viewModel.selectedPageIndex == idx {
                                            Capsule()
                                                .fill(Color.accentColor)
                                                .matchedGeometryEffect(id: "chip", in: chipNamespace)
                                        } else {
                                            Capsule()
                                                .fill(Color.accentColor.opacity(0.12))
                                        }
                                    }
                                )
                        }
                        .buttonStyle(.plain)
                        .animation(.spring(response: 0.35, dampingFraction: 0.8), value: viewModel.selectedPageIndex)
                    }
                    Button(action: showNewListSheet) {
                        Image(systemName: "plus.circle.fill")
                            .font(.title2)
                            .foregroundColor(.accentColor)
                    }
                    Spacer().frame(width: 8)
                }
            }
            .padding(.vertical, 14)
            .scaleEffect(appear ? 1 : 0.96)
            .opacity(appear ? 1 : 0)
            .animation(.spring(response: 0.5, dampingFraction: 0.7), value: appear)
            .onAppear { appear = true }
            .onDisappear { appear = false }
        }
    }
}
