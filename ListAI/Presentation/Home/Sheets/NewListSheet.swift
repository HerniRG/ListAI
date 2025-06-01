import SwiftUI

struct NewListSheet: View {
    @EnvironmentObject var viewModel: HomeViewModel
    @Binding var showNewListSheet: Bool
    @Binding var newListName: String
    
    var body: some View {
        VStack(alignment: .center, spacing: 18) {
            // Cabecera solo texto, sin icono grande
            Text("Crear nueva lista")
                .font(.title2.bold())
                .multilineTextAlignment(.center)
                .padding(.top, 8)
            
            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: 12) {
                    Image(systemName: "list.bullet.rectangle")
                        .foregroundColor(.accentColor)
                    TextField("Nombre de la lista", text: $newListName)
                        .font(.body)
                        .textInputAutocapitalization(.sentences)
                }
                .padding()
                .background(Color(.secondarySystemBackground))
                .cornerRadius(12)

                Text("Pon un nombre específico. La IA lo usará para darte mejores ideas.")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .frame(maxWidth: .infinity)
            
            // Selector visual de contexto y subtítulo agrupados
            VStack(alignment: .leading, spacing: 6) {
                Menu {
                    ForEach(IAContext.allCases, id: \.self) { context in
                        Button {
                            viewModel.selectedContextForNewList = context
                        } label: {
                            Label {
                                Text(context.rawValue)
                            } icon: {
                                Image(systemName: context.iconName)
                            }
                        }
                    }
                } label: {
                    HStack {
                        Image(systemName: viewModel.selectedContextForNewList.iconName)
                        Text(viewModel.selectedContextForNewList.rawValue)
                        Spacer()
                        Image(systemName: "chevron.down")
                            .foregroundColor(.gray)
                    }
                    .padding()
                    .background(Color(.secondarySystemBackground))
                    .cornerRadius(12)
                }

                Text(viewModel.selectedContextForNewList.subtitle)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .frame(maxWidth: .infinity)
            
            // Botón principal (todo el ancho)
            Button {
                viewModel.addNewList(nombre: newListName)
                newListName = ""
                showNewListSheet = false
            } label: {
                Label("Crear lista", systemImage: "plus")
                    .frame(maxWidth: .infinity, minHeight: 48)
            }
            .buttonStyle(.borderedProminent)
            .disabled(newListName.trimmingCharacters(in: .whitespaces).isEmpty)
            
            // Botón cancelar, igual ancho y separado
            Button("Cancelar", role: .destructive) {
                showNewListSheet = false
                newListName = ""
            }
            .frame(maxWidth: .infinity, minHeight: 44)
            .buttonStyle(.bordered)
            .tint(.red)
            .controlSize(.regular)
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 32)
        .presentationDetents([.fraction(0.65), .large])
        .presentationContentInteraction(.resizes)
        .presentationDragIndicator(.visible)
    }
}
