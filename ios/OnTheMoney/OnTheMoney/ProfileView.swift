import SwiftUI
import Combine
import Foundation
import UserNotifications

struct ProfileView: View {
    @State private var userName = "Nick Sobchak"
    @State private var userEmail = "nick@example.com"

    // ── EDIT NAME ──
    @State private var showEditName = false
    @State private var editingName = ""

    // ── EDIT EMAIL ──
    @State private var showEditEmail = false
    @State private var editingEmail = ""

    // ── PREFERENCES ──
    @AppStorage("notifications") private var notificationsOn = false
    @AppStorage("darkMode") private var darkModeOn = true
    @AppStorage("currency") private var currency = "USD"
    @AppStorage("defaultView") private var defaultView = "Portfolio"
    @State private var showCurrencyPicker = false
    @State private var showDefaultViewPicker = false

    // ── DATA ──
    @State private var linkedAccountCount = 2
    @State private var isSyncing = false
    @State private var syncComplete = false
    @State private var syncErrorMessage = ""
    @State private var showSyncError = false
    @State private var showExportSheet = false
    @State private var isExporting = false
    @State private var exportComplete = false
    @State private var exportURL: URL?

    // ── ABOUT ──
    @State private var showTerms = false
    @State private var showPrivacy = false

    // ── LOGOUT ──
    @State private var showLogoutConfirm = false

    private let currencies = ["USD", "EUR", "GBP", "CAD", "AUD"]
    private let defaultViews = ["Portfolio", "Accounts", "Stocks"]

