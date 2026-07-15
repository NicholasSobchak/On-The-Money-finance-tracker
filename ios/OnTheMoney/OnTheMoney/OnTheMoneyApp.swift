import SwiftUI

@main
struct OnTheMoneyApp: App {
    @AppStorage("darkMode") private var darkMode = true
    @State private var showSplash = true

    init() {
        UITableView.appearance().backgroundColor = .clear
        UINavigationBar.appearance().largeTitleTextAttributes = [
            .font: UIFont(name: "Palatino", size: 34) ?? .systemFont(ofSize: 34)
        ]
        UINavigationBar.appearance().titleTextAttributes = [
            .font: UIFont(name: "Palatino", size: 17) ?? .systemFont(ofSize: 17)
        ]
        UINavigationBar.appearance().backgroundColor = UIColor(Color(red: 0.96, green: 0.96, blue: 0.96))
    }

    var body: some Scene {
        WindowGroup {
            ZStack {
                ContentView()
                    .font(.custom("Palatino", size: 17))
                    .preferredColorScheme(darkMode ? .dark : .light)
                    .tint(.themeAccent)

                if showSplash {
                    ZStack {
                        Color.black.ignoresSafeArea()
                        VStack {
                            Spacer()
                            Image("LogoFull")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 280, height: 280)
                            Spacer()
                        }
                    }
                    .transition(.opacity)
                    .task {
                        try? await Task.sleep(for: .seconds(3.5))
                        withAnimation(.easeInOut(duration: 0.8)) {
                            showSplash = false
                        }
                    }
                }
            }
        }
    }
}
