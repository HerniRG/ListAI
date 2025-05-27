//
//  AnalysisSheetView.swift
//  ListAI
//
//  Created by Hernán Rodríguez on 26/5/25.
//

import SwiftUI

struct AnalysisSheetView: View {
    @EnvironmentObject var viewModel: HomeViewModel
    // Recibimos el resultado y copiamos las sugerencias a un @State para poder animar/eliminar.
    let analysis: AnalysisResult
    @Environment(\.dismiss) private var dismiss

    @State private var tempSuggestions: [String] = []
    @State private var showDuplicateAlert = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 12) {
                Spacer().frame(height: 8)
                
                // Cabecera con icono
                VStack(spacing: 6) {
                    Image(systemName: "sparkles")
                        .font(.system(size: 34, weight: .medium))
                        .foregroundColor(.accentColor)
                    Text("Análisis de la lista")
                        .font(.title2.bold())
                        .foregroundColor(.primary)
                    
                    if let nombre = viewModel.activeList?.nombre {
                        Text(nombre)
                            .font(.subheadline.weight(.semibold))
                            .foregroundColor(.secondary)
                    }
                }
                .frame(maxWidth: .infinity)
                
                List {
                    // Bloque de sugerencias IA
                    if !tempSuggestions.isEmpty {
                        Section(header: Text("Sugerencias IA")) {
                            ForEach(tempSuggestions, id: \.self) { sug in
                                HStack {
                                    Image(systemName: "plus.circle")
                                        .foregroundColor(.accentColor)
                                        .font(.system(size: 18, weight: .medium))
                                    Text(sug)
                                    Spacer()
                                }
                                .padding(.vertical, 4)
                                .contentShape(Rectangle())
                                .background(Color.clear)
                                .onTapGesture {
                                    Haptic.light()
                                    withAnimation(.easeInOut(duration: 0.2)) {
                                        addSuggestionToList(sug)
                                    }
                                }
                            }
                        }
                    }
                    
                    // Bloque de consejos
                    if !analysis.tips.isEmpty {
                        Section(header: Text("Consejos")) {
                            ForEach(analysis.tips, id: \.self) { tip in
                                Text("💡 \(tip)")
                                    .padding(.vertical, 2)
                            }
                        }
                    }
                }
                .listStyle(.plain)
                .animation(.easeInOut(duration: 0.3), value: tempSuggestions)
                .onChange(of: tempSuggestions) { _, newValue in
                    // Si ya no quedan sugerencias, cerramos la hoja tras una breve animación
                    if newValue.isEmpty {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                            dismiss()
                        }
                    }
                }
            }
            .padding(.top, 0)
            .background(Color(.systemGroupedBackground).ignoresSafeArea())
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cerrar") {
                        dismiss()
                    }
                }
            }
        }
        .onAppear {
            // Copiamos sugerencias a un @State para poder mutarlas.
            tempSuggestions = analysis.suggestions
        }
        .presentationDetents([.large])
        .presentationDragIndicator(.visible)
        .transition(.move(edge: .bottom).combined(with: .opacity))
        .alert("Este elemento ya existe", isPresented: $showDuplicateAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text("Ya tienes un elemento con ese nombre en tu lista.")
        }
    }
    
    // MARK: - Helpers
    private func addSuggestionToList(_ name: String) {
        if viewModel.products.contains(where: { $0.nombre.lowercased() == name.lowercased() }) {
            showDuplicateAlert = true
            return
        }
        viewModel.addProduct(named: name)
        // Eliminamos de la lista local para feedback rápido
        if let index = tempSuggestions.firstIndex(of: name) {
            let suggestion = tempSuggestions[index] + " (añadido)"
            tempSuggestions[index] = suggestion
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                if let idx = tempSuggestions.firstIndex(of: suggestion) {
                    _ = withAnimation {
                        tempSuggestions.remove(at: idx)
                    }
                }
            }
        }
    }
}
