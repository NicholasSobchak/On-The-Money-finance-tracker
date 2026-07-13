import SwiftUI

struct AccountsView: View {
    @State private var accounts: [Account] = []
    @State private var totalBalance = 0.0
    @State private var showPlaidLink = false
    @State private var linkToken = ""
    @State private var isLinking = false

    var body: some View {
        NavigationStack {
            ScrollView(.vertical, showsIndicators: false) {
                VStack(alignment: .leading, spacing: 0) {

                    // ── ACCOUNT LIST ──
                    if accounts.isEmpty {
                        VStack(spacing: 12) {
                            Image(systemName: "banknote")
                                .font(.system(size: 40))
                                .foregroundColor(.themeMuted.opacity(0.4))
                            Text("No accounts yet")
                                .font(.custom("Palatino", size: 16))
                                .foregroundColor(.themeMuted)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.top, 60)
                    } else {
                        VStack(spacing: 0) {
                            LazyVStack(spacing: 12) {
                                ForEach(accounts) { account in
                                    NavigationLink(destination: AccountDetailView(account: account)) {
                                        AccountRow(account: account, totalBalance: totalBalance)
                                    }
                                    .padding(.horizontal, 16)
                                }
                            }

                            Button {
                                Task { await startLinking() }
                            } label: {
                                Text("Link Account")
                                    .font(.custom("Palatino", size: 15))
                                    .foregroundColor(.themeMuted)
                            }
                            .padding(.top, 20)
                        }
                    }
                }
            }
            .background(Color.themeBackground)
            .sheet(isPresented: $showPlaidLink) {
                PlaidLinkView(
                    linkToken: linkToken,
                    onComplete: { publicToken, institutionId, institutionName in
                        showPlaidLink = false
                        Task {
                            let api = APIClient()
                            try? await api.exchangePlaidToken(
                                publicToken: publicToken,
                                institutionId: institutionId,
                                institutionName: institutionName
                            )
                            _ = try? await api.syncPlaidAccounts()
                            await loadAccounts()
                        }
                    },
                    onCancel: {
                        showPlaidLink = false
                    }
                )
            }
            .task {
                await loadAccounts()
            }
        }
    }

    func startLinking() async {
        isLinking = true
        let api = APIClient()
        linkToken = (try? await api.createLinkToken()) ?? ""
        if !linkToken.isEmpty {
            showPlaidLink = true
        }
        isLinking = false
    }

    func loadAccounts() async {
        let api = APIClient()
        accounts = (try? await api.getAccounts()) ?? []
        totalBalance = accounts.map(\.balance).reduce(0, +)
    }
}

struct AccountRow: View {
    let account: Account
    let totalBalance: Double
    @State private var showDeleteConfirm = false
    @State private var isDeleted = false

    private var pct: Double {
        guard totalBalance != 0 else { return 0 }
        return account.balance / totalBalance
    }

    private var typeIcon: String {
        switch account.accType {
        case "CHECKING": return "banknote"
        case "SAVINGS": return "building.columns"
        case "CREDIT_CARD": return "creditcard"
        case "INVESTMENT": return "chart.line.uptrend.xyaxis"
        default: return "banknote"
        }
    }

    private var typeLabel: String {
        switch account.accType {
        case "CHECKING": return "Checking"
        case "SAVINGS": return "Savings"
        case "CREDIT_CARD": return "Credit Card"
        case "INVESTMENT": return "Investment"
        default: return account.accType
        }
    }

    var body: some View {
        if !isDeleted {
            VStack(spacing: 0) {
                HStack(spacing: 12) {
                    Image(systemName: typeIcon)
                        .font(.system(size: 20))
                        .foregroundColor(.themeMuted)
                        .frame(width: 36, height: 36)
                        .background(Color.themeSurface2)
                        .cornerRadius(8)

                    VStack(alignment: .leading, spacing: 2) {
                        Text(account.name)
                            .font(.custom("Palatino", size: 16))
                            .foregroundColor(.themeText)
                        Text(typeLabel)
                            .font(.custom("Palatino", size: 12))
                            .foregroundColor(.themeMuted)
                    }

                    Spacer()

                    VStack(alignment: .trailing, spacing: 2) {
                        Text(account.balance, format: .currency(code: "USD"))
                            .font(.custom("Palatino", size: 16))
                            .foregroundColor(account.balance >= 0 ? .themeText : .red)
                        Text("\(pct * 100, specifier: "%.1f")%")
                            .font(.custom("Palatino", size: 12))
                            .foregroundColor(.themeMuted)
                    }
                }
                .padding(.vertical, 14)

                // proportional bar
                GeometryReader { geo in
                    let barWidth = max(0, geo.size.width * min(abs(pct), 1.0))
                    RoundedRectangle(cornerRadius: 2)
                        .fill(Color.white.opacity(0.1))
                    RoundedRectangle(cornerRadius: 2)
                        .fill(account.balance >= 0 ? Color.white.opacity(0.25) : Color.red.opacity(0.25))
                        .frame(width: barWidth)
                }
                .frame(height: 6)
            }
            .background(Color.themeSurface)
            .cornerRadius(10)
            .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                Button(role: .destructive) {
                    showDeleteConfirm = true
                } label: {
                    Label("Delete", systemImage: "trash")
                }
            }
            .confirmationDialog("Delete \(account.name)?", isPresented: $showDeleteConfirm, titleVisibility: .visible) {
                Button("Delete", role: .destructive) {
                    Task {
                        let api = APIClient()
                        try? await api.deleteAccount(id: account.id)
                        withAnimation { isDeleted = true }
                    }
                }
                Button("Cancel", role: .cancel) {}
            }
        }
    }
}


#Preview {
    AccountsView()
        .preferredColorScheme(.dark)
}
