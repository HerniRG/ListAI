import SwiftUI

struct ProfileView: View {
    var body: some View {
        NavigationView {
            VStack(spacing: 24) {
                Image(systemName: "person.crop.circle.fill")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 100, height: 100)
                    .foregroundColor(.accentColor)
                    .padding(.top, 32)

                Text("Mi perfil")
                    .font(.title2.bold())

                List {
                    Section(header: Text("Información")) {
                        Label("Nombre: Hernán Rodríguez", systemImage: "person.fill")
                        Label("Correo: hernan@example.com", systemImage: "envelope.fill")
                    }

                    Section(header: Text("Preferencias")) {
                        Label("Modo oscuro: activado", systemImage: "moon.fill")
                        Label("Idioma: Español", systemImage: "globe")
                    }
                }
                .listStyle(.insetGrouped)

                Spacer()
            }
            .navigationTitle("Perfil")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}
