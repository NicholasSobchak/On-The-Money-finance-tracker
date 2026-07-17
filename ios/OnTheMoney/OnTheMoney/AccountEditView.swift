import SwiftUI

struct AccountEditView: View {
    @AppStorage("currency") private var currency = "USD"
    let account: Account
    @Environment(\.dismiss) var dismiss
    @State private var name: String = ""
    @State private var accType: String = ""
    @State private var accountNumber: String = ""
    @State private var interestRate: String = ""
    @State private var dividendRate: String = ""
    @State private var editingField: String? = nil
    @State private var showSaveConfirm = false
    @State private var showDeleteConfirm = false

    private let accountTypes = ["CHECKING", "SAVINGS", "CREDIT_CARD", "INVESTMENT"]

    private var typeLabel: String {
        switch accType {
        case "CHECKING": return "Checking Account"
        case "SAVINGS": return "Savings Account"
        case "CREDIT_CARD": return "Credit Card"
        case "INVESTMENT": return "Investment Account"
        default: return accType
        }
    }

    var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(spacing: 0) {

                // ── CUSTOM TOP BAR ──
                HStack {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.themeMuted)
                        .onTapGesture { dismiss() }

                    Spacer()

                    Text("Account Details")
                        .font(.custom("Palatino", size: 17))
                        .foregroundColor(.themeText)

                    Spacer()

                    Image(systemName: "trash")
                        .font(.system(size: 15))
                        .foregroundColor(.themeMuted)
                        .onTapGesture { showDeleteConfirm = true }
                }
                .padding(.horizontal, 16)
                .padding(.top, 8)
                .padding(.bottom, 20)

