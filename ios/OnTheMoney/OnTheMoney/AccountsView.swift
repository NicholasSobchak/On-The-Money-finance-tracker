import SwiftUI

struct AccountsView: View {
    @State private var accounts: [Account] = []
    @State private var totalBalance = 0.0
    @State private var isLinking = false
    @State private var showPlaidLink = false
    @State private var linkToken: String?
    @State private var searchText = ""
    @State private var showSearch = false
    @FocusState private var isSearchFocused: Bool

    private var filteredAccounts: [Account] {
        guard !searchText.isEmpty else { return accounts }
        return accounts.filter { acct in
            acct.name.lowercased().contains(searchText.lowercased()) ||
            acct.accType.lowercased().contains(searchText.lowercased())
        }
    }

    var body: some View {
        NavigationStack {
            ScrollView(.vertical, showsIndicators: false) {
                VStack(alignment: .leading, spacing: 0) {

                    // ── SEARCH BAR ──
                    if showSearch {
                        HStack(spacing: 8) {
                            Image(systemName: "magnifyingglass")
                                .font(.system(size: 13))
                                .foregroundColor(.themeMuted)

                            TextField("Search accounts...", text: $searchText)
                                .font(.custom("Palatino", size: 15))
                                .foregroundColor(.themeText)
                                .focused($isSearchFocused)

                            if !searchText.isEmpty {
                                Image(systemName: "xmark.circle.fill")
                                    .font(.system(size: 13))
                                    .foregroundColor(.themeMuted)
                                    .onTapGesture {
                                        searchText = ""
                                        isSearchFocused = true
                                    }
                            }
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 10)
                        .background(Color.themeSurface)
                        .cornerRadius(10)
                        .padding(.horizontal, 16)
                        .padding(.bottom, 12)
                    }

                    // ── ACCOUNTS HEADER ──
                    HStack(spacing: 6) {
                        Text("Accounts")
                            .font(.custom("Palatino", size: 16))
                            .foregroundColor(.themeMuted)

                        Image(systemName: "magnifyingglass")
                            .font(.system(size: 13))
                            .foregroundColor(showSearch ? .themeText : .themeMuted)
                            .onTapGesture {
                                withAnimation(.easeInOut(duration: 0.2)) {
                                    showSearch.toggle()
                                    if !showSearch {
                                        searchText = ""
                                        isSearchFocused = false
                                    } else {
                                        isSearchFocused = true
                                    }
                                }
                            }
                    }
                    .padding(.horizontal, 16)
                    .padding(.bottom, 10)

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
                    } else if filteredAccounts.isEmpty {
                        VStack(spacing: 12) {
                            Image(systemName: "magnifyingglass")
                                .font(.system(size: 32))
                                .foregroundColor(.themeMuted.opacity(0.4))
                            Text("No matching accounts")
                                .font(.custom("Palatino", size: 15))
                                .foregroundColor(.themeMuted)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.top, 40)
                    } else {
                        LazyVStack(spacing: 12) {
                            ForEach(filteredAccounts) { account in
                                NavigationLink(destination: AccountDetailView(account: account)) {
                                    AccountRow(account: account, totalBalance: totalBalance)
                                }
                                .padding(.horizontal, 16)
                            }
                        }
                    }

                    // ── LINK ACCOUNT BUTTON ──
                    Button {
                        Task { await startLinking() }
                    } label: {
                        if isLinking {
                            ProgressView()
                                .frame(height: 20)
                        } else {
                            HStack(spacing: 12) {
                                Image(systemName: "plus.circle")
                                    .font(.system(size: 14))
                                    .foregroundColor(.themeMuted)
                                    .frame(width: 28, height: 28)
                                    .background(Color.themeSurface2)
                                    .cornerRadius(6)

                                Text("Link Account")
                                    .font(.custom("Palatino", size: 15))
                                    .foregroundColor(.themeMuted)

                                Spacer()

                                Image(systemName: "chevron.right")
                                    .font(.system(size: 11, weight: .medium))
                                    .foregroundColor(.themeMuted.opacity(0.5))
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 12)
                            .background(Color.themeSurface)
                            .cornerRadius(10)
                        }
                    }
                    .disabled(isLinking)
                    .padding(.horizontal, 16)
                    .padding(.top, 20)
                }
            }
            .background(Color.themeBackground)
            .task {
                await loadAccounts()
            }
            .sheet(isPresented: $showPlaidLink) {
                if let token = linkToken {
                    PlaidLinkView(
                        linkToken: token,
                        onComplete: { publicToken, institutionId, institutionName in
                            showPlaidLink = false
                            Task { await exchangeAndSync(publicToken: publicToken, institutionId: institutionId, institutionName: institutionName) }
                        },
                        onCancel: {
                            showPlaidLink = false
                        }
                    )
                    .ignoresSafeArea()
                }
            }
        }
    }

    func startLinking() async {
        isLinking = true
        let api = APIClient()
        guard let token = try? await api.createLinkToken() else {
            isLinking = false
            return
        }
        linkToken = token
        showPlaidLink = true
        isLinking = false
    }

    func exchangeAndSync(publicToken: String, institutionId: String, institutionName: String) async {
        let api = APIClient()
        try? await api.exchangePlaidToken(publicToken: publicToken, institutionId: institutionId, institutionName: institutionName)
        await loadAccounts()
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
                    .padding(.trailing, 4)

                    NavigationLink(destination: AccountEditView(account: account)) {
                        Image(systemName: "chevron.right")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.themeMuted.opacity(0.5))
                            .padding(.trailing, 8)
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
