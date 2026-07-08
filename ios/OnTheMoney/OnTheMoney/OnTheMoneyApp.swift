import SwiftUI

@main
struct OnTheMoneyApp: App {
    init() {
        UITableView.appearance().backgroundColor = .clear
        UINavigationBar.appearance().largeTitleTextAttributes = [
            .font: UIFont(name: "Palatino", size: 34) ?? .systemFont(ofSize: 34)
        ]
        UINavigationBar.appearance().titleTextAttributes = [
            .font: UIFont(name: "Palatino", size: 17) ?? .systemFont(ofSize: 17)
        ]
        UITabBar.appearance().backgroundColor = UIColor(Color.themeSurface)
        UITabBar.appearance().unselectedItemTintColor = UIColor(Color.themeMuted)
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .font(.custom("Palatino", size: 17))
                .preferredColorScheme(.dark)
                .tint(.themeAccent)
        }
    }
}
