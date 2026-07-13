import SwiftUI

struct AccountDetailView: View {
    let account: Account
    @Environment(\.dismiss) var dismiss
    @State private var transactions: [Transaction] = []
    @State private var accountName: String = ""
    @State private var isEditingName = false
    @FocusState private var isNameFieldFocused: Bool

    var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(alignment: .leading, spacing: 0) {

                // ── HEADER ──
                VStack(spacing: 6) {
                    if isEditingName {
                        TextField("Account Name", text: $accountName)
                            .font(.custom("Palatino", size: 20))
                            .foregroundColor(.white)
                            .multilineTextAlignment(.center)
                            .focused($isNameFieldFocused)
                            .onSubmit { saveName() }
                    } else {
                        Button {
                            accountName = account.name
                            isEditingName = true
                            isNameFieldFocused = true
                        } label: {
                            HStack(spacing: 6) {
                                Text(account.name)
                                    .font(.custom("Palatino", size: 20))
                                    .foregroundColor(.white)
                                Image(systemName: "pencil")
                                    .font(.system(size: 12))
                                    .foregroundColor(.themeMuted)
                            }
                        }
                    }
                    Text(typeLabel)
                        .font(.custom("Palatino", size: 13))
                        .foregroundColor(.themeMuted.opacity(0.6))
                    Text(account.balance, format: .currency(code: "USD"))
                        .font(.custom("Palatino", size: 52))
                        .fontWeight(.medium)
                        .foregroundColor(account.balance >= 0 ? .white : .red)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 30)
                .padding(.bottom, 10)

                // ── TRANSACTIONS ──
                Text("Transactions")
                    .font(.custom("Palatino", size: 16))
                    .foregroundColor(.themeMuted)
                    .padding(.horizontal, 16)
                    .padding(.bottom, 10)

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
                } else {
                    LazyVStack(spacing: 0) {
                        ForEach(transactions) { tx in
                            TransactionRow(transaction: tx, accountId: account.id)
                            if tx.id != transactions.last?.id {
                                Divider()
                                    .background(Color.white.opacity(0.08))
                                    .padding(.horizontal, 16)
                            }
                        }
                    }
                    .background(Color.themeSurface)
                    .cornerRadius(10)
                    .padding(.horizontal, 16)
                }

                Spacer(minLength: 40)
            }
        }
        .background(Color.themeBackground)
        .task {
            await loadData()
        }
    }

    func loadData() async {
        let api = APIClient()
        transactions = (try? await api.getTransactions()) ?? []
    }

    private func saveName() {
        isEditingName = false
        isNameFieldFocused = false
        let trimmed = accountName.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty, trimmed != account.name else { return }
        Task {
            let api = APIClient()
            _ = try? await api.updateAccount(id: account.id, name: trimmed)
            dismiss()
        }
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
}

struct TransactionRow: View {
    let transaction: Transaction
    let accountId: Int

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
                Text(transaction.description ?? transaction.type.capitalized)
                    .font(.custom("Palatino", size: 15))
                    .foregroundColor(.themeText)
                Text(dateLabel)
                    .font(.custom("Palatino", size: 12))
                    .foregroundColor(.themeMuted)
            }

            Spacer()

            Text(amount, format: .currency(code: "USD"))
                .font(.custom("Palatino", size: 15))
                .foregroundColor(isCredit ? .green : .red)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }
}


#Preview {
    AccountDetailView(account: Account(id: 1, name: "Checking", balance: 5000, accType: "CHECKING"))
        .preferredColorScheme(.dark)
}
