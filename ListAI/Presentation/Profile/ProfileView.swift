import SwiftUI

struct ProfileView: View {
    @EnvironmentObject var viewModel: ProfileViewModel
    @EnvironmentObject var session: SessionManager
    @EnvironmentObject var homeViewModel: HomeViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var showSuccessAlert = false
    @State private var confirmingDeletion = false
    @State private var confirmingLogout = false
    @State private var confirmingPasswordReset = false
    @State private var fixedUserEmail: String = ""

    var body: some View {
        NavigationView {
            List {
                Section(header: Text("Información")) {
                    Label {
                        Text(fixedUserEmail)
                            .foregroundColor(.primary)
                    } icon: {
                        Image(systemName: "envelope.fill")
                            .foregroundColor(.accentColor)
                    }
                }
                
                Section(header: Text("Listas compartidas")) {
                    if viewModel.sharedLists.isEmpty {
                        Text("No tienes ninguna lista compartida")
                            .foregroundColor(.secondary)
                    } else {
                        ForEach(viewModel.sharedLists) { list in
                            Button {
                                if let index = homeViewModel.lists.firstIndex(where: { $0.id == list.id }) {
                                    homeViewModel.activeList = list
                                    homeViewModel.selectedPageIndex = index
                                    dismiss()
                                    Haptic.light()
                                }
                            } label: {
                                HStack {
                                    Text(list.nombre)
                                        .font(.body)
                                        .foregroundColor(.primary)
                                    Spacer()
                                    Image(systemName: "chevron.right")
                                        .foregroundColor(.secondary)
                                        .imageScale(.small)
                                }
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }

                Section(header: Text("Cuenta")) {
                    Button {
                        confirmingPasswordReset = true
                    } label: {
                        Label {
                            Text("Cambiar contraseña")
                                .foregroundColor(.primary)
                        } icon: {
                            Image(systemName: "key.fill")
                                .foregroundColor(.accentColor)
                        }
                    }
                    Button(role: .destructive) {
                        confirmingLogout = true
                    } label: {
                        Label {
                            Text("Cerrar sesión")
                                .foregroundColor(.primary)
                        } icon: {
                            Image(systemName: "rectangle.portrait.and.arrow.right")
                                .foregroundColor(.accentColor)
                        }
                    }
                }

                Section {
                    Button(role: .destructive) {
                        confirmingDeletion = true
                    } label: {
                        Label {
                            Text("Eliminar cuenta")
                        } icon: {
                            Image(systemName: "trash")
                                .foregroundColor(.red)
                        }
                    }
                } footer: {
                    Text("Eliminar tu cuenta es irreversible. Todos tus datos serán borrados.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .listStyle(.insetGrouped)
            .navigationTitle("Cuenta")
            .navigationBarTitleDisplayMode(.inline)
        }
        .confirmationDialog("Eliminar tu cuenta es irreversible.\nTodos tus datos serán borrados permanentemente.", isPresented: $confirmingDeletion, titleVisibility: .visible) {
            Button("Eliminar cuenta", role: .destructive) {
                viewModel.deleteAccount()
            }
            Button("Cancelar", role: .cancel) {}
        }
        .confirmationDialog("¿Quieres cerrar sesión?", isPresented: $confirmingLogout, titleVisibility: .visible) {
            Button("Cerrar sesión", role: .destructive) {
                viewModel.logout()
            }
            Button("Cancelar", role: .cancel) {}
        }
        .confirmationDialog("¿Enviar correo para restablecer contraseña?", isPresented: $confirmingPasswordReset, titleVisibility: .visible) {
            Button("Enviar", role: .none) {
                viewModel.sendPasswordReset()
            }
            Button("Cancelar", role: .cancel) {}
        }
        .onChange(of: viewModel.successMessage) { _, newValue in
            if newValue == "Sesión cerrada correctamente." {
                session.signOut()
            } else if newValue != nil {
                showSuccessAlert = true
            }
        }
        .alert("Operación completada", isPresented: $showSuccessAlert) {
            Button("OK") {
                viewModel.successMessage = nil
                session.signOut()
            }
        } message: {
            Text(viewModel.successMessage ?? "")
        }
        .onAppear {
            if fixedUserEmail.isEmpty, viewModel.userEmail != "Sin correo" {
                fixedUserEmail = viewModel.userEmail
            }
        }
    }
}
