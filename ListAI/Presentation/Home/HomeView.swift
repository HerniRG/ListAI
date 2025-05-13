import SwiftUI

struct HomeView: View {
    @EnvironmentObject var session: SessionManager
    @EnvironmentObject var viewModel: HomeViewModel
    
    var body: some View {
        NavigationView {
            VStack(alignment: .leading, spacing: 16) {
                
                if viewModel.isLoading {
                    ProgressView("Cargando lista...")
                } else if let error = viewModel.errorMessage {
                    Text("❌ \(error)").foregroundColor(.red)
                } else if let activeList = viewModel.activeList {
                    Text("📝 Lista: \(activeList.nombre)")
                        .font(.title2.bold())
                    
                    List(viewModel.products) { product in
                        HStack {
                            Text(product.nombre)
                            Spacer()
                            if product.esComprado {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(.green)
                            }
                        }
                    }
                } else {
                    Text("No tienes listas creadas todavía.")
                }
            }
            .padding()
            .navigationTitle("ListAI")
        }
    }
}
