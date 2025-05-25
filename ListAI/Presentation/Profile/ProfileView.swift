import SwiftUI

struct ProfileView: View {
    @EnvironmentObject var viewModel: ProfileViewModel
    @EnvironmentObject var session: SessionManager
    @State private var showSuccessAlert = false
    @State private var confirmingDeletion = false
    @State private var confirmingLogout = false
    @State private var confirmingPasswordReset = false

    var body: some View {
        NavigationView {
            List {
                Section(header: Text("Información")) {
                    HStack {
                        Image(systemName: "envelope.fill")
                            .foregroundColor(.blue)
                        Text(viewModel.userEmail)
                            .foregroundColor(.secondary)
                    }
                    .padding(.vertical, 2)
                }

                Section(header: Text("Cuenta")) {
                    Button {
                        confirmingPasswordReset = true
                    } label: {
                        Label("Cambiar contraseña", systemImage: "key.fill")
                            .foregroundColor(.primary)
                    }
                    Button(role: .destructive) {
                        confirmingLogout = true
                    } label: {
                        Label("Cerrar sesión", systemImage: "rectangle.portrait.and.arrow.right")
                            .foregroundColor(.primary)
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
            if newValue != nil {
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
    }
}
