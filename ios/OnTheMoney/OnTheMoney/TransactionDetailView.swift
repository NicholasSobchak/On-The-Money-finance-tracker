import SwiftUI

struct TransactionDetailView: View {
    @AppStorage("currency") private var currency = "USD"
    let transaction: Transaction
    @Environment(\.dismiss) var dismiss
    @State private var description: String = ""
    @State private var editingField: String? = nil
    @State private var showDeleteConfirm = false
    @FocusState private var focusedField: String?

    private var isCredit: Bool {
        transaction.type == "DEPOSIT" || transaction.toAccountId != nil
    }

    private var amount: Double {
        isCredit ? transaction.amount : -transaction.amount
    }

    private var dateLabel: String {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        guard let d = f.date(from: transaction.date) else { return transaction.date }
        f.dateFormat = "EEEE, MMM d, yyyy"
        return f.string(from: d)
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

                    Image(systemName: "trash")
                        .font(.system(size: 15))
                        .foregroundColor(.themeMuted)
                        .onTapGesture { showDeleteConfirm = true }
                }
                .padding(.horizontal, 16)
                .padding(.top, 8)
                .padding(.bottom, 20)

                // ── AMOUNT ──
                VStack(spacing: 6) {
                    Text(amount, format: .currency(code: currency))
                        .font(.custom("Palatino", size: 48))
                        .fontWeight(.medium)
                        .foregroundColor(isCredit ? .green : .red)

                    Text(isCredit ? "Money In" : "Money Out")
                        .font(.custom("Palatino", size: 13))
                        .foregroundColor(.themeMuted.opacity(0.6))
                }
                .frame(maxWidth: .infinity)
                .padding(.bottom, 30)

                // ── DETAILS ──
                VStack(spacing: 0) {
                    // Description
                    fieldRow(label: "Description", value: $description, field: "description")

                    Divider().background(Color.white.opacity(0.08)).padding(.horizontal, 16)

                    // Date
                    dateFieldRow()

                    Divider().background(Color.white.opacity(0.08)).padding(.horizontal, 16)

                    // Type
                    typeFieldRow()
                }
                .background(Color.themeSurface)
                .cornerRadius(10)
                .padding(.horizontal, 16)

                Spacer(minLength: 40)
            }
        }
        .background(Color.themeBackground)
        .navigationBarHidden(true)
        .overlay {
            if showDeleteConfirm {
                Color.black.opacity(0.6)
                    .ignoresSafeArea()
                    .onTapGesture { showDeleteConfirm = false }

                VStack(spacing: 20) {
                    Image(systemName: "trash")
                        .font(.system(size: 32))
                        .foregroundColor(.red)

                    Text("Delete this transaction?")
                        .font(.custom("Palatino", size: 18))
                        .foregroundColor(.themeText)

                    Text("This action cannot be undone.")
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
                                try? await api.deleteTransaction(id: transaction.id)
                                dismiss()
                            }
                        } label: {
                            Text("Delete")
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
            description = transaction.description ?? ""
        }
    }

    // ── REUSABLE FIELD ROW ──
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
                    .focused($focusedField, equals: field)
                    .onSubmit { saveField(field) }
            } else {
                Text(value.wrappedValue.isEmpty ? "Add" : value.wrappedValue)
                    .font(.custom("Palatino", size: 15))
                    .foregroundColor(value.wrappedValue.isEmpty ? .themeMuted.opacity(0.5) : .themeText)
                Image(systemName: "pencil")
                    .font(.system(size: 10))
                    .foregroundColor(.themeMuted)
                    .padding(.leading, 6)
                    .onTapGesture {
                        focusedField = field
                        editingField = field
                    }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
    }

    // ── DATE FIELD ROW ──
    private func dateFieldRow() -> some View {
        HStack {
            Text("Date")
                .font(.custom("Palatino", size: 15))
                .foregroundColor(.themeMuted)
            Spacer()
            if editingField == "date" {
                DatePicker("", selection: dateBinding, displayedComponents: .date)
                    .labelsHidden()
                    .environment(\.colorScheme, .dark)
                    .onSubmit { saveField("date") }
            } else {
                Text(dateLabel)
                    .font(.custom("Palatino", size: 15))
                    .foregroundColor(.themeText)
                Image(systemName: "pencil")
                    .font(.system(size: 10))
                    .foregroundColor(.themeMuted)
                    .padding(.leading, 6)
                    .onTapGesture {
                        editingField = "date"
                    }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
    }

    // ── TYPE FIELD ROW ──
    private func typeFieldRow() -> some View {
        HStack {
            Text("Type")
                .font(.custom("Palatino", size: 15))
                .foregroundColor(.themeMuted)
            Spacer()
            Text(transaction.type.capitalized)
                .font(.custom("Palatino", size: 15))
                .foregroundColor(.themeText)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
    }

    // ── DATE BINDING ──
    private var dateBinding: Binding<Date> {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        let initialDate = f.date(from: transaction.date) ?? Date()
        return Binding(
            get: { initialDate },
            set: { newDate in
                let formatter = DateFormatter()
                formatter.dateFormat = "yyyy-MM-dd"
                let newDateString = formatter.string(from: newDate)
                saveDate(newDateString)
            }
        )
    }

    // ── SAVE FIELD ──
    private func saveField(_ field: String) {
        editingField = nil
        focusedField = nil
        if field == "description" {
            let trimmed = description.trimmingCharacters(in: .whitespaces)
            Task {
                let api = APIClient()
                _ = try? await api.updateTransaction(id: transaction.id, description: trimmed.isEmpty ? nil : trimmed)
            }
        }
    }

    private func saveDate(_ dateString: String) {
        editingField = nil
        Task {
            let api = APIClient()
            _ = try? await api.updateTransaction(id: transaction.id, date: dateString)
        }
    }
}


#Preview {
    TransactionDetailView(transaction: Transaction(id: 1, fromAccountId: nil, toAccountId: 59, amount: 500, description: nil, date: "2026-07-14", type: "DEPOSIT"))
        .preferredColorScheme(.dark)
}
