import SwiftUI

struct SplashScreenView: View {
    @State private var animate = false

    var body: some View {
        VStack(spacing: 16) {
            Image("logo")
                .resizable()
                .scaledToFit()
                .frame(width: 160, height: 160)
                .opacity(animate ? 1 : 0)
                .scaleEffect(animate ? 1 : 0.8)
                .animation(.easeOut(duration: 1), value: animate)

            Text("ListAI")
                .font(.largeTitle)
                .fontWeight(.semibold)
                .foregroundColor(.white)
                .opacity(animate ? 1 : 0)
                .offset(y: animate ? 0 : 10)
                .animation(.easeOut(duration: 1).delay(0.2), value: animate)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(hex: "#008BFF"))
        .onAppear {
            animate = true
        }
    }
}

extension Color {
    init(hex: String) {
        let scanner = Scanner(string: hex)
        _ = scanner.scanString("#")
        
        var rgb: UInt64 = 0
        scanner.scanHexInt64(&rgb)
        
        let r = Double((rgb >> 16) & 0xFF) / 255
        let g = Double((rgb >> 8) & 0xFF) / 255
        let b = Double(rgb & 0xFF) / 255
        
        self.init(red: r, green: g, blue: b)
    }
}
