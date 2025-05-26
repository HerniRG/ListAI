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
            
            // Campo con icono
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
            
            // Texto explicativo bajo el TextField
            Text("Especifica el nombre de la lista con detalle. Esto ayudará a la IA a darte mejores sugerencias.")
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
            
            // Selector visual de contexto
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
            
            // Explicación breve
            Text("Puedes crear listas para organizar tus ideas, compras, eventos o cualquier cosa que necesites.")
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.horizontal)
            
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
