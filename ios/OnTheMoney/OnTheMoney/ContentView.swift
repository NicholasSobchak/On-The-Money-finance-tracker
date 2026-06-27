import SwiftUI

struct ContentView: View {
    @State private var engineStatus = "Waiting..."

    var body: some View {
        VStack(spacing: 20) {
            Text("On The Money")
                .font(.largeTitle)
            Text("Engine: \(engineStatus)")
                .task { await fetchStatus() }
        }
        .padding()
    }

    func fetchStatus() async {
        engineStatus = (try? await APIClient().getStatus())?.engineStatus ?? "Error"
    }
}

#Preview {
    ContentView()
}