                // ── FIELDS ──
                VStack(spacing: 0) {
                    // Name
                    fieldRow(label: "Name", value: $name, field: "name")

                    Divider().background(Color.white.opacity(0.08)).padding(.horizontal, 16)

                    // Account Number
                    fieldRow(label: "Account #", value: $accountNumber, field: "accountNumber")

                    Divider().background(Color.white.opacity(0.08)).padding(.horizontal, 16)

                    // Balance (read only)
                    HStack {
                        Text("Balance")
                            .font(.custom("Palatino", size: 15))
                            .foregroundColor(.themeMuted)
                        Spacer()
                        Text(account.balance, format: .currency(code: currency))
                            .font(.custom("Palatino", size: 15))
                            .foregroundColor(.themeText)
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 14)

                    Divider().background(Color.white.opacity(0.08)).padding(.horizontal, 16)

                    // Interest Rate
                    fieldRow(label: "Interest %", value: $interestRate, field: "interestRate")

                    Divider().background(Color.white.opacity(0.08)).padding(.horizontal, 16)

                    // Dividend Rate
                    fieldRow(label: "Dividend %", value: $dividendRate, field: "dividendRate")

                    Divider().background(Color.white.opacity(0.08)).padding(.horizontal, 16)

                    // Type
                    HStack {
                        Text("Type")
                            .font(.custom("Palatino", size: 15))
                            .foregroundColor(.themeMuted)
                        Spacer()
                        Menu {
                            ForEach(accountTypes, id: \.self) { type in
                                Button {
                                    accType = type
                                } label: {
                                    HStack {
                                        Text(typeLabelFor(type))
                                        if accType == type {
                                            Image(systemName: "checkmark")
                                        }
                                    }
                                }
                            }
                        } label: {
                            HStack(spacing: 4) {
                                Text(typeLabel)
                                    .font(.custom("Palatino", size: 15))
                                    .foregroundColor(.themeText)
                                Image(systemName: "chevron.down")
                                    .font(.system(size: 10))
                                    .foregroundColor(.themeMuted)
                            }
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 14)
                }
                .background(Color.themeSurface)
                .cornerRadius(10)
                .padding(.horizontal, 16)

                // ── SAVE BUTTON ──
                Button {
                    showSaveConfirm = true
                } label: {
                    Text("Save Changes")
                        .font(.custom("Palatino", size: 15))
                        .foregroundColor(.themeMuted)
                }
                .padding(.top, 24)
                .frame(maxWidth: .infinity)

                Spacer(minLength: 40)
            }
        }
        .background(Color.themeBackground)
        .navigationBarHidden(true)
        .overlay {
            if showSaveConfirm {
                Color.black.opacity(0.6)
                    .ignoresSafeArea()
                    .onTapGesture { showSaveConfirm = false }

                VStack(spacing: 20) {
                    Image(systemName: "checkmark.circle")
                        .font(.system(size: 32))
                        .foregroundColor(.green)

                    Text("Save changes to \(name)?")
                        .font(.custom("Palatino", size: 18))
                        .foregroundColor(.themeText)
                        .multilineTextAlignment(.center)

                    HStack(spacing: 12) {
                        Button {
                            showSaveConfirm = false
                        } label: {
                            Text("Cancel")
                                .font(.custom("Palatino", size: 15))
                                .foregroundColor(.themeMuted)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 12)
                                .background(Color.themeSurface2)
                                .cornerRadius(10)
                        }

                        Button {
                            showSaveConfirm = false
                            saveChanges()
                        } label: {
                            Text("Save")
                                .font(.custom("Palatino", size: 15))
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 12)
                                .background(Color.green)
                                .cornerRadius(10)
                        }
                    }
                }
                .padding(24)
                .background(Color.themeSurface)
                .cornerRadius(16)
                .padding(.horizontal, 40)
            }

            if showDeleteConfirm {
                Color.black.opacity(0.6)
                    .ignoresSafeArea()
                    .onTapGesture { showDeleteConfirm = false }

                VStack(spacing: 20) {
                    Image(systemName: "trash")
                        .font(.system(size: 32))
                        .foregroundColor(.red)

                    Text("Remove \(account.name)?")
                        .font(.custom("Palatino", size: 18))
                        .foregroundColor(.themeText)

                    Text("This account and all its transactions will be permanently deleted.")
                        .font(.custom("Palatino", size: 14))
                        .foregroundColor(.themeMuted)
                        .multilineTextAlignment(.center)

                    HStack(spacing: 12) {
                        Button {
                            showDeleteConfirm = false
                        } label: {
                            Text("Cancel")
                                .font(.custom("Palatino", size: 15))
                                .foregroundColor(.themeMuted)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 12)
                                .background(Color.themeSurface2)
                                .cornerRadius(10)
                        }

                        Button {
                            Task {
                                let api = APIClient()
                                try? await api.deleteAccount(id: account.id)
                                dismiss()
                            }
                        } label: {
                            Text("Remove")
                                .font(.custom("Palatino", size: 15))
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 12)
                                .background(Color.red)
                                .cornerRadius(10)
                        }
                    }
                }
                .padding(24)
                .background(Color.themeSurface)
                .cornerRadius(16)
                .padding(.horizontal, 40)
            }
        }
        .onAppear {
            name = account.name
            accType = account.accType
            accountNumber = account.accountNumber ?? ""
            if let rate = account.interestRate {
                interestRate = String(format: "%.2f", rate)
            }
        }
    }

    @ViewBuilder
    private func fieldRow(label: String, value: Binding<String>, field: String) -> some View {
        HStack {
            Text(label)
                .font(.custom("Palatino", size: 15))
                .foregroundColor(.themeMuted)
            Spacer()
            if editingField == field {
                TextField(label, text: value)
                    .font(.custom("Palatino", size: 15))
                    .foregroundColor(.themeText)
                    .multilineTextAlignment(.trailing)
                    .frame(maxWidth: 200)
                    .onSubmit { editingField = nil }
            } else {
                Text(value.wrappedValue.isEmpty ? "Add" : value.wrappedValue)
                    .font(.custom("Palatino", size: 15))
                    .foregroundColor(value.wrappedValue.isEmpty ? .themeMuted.opacity(0.5) : .themeText)
                Image(systemName: "pencil")
                    .font(.system(size: 10))
                    .foregroundColor(.themeMuted)
                    .padding(.leading, 6)
                    .onTapGesture {
                        editingField = field
                    }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
    }

    private func typeLabelFor(_ type: String) -> String {
        switch type {
        case "CHECKING": return "Checking Account"
        case "SAVINGS": return "Savings Account"
        case "CREDIT_CARD": return "Credit Card"
        case "INVESTMENT": return "Investment Account"
        default: return type
        }
    }

    private func saveChanges() {
        let trimmedName = name.trimmingCharacters(in: .whitespaces)
        guard !trimmedName.isEmpty else { return }
        Task {
            let api = APIClient()
            _ = try? await api.updateAccount(id: account.id, name: trimmedName, accType: accType)
            dismiss()
        }
    }
}


#Preview {
    AccountEditView(account: Account(id: 1, name: "Checking", balance: 5000, accType: "CHECKING"))
        .preferredColorScheme(.dark)
}
