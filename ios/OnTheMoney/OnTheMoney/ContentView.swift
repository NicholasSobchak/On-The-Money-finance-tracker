import SwiftUI

struct ContentView: View {
    var body: some View {
        TabView {
            PortfolioView()
                .tabItem { Label("Portfolio", systemImage: "chart.bar.fill") }

            AccountsView()
                .tabItem { Label("Accounts", systemImage: "creditcard") }

            StocksView()
                .tabItem { Label("Stocks", systemImage: "chart.xyaxis.line") }

            ProfileView()
                .tabItem { Label("Profile", systemImage: "person") }
        }
    }
}
