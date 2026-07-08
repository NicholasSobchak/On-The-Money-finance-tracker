import SwiftUI

struct ContentView: View {
    @State private var status = "Loading..."
    @State private var netWorth = 0.0
    @State private var totalAssets = 0.0
    @State private var totalLiabilities = 0.0
    @State private var inTheRed = 0.0
    @State private var inTheGreen = 0.0
    @State private var accounts: [Account] = []
    @State private var transactions: [Transaction] = []

    var body: some View {
        VStack(spacing: 20) {
            Text(status)
            Text(netWorth, format: .currency(code: "USD"))
            Text(totalAssets, format: .currency(code: "USD"))
            Text(totalLiabilities, format: .currency(code: "USD"))
            Text(inTheRed, format: .currency(code: "USD"))
            Text(inTheGreen, format: .currency(code: "USD"))

            List(accounts) { account in
                HStack {
                    Text(account.name)
                    Spacer()
                    Text(account.balance, format: .currency(code: "USD"))
                }
            }

            List(transactions) { tx in
                HStack {
                    Text(tx.description ?? tx.type)
                    Spacer()
                    Text(tx.amount, format: .currency(code: "USD"))
                }
            }

            Button("Add Account") {
                Task {
                    let api = APIClient()
                    try? await api.addAccount(name: "New", balance: 100, accType: "CHECKING")
                    accounts = (try? await api.getAccounts()) ?? []
                    transactions = (try? await api.getTransactions()) ?? []
                }
            }
        }
        .task { // runs async code when the view appears on screen
            await loadData()
        }
    }

    func loadData() async {
        let api = APIClient()
        status = (try? await api.getStatus())?.engineStatus ?? "Error" // try? - if this throws, return nil instead of crashing and ?.engineStatus ?? "Error" unwraps the optional
        netWorth = (try? await api.getNetWorth())?.netWorth ?? 0
        totalAssets = (try? await api.getTotalAssets())?.totalAssets ?? 0
        totalLiabilities = (try? await api.getTotalLiabilities())?.totalLiabilities ?? 0
        inTheRed = (try? await api.getInTheRed())?.inTheRed ?? 0
        inTheGreen = (try? await api.getInTheGreen())?.inTheGreen ?? 0
        accounts = (try? await api.getAccounts()) ?? []
    }
}

#Preview {
    ContentView()
}
