import SwiftUI

struct ContentView: View {
    @State private var selectedTab = 0

    var body: some View {
        ZStack(alignment: .bottom) {
            TabView(selection: $selectedTab) {
                PortfolioView()
                    .tag(0)

                AccountsView()
                    .tag(1)

                StocksView()
                    .tag(2)

                ProfileView()
                    .tag(3)
            }
            .toolbar(.hidden, for: .tabBar)

            HStack(spacing: 0) {
                tabButton(icon: "building.columns.fill", title: "Portfolio", tag: 0)
                tabButton(icon: "creditcard", title: "Accounts", tag: 1)
                tabButton(icon: "chart.xyaxis.line", title: "Stocks", tag: 2)
                tabButton(icon: "person", title: "Profile", tag: 3)
            }
            .frame(height: 56)
            .background(Color.black)
        }
    }

    private func tabButton(icon: String, title: String, tag: Int) -> some View {
        Button {
            selectedTab = tag
        } label: {
            VStack(spacing: 2) {
                Image(systemName: icon)
                    .font(.system(size: 20))
                Text(title)
                    .font(.custom("Palatino", size: 10))
            }
            .foregroundColor(selectedTab == tag ? .white : Color.themeMuted)
            .frame(maxWidth: .infinity)
        }
    }
}