    var body: some View {
        NavigationStack {
            ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: 20) {

                    // ── AVATAR ──
                    VStack(spacing: 8) {
                        ZStack {
                            Circle()
                                .fill(Color.themeSurface)
                                .frame(width: 90, height: 90)

                            Image(systemName: "person.fill")
                                .font(.system(size: 36))
                                .foregroundColor(.themeMuted)
                        }

                        Text(userName)
                            .font(.custom("Palatino", size: 20))
                            .foregroundColor(.themeText)

                        Text(userEmail)
                            .font(.custom("Palatino", size: 13))
                            .foregroundColor(.themeMuted)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 24)

                    // ── ACCOUNT ──
                    profileSection(title: "Account") {
                        profileRow(icon: "person", label: "Edit Name", value: userName) {
                            editingName = userName
                            showEditName = true
                        }
                        profileRow(icon: "envelope", label: "Email", value: userEmail) {
                            editingEmail = userEmail
                            showEditEmail = true
                        }
                    }

                    // ── PREFERENCES ──
                    profileSection(title: "Preferences") {
                        toggleRow(icon: "bell", label: "Notifications", isOn: $notificationsOn)
                            .onChange(of: notificationsOn) { on in
                                toggleWeeklyNotification(on)
                            }
                        toggleRow(icon: "moon", label: "Dark Mode", isOn: $darkModeOn)
                        profileRow(icon: "dollarsign.circle", label: "Currency", value: currency) {
                            showCurrencyPicker = true
                        }
                        profileRow(icon: "chart.bar", label: "Default View", value: defaultView) {
                            showDefaultViewPicker = true
                        }
                    }

                    // ── DATA ──
                    profileSection(title: "Data") {
                        profileRow(icon: "link", label: "Linked Accounts", value: "\(linkedAccountCount)") {
                        }
                        profileRow(icon: "square.and.arrow.up", label: "Export Data", value: nil) {
                            showExportSheet = true
                        }
                        syncRow()
                    }

                    // ── ABOUT ──
                    profileSection(title: "About") {
                        profileRow(icon: "info.circle", label: "Version", value: "1.0") {
                        }
                        profileRow(icon: "doc.text", label: "Terms of Service", value: nil) {
                            showTerms = true
                        }
                        profileRow(icon: "hand.raised", label: "Privacy Policy", value: nil) {
                            showPrivacy = true
                        }
                    }

                    // ── LOGOUT ──
                    Button {
                        showLogoutConfirm = true
                    } label: {
                        Text("Log Out")
                            .font(.custom("Palatino", size: 15))
                            .foregroundColor(.red)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(Color.themeSurface)
                            .cornerRadius(10)
                    }
                    .padding(.horizontal, 16)

                    Spacer(minLength: 40)
                }
            }
            .background(Color.themeBackground)
            .onAppear {
                UNUserNotificationCenter.current().getNotificationSettings { settings in
                    DispatchQueue.main.async {
                        notificationsOn = settings.authorizationStatus == .authorized
                    }
                }
            }
            // ── EDIT NAME SHEET ──
            .sheet(isPresented: $showEditName) {
                editSheet(title: "Edit Name") {
                    TextField("Name", text: $editingName)
                        .font(.custom("Palatino", size: 15))
                        .foregroundColor(.themeText)
                        .padding(12)
                        .background(Color.themeSurface2)
                        .cornerRadius(8)
                } onConfirm: {
                    userName = editingName
                    showEditName = false
                }
            }
            // ── EDIT EMAIL SHEET ──
            .sheet(isPresented: $showEditEmail) {
                editSheet(title: "Edit Email") {
                    TextField("Email", text: $editingEmail)
                        .font(.custom("Palatino", size: 15))
                        .foregroundColor(.themeText)
                        .padding(12)
                        .background(Color.themeSurface2)
                        .cornerRadius(8)
                } onConfirm: {
                    userEmail = editingEmail
                    showEditEmail = false
                }
            }
            // ── CURRENCY PICKER ──
            .sheet(isPresented: $showCurrencyPicker) {
                editSheet(title: "Currency") {
                    VStack(spacing: 0) {
                        ForEach(currencies, id: \.self) { c in
                            Button {
                                currency = c
                                showCurrencyPicker = false
                            } label: {
                                HStack {
                                    Text(c)
                                        .font(.custom("Palatino", size: 15))
                                        .foregroundColor(.themeText)
                                    Spacer()
                                    if c == currency {
                                        Image(systemName: "checkmark")
                                            .foregroundColor(.white)
                                    }
                                }
                                .padding(.horizontal, 12)
                                .padding(.vertical, 14)
                            }

                            if c != currencies.last {
                                Divider().background(Color.white.opacity(0.06))
                            }
                        }
                    }
                } onConfirm: {
                    showCurrencyPicker = false
                }
            }
            // ── DEFAULT VIEW PICKER ──
            .sheet(isPresented: $showDefaultViewPicker) {
                editSheet(title: "Default View") {
                    VStack(spacing: 0) {
                        ForEach(defaultViews, id: \.self) { v in
                            Button {
                                defaultView = v
                                showDefaultViewPicker = false
                            } label: {
                                HStack {
                                    Text(v)
                                        .font(.custom("Palatino", size: 15))
                                        .foregroundColor(.themeText)
                                    Spacer()
                                    if v == defaultView {
                                        Image(systemName: "checkmark")
                                            .foregroundColor(.white)
                                    }
                                }
                                .padding(.horizontal, 12)
                                .padding(.vertical, 14)
                            }

                            if v != defaultViews.last {
                                Divider().background(Color.white.opacity(0.06))
                            }
                        }
                    }
                } onConfirm: {
                    showDefaultViewPicker = false
                }
            }
            // ── EXPORT SHEET ──
            .sheet(isPresented: $showExportSheet) {
                editSheet(title: "Export Data", onCancel: {
                    showExportSheet = false
                    exportComplete = false
                    isExporting = false
                }) {
                    VStack(spacing: 16) {
                        if isExporting {
                            ProgressView()
                                .scaleEffect(0.8)
                            Text("Generating CSV...")
                                .font(.custom("Palatino", size: 14))
                                .foregroundColor(.themeMuted)
                        } else if exportComplete {
                            Image(systemName: "checkmark.circle")
                                .font(.system(size: 32))
                                .foregroundColor(.green)
                            Text("CSV ready to share")
                                .font(.custom("Palatino", size: 14))
                                .foregroundColor(.themeMuted)
                        } else {
                            Image(systemName: "square.and.arrow.up")
                                .font(.system(size: 32))
                                .foregroundColor(.themeMuted)

                            Text("Export all accounts and transactions as a CSV file.")
                                .font(.custom("Palatino", size: 14))
                                .foregroundColor(.themeMuted)
                                .multilineTextAlignment(.center)
                        }
                    }
                    .padding(.vertical, 12)
                } onConfirm: {
                    if !isExporting && !exportComplete {
                        Task { await exportData() }
                    } else if exportComplete {
                        showExportSheet = false
                        exportComplete = false
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                            if let url = self.exportURL {
                                let vc = UIActivityViewController(activityItems: [url], applicationActivities: nil)
                                UIApplication.shared.firstKeyWindow?.rootViewController?.present(vc, animated: true)
                            }
                        }
                    }
                }
            }
            // ── TERMS SHEET ──
            .sheet(isPresented: $showTerms) {
                editSheet(title: "Terms of Service") {
                    ScrollView {
                        Text("Terms of Service\n\nThis app is for personal financial tracking only. No real money is moved. All data is stored locally on your device and your self-hosted backend.\n\nUse at your own risk. We are not responsible for any financial decisions made based on the data in this app.")
                            .font(.custom("Palatino", size: 14))
                            .foregroundColor(.themeMuted)
                            .lineSpacing(4)
                    }
                    .frame(maxHeight: 300)
                } onConfirm: {
                    showTerms = false
                }
            }
            // ── PRIVACY SHEET ──
            .sheet(isPresented: $showPrivacy) {
                editSheet(title: "Privacy Policy") {
                    ScrollView {
                        Text("Privacy Policy\n\nYour financial data never leaves your local network. All API calls are made to your own self-hosted backend at localhost:8080.\n\nNo data is sent to third parties except when you explicitly link a bank account via Plaid, which is handled securely through Plaid's servers.")
                            .font(.custom("Palatino", size: 14))
                            .foregroundColor(.themeMuted)
                            .lineSpacing(4)
                    }
                    .frame(maxHeight: 300)
                } onConfirm: {
                    showPrivacy = false
                }
            }
            // ── LOGOUT CONFIRM ──
            .overlay {
                if showLogoutConfirm {
                    Color.black.opacity(0.6)
                        .ignoresSafeArea()
                        .onTapGesture { showLogoutConfirm = false }

                    VStack(spacing: 20) {
                        Image(systemName: "rectangle.portrait.and.arrow.right")
                            .font(.system(size: 32))
                            .foregroundColor(.red)

                        Text("Log Out?")
                            .font(.custom("Palatino", size: 18))
                            .foregroundColor(.themeText)

                        Text("You'll need to sign in again to access your account.")
                            .font(.custom("Palatino", size: 14))
                            .foregroundColor(.themeMuted)
                            .multilineTextAlignment(.center)

                        HStack(spacing: 12) {
                            Button {
                                showLogoutConfirm = false
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
                                showLogoutConfirm = false
                            } label: {
                                Text("Log Out")
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
        }
        .task {
            let api = APIClient()
            linkedAccountCount = (try? await api.getLinkedItemCount()) ?? 0
        }
    }

    // ── SYNC ROW ──
    private func syncRow() -> some View {
        HStack(spacing: 12) {
            Image(systemName: "arrow.triangle.2.circlepath")
                .font(.system(size: 15))
                .foregroundColor(.themeMuted)
                .frame(width: 24)

            Text("Sync Now")
                .font(.custom("Palatino", size: 15))
                .foregroundColor(.themeText)

            Spacer()

            if isSyncing {
                ProgressView()
                    .scaleEffect(0.8)
            } else if syncComplete {
                Image(systemName: "checkmark")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(.green)
            } else {
                Image(systemName: "chevron.right")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(.themeMuted.opacity(0.5))
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .contentShape(Rectangle())
        .onTapGesture {
            guard !isSyncing else { return }
            isSyncing = true
            syncComplete = false
            Task {
                let api = APIClient()
                do {
                    _ = try await api.syncPlaidAccounts()
                    _ = try await api.recordNetWorthSnapshot()
                    syncComplete = true
                } catch {
                    syncErrorMessage = "Sync failed. Check your connection."
                    showSyncError = true
                }
                isSyncing = false
                try? await Task.sleep(for: .seconds(2))
                syncComplete = false
            }
        }
        .alert("Sync Error", isPresented: $showSyncError) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(syncErrorMessage)
        }
    }

    // ── EXPORT DATA ──
    private func exportData() async {
        isExporting = true
        let api = APIClient()
        let accounts = (try? await api.getAccounts()) ?? []
        let transactions = (try? await api.getTransactions()) ?? []

        var csv = "Type,ID,Name,Balance,Account Type\n"
        for acct in accounts {
            csv += "Account,\(acct.id),\"\(acct.name)\",\(acct.balance),\(acct.accType)\n"
        }

        csv += "\nType,ID,From Account,To Account,Amount,Description,Date,Transaction Type\n"
        for tx in transactions {
            let from = tx.fromAccountId.map(String.init) ?? ""
            let to = tx.toAccountId.map(String.init) ?? ""
            let desc = tx.description?.replacingOccurrences(of: "\"", with: "\"\"") ?? ""
            csv += "Transaction,\(tx.id),\(from),\(to),\(tx.amount),\"\(desc)\",\(tx.date),\(tx.type)\n"
        }

        let fileName = "OnTheMoney_Export_\(Date.now.formatted(.dateTime.year().month().day())).csv"
        let tempDir = FileManager.default.temporaryDirectory
        let fileURL = tempDir.appendingPathComponent(fileName)
        try? csv.write(to: fileURL, atomically: true, encoding: .utf8)

        exportURL = fileURL
        isExporting = false
        exportComplete = true

        if let url = exportURL {
            let vc = UIActivityViewController(activityItems: [url], applicationActivities: nil)
            UIApplication.shared.firstKeyWindow?.rootViewController?.present(vc, animated: true)
        }
    }

    // ── GENERIC EDIT SHEET ──
    private func editSheet<Content: View>(title: String, onCancel: (() -> Void)? = nil, @ViewBuilder content: () -> Content, onConfirm: @escaping () -> Void) -> some View {
        VStack(spacing: 0) {
            // ── CUSTOM TOP BAR ──
            HStack {
                Text("Cancel")
                    .font(.custom("Palatino", size: 15))
                    .foregroundColor(.themeMuted)
                    .onTapGesture { onCancel?() ?? onConfirm() }

                Spacer()

                Text(title)
                    .font(.custom("Palatino", size: 17))
                    .foregroundColor(.themeText)

                Spacer()

                Text("Done")
                    .font(.custom("Palatino", size: 15))
                    .foregroundColor(.white)
                    .onTapGesture { onConfirm() }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)

            Divider().background(Color.white.opacity(0.08))

            VStack(spacing: 20) {
                content()
                    .padding(.horizontal, 16)
                    .padding(.top, 20)

                Spacer()
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.themeBackground)
    }

    // ── PROFILE SECTION ──
    private func profileSection<Content: View>(title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(title)
                .font(.custom("Palatino", size: 13))
                .foregroundColor(.themeMuted)
                .padding(.horizontal, 16)
                .padding(.bottom, 8)

            VStack(spacing: 0) {
                content()
            }
            .background(Color.themeSurface)
            .cornerRadius(10)
            .padding(.horizontal, 16)
        }
    }

    // ── PROFILE ROW ──
    @ViewBuilder
    private func profileRow(icon: String, label: String, value: String?, action: @escaping () -> Void) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 15))
                .foregroundColor(.themeMuted)
                .frame(width: 24)

            Text(label)
                .font(.custom("Palatino", size: 15))
                .foregroundColor(.themeText)

            Spacer()

            if let value = value {
                Text(value)
                    .font(.custom("Palatino", size: 14))
                    .foregroundColor(.themeMuted)
            }

            Image(systemName: "chevron.right")
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(.themeMuted.opacity(0.5))
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .contentShape(Rectangle())
        .onTapGesture { action() }

        Divider()
            .background(Color.white.opacity(0.06))
            .padding(.leading, 52)
    }

    // ── TOGGLE ROW ──
    @ViewBuilder
    private func toggleRow(icon: String, label: String, isOn: Binding<Bool>) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 15))
                .foregroundColor(.themeMuted)
                .frame(width: 24)

            Text(label)
                .font(.custom("Palatino", size: 15))
                .foregroundColor(.themeText)

            Spacer()

            // ── CUSTOM SWITCH ──
            ZStack {
                Capsule()
                    .fill(isOn.wrappedValue ? Color.themeAccent : Color.themeSurface2)
                    .frame(width: 40, height: 10)

                Circle()
                    .fill(isOn.wrappedValue ? Color.black : Color.themeMuted)
                    .frame(width: 20, height: 20)
                    .shadow(color: .black.opacity(0.3), radius: 3, y: 1)
                    .offset(x: isOn.wrappedValue ? 10 : -10)
            }
            .onTapGesture {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                    isOn.wrappedValue.toggle()
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .contentShape(Rectangle())

        Divider()
            .background(Color(light: Color.black.opacity(0.06), dark: Color.white.opacity(0.06)))
            .padding(.leading, 52)
    }

    // MARK: - Notifications

    private func toggleWeeklyNotification(_ on: Bool) {
        let center = UNUserNotificationCenter.current()
        if on {
            center.requestAuthorization(options: [.alert, .sound]) { granted, _ in
                guard granted else {
                    DispatchQueue.main.async { notificationsOn = false }
                    return
                }
                DispatchQueue.main.async { self.scheduleWeeklyReminder() }
            }
        } else {
            center.removePendingNotificationRequests(withIdentifiers: ["weeklySpendingReminder"])
        }
    }

    private func scheduleWeeklyReminder() {
        let center = UNUserNotificationCenter.current()
        let content = UNMutableNotificationContent()
        content.title = "On The Money"
        content.body = "Money on the move? Check out your spending and earnings."
        content.sound = .default

        var dateComponents = DateComponents()
        dateComponents.weekday = 2  // Monday
        dateComponents.hour = 9
        dateComponents.minute = 0

        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
        let request = UNNotificationRequest(identifier: "weeklySpendingReminder", content: content, trigger: trigger)
        center.add(request)
    }
}


extension UIApplication {
    var firstKeyWindow: UIWindow? {
        connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .flatMap { $0.windows }
            .first { $0.isKeyWindow }
    }
}


#Preview {
    ProfileView()
        .preferredColorScheme(.dark)
}
