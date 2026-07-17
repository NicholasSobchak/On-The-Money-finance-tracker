import SwiftUI

struct AccountDetailView: View {
    @AppStorage("currency") private var currency = "USD"
    let account: Account
    @Environment(\.dismiss) var dismiss
    @State private var transactions: [Transaction] = []
    @State private var searchText = ""
    @State private var showSearch = false
    @State private var typeFilter: String? = nil
    @FocusState private var isSearchFocused: Bool

    private var filteredTransactions: [Transaction] {
        var result = transactions

        if let filter = typeFilter {
            if filter == "DEPOSIT" {
                result = result.filter { $0.type == "DEPOSIT" || $0.toAccountId == account.id }
            } else if filter == "WITHDRAW" {
                result = result.filter { $0.type == "WITHDRAW" || $0.fromAccountId == account.id }
            }
        }

        if !searchText.isEmpty {
            result = result.filter { tx in
                let desc = tx.description?.lowercased() ?? ""
                let amt = String(format: "%.2f", tx.amount)
                return desc.contains(searchText.lowercased()) || amt.contains(searchText.lowercased())
            }
        }

        return result
    }

    var body: some View {
        NavigationStack {
            ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: 0) {

                    // ── CUSTOM TOP BAR ──
                    HStack {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.themeMuted)
                            .onTapGesture { dismiss() }

                        Spacer()

                        NavigationLink(destination: AccountEditView(account: account)) {
                            Image(systemName: "pencil")
                                .font(.system(size: 15))
                                .foregroundColor(.themeMuted)
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 8)
                    .padding(.bottom, 12)

                    // ── SEARCH BAR ──
                    if showSearch {
                        VStack(spacing: 10) {
                            HStack(spacing: 8) {
                                Image(systemName: "magnifyingglass")
                                    .font(.system(size: 13))
                                    .foregroundColor(.themeMuted)

                                TextField("Search transactions...", text: $searchText)
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

                            // ── FILTER BUTTONS ──
                            HStack(spacing: 8) {
                                filterPill(label: "Deposits", type: "DEPOSIT")
                                filterPill(label: "Withdraws", type: "WITHDRAW")
                                Spacer()
                            }
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 10)
                        .background(Color.themeSurface)
                        .cornerRadius(10)
                        .padding(.horizontal, 16)
                        .padding(.bottom, 12)
                    }

                    // ── HEADER ──
                    VStack(spacing: 6) {
                        Text(account.name)
                            .font(.custom("Palatino", size: 20))
                            .foregroundColor(.themeText)

                        Text(typeLabel)
                            .font(.custom("Palatino", size: 13))
                            .foregroundColor(.themeMuted.opacity(0.6))

                        Text(account.balance, format: .currency(code: currency))
                            .font(.custom("Palatino", size: 52))
                            .fontWeight(.medium)
                            .foregroundColor(account.balance >= 0 ? .themeText : .red)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 30)
                    .padding(.bottom, 10)

                    // ── TRANSACTIONS ──
                    HStack(spacing: 6) {
                        Text("Transactions")
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
                                        typeFilter = nil
                                        isSearchFocused = false
                                    } else {
                                        isSearchFocused = true
                                    }
                                }
                            }
                    }
                    .padding(.horizontal, 16)
                    .padding(.bottom, 10)
                    .frame(maxWidth: .infinity, alignment: .leading)

                    if transactions.isEmpty {
                        VStack(spacing: 12) {
                            Image(systemName: "list.bullet.rectangle")
                                .font(.system(size: 32))
                                .foregroundColor(.themeMuted.opacity(0.4))
                            Text("No transactions yet")
                                .font(.custom("Palatino", size: 15))
                                .foregroundColor(.themeMuted)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.top, 40)
                    } else if filteredTransactions.isEmpty {
                        VStack(spacing: 12) {
                            Image(systemName: "magnifyingglass")
                                .font(.system(size: 32))
                                .foregroundColor(.themeMuted.opacity(0.4))
                            Text("No matching transactions")
                                .font(.custom("Palatino", size: 15))
                                .foregroundColor(.themeMuted)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.top, 40)
                    } else {
                        LazyVStack(spacing: 12) {
                            ForEach(filteredTransactions) { tx in
                                NavigationLink(destination: TransactionDetailView(transaction: tx)) {
                                    TransactionRow(transaction: tx, accountId: account.id, accountBalance: account.balance)
                                }
                            }
                        }
                        .padding(.horizontal, 16)
                    }

                    Spacer(minLength: 40)
                }
            }
            .background(Color.themeBackground)
            .navigationBarHidden(true)
            .task {
                await loadData()
            }
        }
    }

    func loadData() async {
        let api = APIClient()
        transactions = (try? await api.getTransactions()) ?? []
    }

    private var typeLabel: String {
        switch account.accType {
        case "CHECKING": return "Checking Account"
        case "SAVINGS": return "Savings Account"
        case "CREDIT_CARD": return "Credit Card"
        case "INVESTMENT": return "Investment Account"
        default: return account.accType
        }
    }

    private func filterPill(label: String, type: String) -> some View {
        Button {
            withAnimation(.easeInOut(duration: 0.15)) {
                typeFilter = typeFilter == type ? nil : type
            }
        } label: {
            Text(label)
                .font(.custom("Palatino", size: 13))
                .foregroundColor(typeFilter == type ? .black : .themeMuted)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(typeFilter == type ? Color.white : Color.themeSurface2)
                .cornerRadius(8)
        }
    }
}

struct TransactionRow: View {
    let transaction: Transaction
    let accountId: Int
    var accountBalance: Double? = nil
    @AppStorage("currency") private var currency = "USD"

    private var isCredit: Bool {
        transaction.type == "DEPOSIT" || transaction.toAccountId == accountId
    }

    private var amount: Double {
        isCredit ? transaction.amount : -transaction.amount
    }

    private var dateLabel: String {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        guard let d = f.date(from: transaction.date) else { return transaction.date }
        f.dateFormat = "MMM d, yyyy"
        return f.string(from: d)
    }

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: isCredit ? "arrow.down.left" : "arrow.up.right")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(isCredit ? .green : .red)
                .frame(width: 32, height: 32)
                .background((isCredit ? Color.green : Color.red).opacity(0.1))
                .cornerRadius(8)

            VStack(alignment: .leading, spacing: 2) {
                if let desc = transaction.description, !desc.isEmpty {
                    Text(desc)
                        .font(.custom("Palatino", size: 15))
                        .foregroundColor(.themeText)
                } else {
                    HStack(spacing: 4) {
                        Image(systemName: "pencil")
                            .font(.system(size: 10))
                            .foregroundColor(.themeMuted.opacity(0.5))
                        Text("Add a description")
                            .font(.custom("Palatino", size: 15))
                            .foregroundColor(.themeMuted.opacity(0.5))
                    }
                }
                Text(dateLabel)
                    .font(.custom("Palatino", size: 12))
                    .foregroundColor(.themeMuted)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 2) {
                Text(amount, format: .currency(code: currency))
                    .font(.custom("Palatino", size: 15))
                    .foregroundColor(isCredit ? .green : .red)
                if let balance = accountBalance {
                    Text(balance, format: .currency(code: currency))
                        .font(.custom("Palatino", size: 11))
                        .foregroundColor(.themeMuted)
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 16)
        .background(Color.themeSurface)
        .cornerRadius(10)
    }
}


#Preview {
    AccountDetailView(account: Account(id: 1, name: "Checking", balance: 5000, accType: "CHECKING"))
        .preferredColorScheme(.dark)
}
