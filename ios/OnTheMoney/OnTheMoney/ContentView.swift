import SwiftUI
import UIKit

struct ContentView: View {
    @AppStorage("defaultView") private var defaultView = "Portfolio"

    private var initialTab: Int {
        switch defaultView {
        case "Accounts": return 1
        case "Stocks":  return 2
        default:        return 0
        }
    }

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
            .onAppear { selectedTab = initialTab }

            HStack(spacing: 0) {
                tabButton(icon: "building.columns.fill", title: "Portfolio", tag: 0)
                tabButton(icon: "lock.rectangle.stack", title: "Accounts", tag: 1)
                tabButton(icon: "chart.xyaxis.line", title: "Stocks", tag: 2)
                tabButton(icon: "person", title: "Profile", tag: 3)
            }
            .frame(height: 56)
            .background(Color(light: Color(red: 0.96, green: 0.93, blue: 0.86), dark: Color.themeSurface))
        }
    }

    private func tabButton(icon: String, title: String, tag: Int) -> some View {
        Button {
            UISelectionFeedbackGenerator().selectionChanged()
            selectedTab = tag
        } label: {
            VStack(spacing: 2) {
                Image(systemName: icon)
                    .font(.system(size: 20))
                Text(title)
                    .font(.custom("Palatino", size: 10))
            }
            .foregroundColor(selectedTab == tag ? .themeAccent : Color.themeMuted)
            .frame(maxWidth: .infinity)
        }
    }
}
