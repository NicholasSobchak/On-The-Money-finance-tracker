import SwiftUI // provides UI components (VStack, Text, Color, .font(), etc.)
import Charts // provides Chart, LineMark, AxisMarks, default coordinate system math (ChartProxy, chartOverlay)

// I KNOW THERE IS TOO MANY COMMENTS: This file is overommented for learning purposes
// I'm trying to code swift at a high level just learning it and there is a lot of functions from libraries i've never used before

struct PortfolioView: View {
    @State private var netWorth = 0.0
    @State private var originalNetWorth = 0.0
    @State private var history: [NetWorthHistory] = []
    @State private var selectedRange = "ALL"
    @State private var selectedDate: String?
    @State private var cachedFilteredHistory: [NetWorthHistory] = []
    @State private var cachedYDomain: ClosedRange<Double> = 0...20000
    @State private var accounts: [Account] = []
    @State private var transactions: [Transaction] = []
    @State private var creditScore = 0
    @State private var previousCreditScore = 0
    @State private var lastCreditScoreUpdate = Date()
    @State private var showCreditScoreEntry = false
    @State private var creditScoreInput = ""
    @State private var isSavingCreditScore = false
    @State private var showPlaidLink = false
    @State private var isLinking = false
    @State private var linkToken: String?

    let ranges = ["1W", "1M", "3M", "YTD", "1Y", "ALL"]

    private let dateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        return f
    }()
    private let monthFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM"
        return f
    }()
    private let monthLabelFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "MMM"
        return f
    }()

    struct CashFlowMonth: Identifiable {
        let id = UUID()
        let month: String
        let label: String
        let income: Double
        let expenses: Double
    }

    var monthlyCashFlow: [CashFlowMonth] {
        var grouped: [String: (income: Double, expenses: Double)] = [:]
        for tx in transactions {
            let monthKey = String(tx.date.prefix(7))
            var entry = grouped[monthKey] ?? (income: 0, expenses: 0)
            if tx.type == "DEPOSIT" || tx.toAccountId != nil {
                entry.income += tx.amount
            } else {
                entry.expenses += tx.amount
            }
            grouped[monthKey] = entry
        }
        return grouped.keys.sorted().suffix(6).map { key in
            let entry = grouped[key]!
            let date = monthFormatter.date(from: key)
            return CashFlowMonth(
                month: key,
                label: date.map { monthLabelFormatter.string(from: $0) } ?? key,
                income: entry.income,
                expenses: entry.expenses
            )
        }
    }

    var totalIncome: Double { monthlyCashFlow.map(\.income).reduce(0, +) }
    var totalExpenses: Double { monthlyCashFlow.map(\.expenses).reduce(0, +) }
    var savingsRate: Double { totalIncome > 0 ? ((totalIncome - totalExpenses) / totalIncome) * 100 : 0 }

    var debtAccounts: [Account] { accounts.filter { $0.accType == "CREDIT_CARD" || $0.balance < 0 } }
    var totalDebt: Double { debtAccounts.map(\.balance).reduce(0, +).magnitude }
    var investmentAccounts: [Account] { accounts.filter { $0.accType == "INVESTMENT" } }
    var totalInvestments: Double { investmentAccounts.map(\.balance).reduce(0, +) }

    var netWorthMilestones: [(month: String, netWorth: Double, change: Double)] {
        var result: [(month: String, netWorth: Double, change: Double)] = []
        let grouped = Dictionary(grouping: history) { String($0.date.prefix(7)) }
        let sorted = grouped.keys.sorted()
        for (i, key) in sorted.enumerated() {
            guard let last = grouped[key]?.last else { continue }
            let prev = i > 0 ? grouped[sorted[i - 1]]?.last?.netWorth : 0
            let date = monthFormatter.date(from: key)
            let label = date.map { monthLabelFormatter.string(from: $0) } ?? key
            result.append((month: label, netWorth: last.netWorth, change: last.netWorth - (prev ?? 0)))
        }
        return result.suffix(6)
    }

    var creditScoreColor: Color {
        switch creditScore {
        case ..<580: return .red
        case 580..<670: return .orange
        case 670..<740: return Color(red: 1.0, green: 0.85, blue: 0.0)
        case 740..<800: return .green
        default: return Color(red: 0.2, green: 0.8, blue: 0.4)
        }
    }

    var creditScoreLabel: String {
        switch creditScore {
        case ..<580: return "Poor"
        case 580..<670: return "Fair"
        case 670..<740: return "Good"
        case 740..<800: return "Very Good"
        default: return "Excellent"
        }
    }

    var creditScoreChange: Int { creditScore - previousCreditScore }
    var creditScoreImproved: Bool { creditScoreChange >= 0 }

    private let creditScoreDateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "MMM d, yyyy"
        return f
    }()

    private let dateOnlyFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "MMM d, yyyy"
        return f
    }()

    var isHovering: Bool { selectedDate != nil }

    // .flatMap {} — if selectedDate is non-nil, pass it into the closure.
    // dateFormatter.date(from:) — tries to parse the string into a Date, returns nil on failure.
    var hoverDate: String {
        guard let d = selectedDate.flatMap({ dateFormatter.date(from: $0) }) else { return "" }
        return dateOnlyFormatter.string(from: d) // format Date back into display string
    }

    // .first(where:) — returns the first element matching the condition (or nil).
    // $0 — shorthand for the first closure argument (each element in the array as it iterates).
    var hoveredEntry: NetWorthHistory? {
        guard cachedFilteredHistory.count >= 2 else { return nil }
        if let date = selectedDate {
            return cachedFilteredHistory.first(where: { $0.date == date })
        }
        return cachedFilteredHistory.last // returns last entry when not hovering
    }

    // .first! — force-unwrap .first because guard already confirmed count >= 2
    var change: Double {
        guard cachedFilteredHistory.count >= 2, let entry = hoveredEntry else { return 0 }
        return entry.netWorth - cachedFilteredHistory.first!.netWorth
    }

    var changePercent: Double {
        guard cachedFilteredHistory.count >= 2, let _ = hoveredEntry, cachedFilteredHistory.first!.netWorth != 0 else { return 0 }
        return (change / cachedFilteredHistory.first!.netWorth) * 100
    }

    var isPositive: Bool { change >= 0 }
    var inTheRed: Bool { netWorth < 0 }

    var latestHistoryDate: String {
        guard let last = history.last, let d = dateFormatter.date(from: last.date) else { return "" }
        return dateOnlyFormatter.string(from: d)
    }

    // dateFormatter.date(from:) — parse API date string (e.g. "2026-05-14") into a Date object.
    // dateOnlyFormatter.string(from:) — format that Date back to a readable string (e.g. "January 25, 2026").
    func formattedLabel(for dateString: String) -> String {
        guard let d = dateFormatter.date(from: dateString) else { return dateString }
        return dateOnlyFormatter.string(from: d)
    }

    // .firstIndex(where:) — find the index of the first element matching the date.
    // .prefix(N) — returns the first N elements as an ArraySlice.
    // Array(...) — converts the slice back into a regular Array.
    var leftSegment: [NetWorthHistory] {
        guard let selected = selectedDate else { return cachedFilteredHistory }
        let idx = cachedFilteredHistory.firstIndex(where: { $0.date == selected }) ?? cachedFilteredHistory.count - 1
        return Array(cachedFilteredHistory.prefix(idx + 1))
    }

    // .suffix(from:) — returns elements starting at index idx to the end.
    var rightSegment: [NetWorthHistory] {
        guard let selected = selectedDate,
              let idx = cachedFilteredHistory.firstIndex(where: { $0.date == selected }),
              idx + 1 < cachedFilteredHistory.count else { return [] }
        return Array(cachedFilteredHistory.suffix(from: idx))
    }

    // Dictionary(grouping: by:) — partitions array into buckets by a computed key.
    //   Returns [Key: [Element]]. Each bucket is all elements that produced the same key.
    //
    // .values — all the bucket arrays (ignoring the key).
    // .compactMap(\.last) — call .last on each bucket (returns the final entry of that month/week).
    // .sorted { $0.date < $1.date } — re-sort buckets back into chronological order
    //   (dictionaries have arbitrary iteration order).
    //
    // Calendar.current.dateComponents() — extracts specific components (weekOfYear, etc.) from a Date.
    //   .yearForWeekOfYear — the year that the ISO week belongs to (differs from calendar year
    //   for the first/last few days of the year).
    func downsample(_ data: [NetWorthHistory], for range: String) -> [NetWorthHistory] {
        switch range {
        case "ALL":
            let groups = Dictionary(grouping: data) { String($0.date.prefix(7)) }
            return groups.values.compactMap(\.last).sorted { $0.date < $1.date }
        case "1Y", "YTD":
            let groups = Dictionary(grouping: data) { point -> String in
                guard let d = dateFormatter.date(from: point.date) else { return point.date }
                let comps = Calendar.current.dateComponents([.yearForWeekOfYear, .weekOfYear], from: d)
                return "\(comps.yearForWeekOfYear ?? 0)-W\(comps.weekOfYear ?? 0)"
            }
            return groups.values.compactMap(\.last).sorted { $0.date < $1.date }
        default:
            return data
        }
    }

    // Calendar.current — the user's calendar (Gregorian on most devices).
    // .date(byAdding:value:to:) — arithmetic: subtract N days/months/years from today.
    // Date() — current date and time.
    // .date(from:) — construct a Date from DateComponents (e.g. first day of the year).
    //
    // .filter { } — keep only elements where the condition is true.
    // .map(\.netWorth) — transform array [NetWorthHistory] → [Double] by extracting .netWorth.
    // .min() / .max() — find smallest/largest value in a sequence (returns Optional, nil if empty).
    func recomputeCache() {
        let cutoff: Date?
        switch selectedRange {
        case "1W": cutoff = Calendar.current.date(byAdding: .day, value: -7, to: Date())
        case "1M": cutoff = Calendar.current.date(byAdding: .month, value: -1, to: Date())
        case "3M": cutoff = Calendar.current.date(byAdding: .month, value: -3, to: Date())
        case "YTD": cutoff = Calendar.current.date(from: Calendar.current.dateComponents([.year], from: Date()))
        case "1Y": cutoff = Calendar.current.date(byAdding: .year, value: -1, to: Date())
        default: cutoff = nil
        }
        if let cutoff = cutoff {
            cachedFilteredHistory = history.filter { point in
                guard let d = dateFormatter.date(from: point.date) else { return false }
                return d >= cutoff
            }
        } else {
            cachedFilteredHistory = history
        }
        cachedFilteredHistory = downsample(cachedFilteredHistory, for: selectedRange)
        let values = cachedFilteredHistory.map(\.netWorth)
        guard let minValue = values.min(), let maxValue = values.max() else {
            cachedYDomain = 0...20000
            return
        }
        guard minValue != maxValue else {
            let padding = max(abs(minValue) * 0.1, 1_000)
            cachedYDomain = (minValue - padding)...(maxValue + padding)
            return
        }
        let padding = (maxValue - minValue) * 0.1
        cachedYDomain = (minValue - padding)...(maxValue + padding)
    }

    var body: some View {
        // NavigationStack — SwiftUI navigation container (replaces old NavigationView in iOS 26).
        // Manages a stack of screens; here it just provides the nav bar area.
        NavigationStack {
            ScrollView(.vertical, showsIndicators: false) {
            // VStack — vertical layout. spacing: 0 means no gap between children.
            VStack(spacing: 0) {

                // ── HEADER: Net Worth label + badge, big number, change arrow ──
                VStack(alignment: .leading, spacing: 4) {
                    // HStack: "Net Worth+ as of Jul 8, 2026" (or date when hovering)
                    HStack(spacing: 2) {
                        Text("Net Worth")
                            .font(.custom("Palatino", size: 16))
                            .foregroundColor(.themeMuted)
                        if cachedFilteredHistory.count >= 2 {
                            Text(isPositive ? "+" : "−")
                                .font(.custom("Palatino", size: 10))
                                .foregroundColor(isPositive ? .green : .red)
                                .baselineOffset(8)
                        }
                        if isHovering {
                            Text("as of \(hoverDate)")
                                .font(.custom("Palatino", size: 12))
                                .foregroundColor(.themeMuted)
                        }
                        if !isHovering {
                            Text("as of \(latestHistoryDate)")
                                .font(.custom("Palatino", size: 12))
                                .foregroundColor(.themeMuted)
                        }
                    }

                    Text(netWorth, format: .currency(code: "USD"))
                        .font(.custom("Palatino", size: 36))
                        .foregroundColor(.themeText)

                    if let _ = hoveredEntry, cachedFilteredHistory.count >= 2 {
                        HStack(spacing: 4) {
                            Image(systemName: isPositive ? "arrow.up" : "arrow.down")
                                .font(.custom("Palatino", size: 14))
                            Text("\(change, specifier: "$%.2f") (\(changePercent, specifier: "%.2f")%)")
                                .font(.custom("Palatino", size: 14))
                        }
                        .foregroundColor(isPositive ? .green : .red)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading) // stretch horizontally, left-align
                .padding(.leading, 16) // .padding() — adds space on specified sides
                .padding(.top, 24)

                // ── CHART: Two lines with different colors ──
                Chart {
                    ForEach(leftSegment, id: \.id) { point in
                        LineMark(
                            x: .value("Date", point.date),
                            y: .value("Net Worth", point.netWorth),
                            series: .value("Segment", "active")
                        )
                        .foregroundStyle(isPositive ? Color.green : Color.red)
                    }
                    ForEach(rightSegment, id: \.id) { point in
                        LineMark(
                            x: .value("Date", point.date),
                            y: .value("Net Worth", point.netWorth),
                            series: .value("Segment", "dimmed")
                        )
                        .foregroundStyle(isPositive ? Color(light: Color.green.opacity(0.3), dark: Color(red: 0.05, green: 0.25, blue: 0.05)) : Color(light: Color.red.opacity(0.3), dark: Color(red: 0.25, green: 0.05, blue: 0.05)))
                    }
                    if cachedFilteredHistory.count == 1, let point = cachedFilteredHistory.first {
                        PointMark(
                            x: .value("Date", point.date),
                            y: .value("Net Worth", point.netWorth)
                        )
                        .foregroundStyle(point.netWorth >= 0 ? Color.green : Color.red)
                        .symbolSize(80)
                    }
                }
                .chartXAxis { AxisMarks { _ in } } // hide the X axis
                .chartYAxis { // configure Y axis labels
                    // AxisMarks(position: .trailing) — place labels on the right side.
                    AxisMarks(position: .trailing) { _ in
                        AxisValueLabel() // the number label itself
                        .foregroundStyle(Color.themeMuted)
                    }
                }
                .chartYScale(domain: cachedYDomain) // set explicit Y min/max range
                .frame(height: 260)
                .padding(.horizontal)
                .padding(.top, 8)

                // ── OVERLAY: Touch gesture + selection indicators ──
                // .chartOverlay { proxy in } — from Swift Charts.
                //   Closes over a ChartProxy which converts between data values and pixel positions.
                .chartOverlay { proxy in
                    // GeometryReader — SwiftUI container that reads its own size and position.
                    //   geometry[proxy.plotAreaFrame] — returns the plot area's CGRect
                    //   within the overlay (where the actual line marks are drawn).
                    GeometryReader { geometry in
                        let plot = proxy.plotFrame.map { geometry[$0] } ?? CGRect(x: 0, y: 0, width: 300, height: 260)
                        let origin = plot.origin // top-left corner of the plot area
                        ZStack(alignment: .topLeading) {
                            if let selected = selectedDate,
                               let entry = leftSegment.last {

                                // proxy.position(forX:) / proxy.position(forY:) —
                                //   Convert data values (date string, net worth number)
                                //   into pixel positions relative to the plot area origin.
                                let x = proxy.position(forX: selected) ?? 0
                                let y = proxy.position(forY: entry.netWorth) ?? 0
                                // pointX, pointY — absolute position in the overlay's coords
                                let pointX = origin.x + x
                                let pointY = origin.y + y
                                // labelY — clamped to stay at least 4px below the plot top
                                let labelY = max(pointY - 64, origin.y + 4)

                                // Path { } — SwiftUI shape for custom drawing.
                                //   path.move(to:) — move pen without drawing.
                                //   path.addLine(to:) — draw line from current point.
                                Path { path in
                                    path.move(to: CGPoint(x: pointX, y: origin.y + plot.height))
                                    path.addLine(to: CGPoint(x: pointX, y: labelY))
                                }
                                .stroke(Color.themeMuted.opacity(0.4), lineWidth: 1)
                                // .stroke() — outline a shape with color, opacity, thickness.

                                // Circle() — SwiftUI shape (elipse that fills its frame).
                                Circle()
                                    .fill(Color.themeAccent) // .fill() — fill the shape
                                    .frame(width: 8, height: 8) // constrain size
                                    .position(x: pointX, y: pointY) // .position() — absolute positioning
                                //   (places the view's center at (x, y) in the parent).

                                Text(formattedLabel(for: selected))
                                    .font(.custom("Palatino", size: 11))
                                    .foregroundColor(.themeText)
                                    .padding(.horizontal, 6) // internal horizontal padding
                                    .padding(.vertical, 3)   // internal vertical padding
                                    .position(x: pointX, y: labelY)
                            }

                            // .contentShape(Rectangle()) — sets the hit-test shape for gesture
                            //   detection. Without this, a clear/fill(.clear) view is untappable.
                            // .gesture() — attaches an interactive gesture to the view.
                            // DragGesture(minimumDistance: 0) — fires on both tap and drag.
                            //   .onChanged — fires continuously as the finger moves.
                            //   .onEnded — fires when the finger lifts.
                            Rectangle()
                                .fill(.clear)
                                .contentShape(Rectangle())
                                .simultaneousGesture(
                                    DragGesture(minimumDistance: 0)
                                        .onChanged { value in
                                            // value.location — CGPoint of the touch in the overlay.
                                            // Subtract origin.x to get position relative to plot.
                                            let x = value.location.x - origin.x
                                            let w = plot.width
                                            if x < 0 || x > w { return }
                                            // proxy.value(atX:) — inverse of position(forX:).
                                            //   Converts a pixel x-offset back into the nearest
                                            //   x-axis data value (the date string).
                                            guard let date: String = proxy.value(atX: x) else { return }
                                            selectedDate = date
                                            if let entry = cachedFilteredHistory.first(where: { $0.date == date }) {
                                                netWorth = entry.netWorth
                                            }

                                            // UIImpactFeedbackGenerator — UIKit haptic feedback.
                                            //   .light style = a subtle tap.
                                            UIImpactFeedbackGenerator(style: .light).impactOccurred()
                                        }
                                        .onEnded { _ in
                                            selectedDate = nil
                                            netWorth = originalNetWorth
                                        }
                                )
                        }
                    }
                }

                // ── TIME RANGE BUTTONS ──
                // ForEach(ranges, id: \.self) — iterate over the string array.
                //   \.self uses the string itself as the identity.
                HStack(spacing: 0) {
                    ForEach(ranges, id: \.self) { range in
                        Button {
                            selectedRange = range
                            selectedDate = nil
                            netWorth = originalNetWorth
                            recomputeCache()
                        } label: {
                            Text(range)
                                .font(.custom("Palatino", size: 12))
                                .foregroundColor(selectedRange == range ? .black : .themeMuted)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 6)
                                .background(
                                    RoundedRectangle(cornerRadius: 4)
                                        .fill(selectedRange == range ? Color.white : Color.clear)
                                )
                        }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.top, 12)

                // ── ACCOUNT MIX ──
                let totalBalance = accounts.map(\.balance).reduce(0, +)
                if totalBalance != 0 {
                    VStack(alignment: .leading, spacing: 14) {
                        Text("Account Mix")
                            .font(.custom("Palatino", size: 20))
                            .foregroundColor(.themeText)
                            .padding(.leading, 16)
                            .padding(.top, 20)

                        ForEach(accounts.sorted(by: { $0.balance > $1.balance })) { account in
                            let pct = totalBalance != 0 ? account.balance / totalBalance : 0
                            HStack(spacing: 12) {
                                Text(account.name)
                                    .font(.custom("Palatino", size: 16))
                                    .foregroundColor(.themeMuted)
                                    .frame(width: 120, alignment: .leading)

                                GeometryReader { geo in
                                    let barWidth = max(0, geo.size.width * pct)
                                    RoundedRectangle(cornerRadius: 3)
                                        .fill(Color.primary.opacity(0.15))
                                    RoundedRectangle(cornerRadius: 3)
                                        .fill(Color.primary)
                                        .frame(width: barWidth)
                                }
                                .frame(height: 8)

                                Text(account.balance, format: .currency(code: "USD"))
                                    .font(.custom("Palatino", size: 16))
                                    .foregroundColor(.themeText)
                                    .frame(width: 100, alignment: .trailing)

                                Text("\(pct * 100, specifier: "%.0f")%")
                                    .font(.custom("Palatino", size: 16))
                                    .foregroundColor(.themeMuted)
                                    .frame(width: 44, alignment: .trailing)
                            }
                            .padding(.horizontal, 16)
                        }
                    }
                }

                // ── DEBT OVERVIEW ──
                VStack(alignment: .leading, spacing: 14) {
                    HStack {
                        Text("Debt Overview")
                            .font(.custom("Palatino", size: 20))
                            .foregroundColor(.themeText)
                        Spacer()
                        if totalDebt > 0 {
                            Text(totalDebt, format: .currency(code: "USD"))
                                .font(.custom("Palatino", size: 16))
                                .foregroundColor(.red)
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 24)

                    if debtAccounts.isEmpty {
                        HStack(spacing: 12) {
                            Image(systemName: "checkmark.circle")
                                .font(.system(size: 14))
                                .foregroundColor(.green)
                                .frame(width: 28, height: 28)
                                .background(Color.green.opacity(0.1))
                                .cornerRadius(6)

                            Text("No outstanding debt")
                                .font(.custom("Palatino", size: 15))
                                .foregroundColor(.themeMuted)

                            Spacer()
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                        .background(Color.themeSurface)
                        .cornerRadius(10)
                        .padding(.horizontal, 16)
                    } else {
                        ForEach(debtAccounts) { acct in
                            HStack(spacing: 12) {
                                Image(systemName: "creditcard")
                                    .font(.system(size: 14))
                                    .foregroundColor(.red)
                                    .frame(width: 28, height: 28)
                                    .background(Color.red.opacity(0.1))
                                    .cornerRadius(6)

                                VStack(alignment: .leading, spacing: 2) {
                                    Text(acct.name)
                                        .font(.custom("Palatino", size: 15))
                                        .foregroundColor(.themeText)
                                    if let rate = acct.interestRate {
                                        Text("\(rate, specifier: "%.2f")% APR")
                                            .font(.custom("Palatino", size: 12))
                                            .foregroundColor(.themeMuted)
                                    }
                                }

                                Spacer()

                                Text(acct.balance, format: .currency(code: "USD"))
                                    .font(.custom("Palatino", size: 15))
                                    .foregroundColor(.red)
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 12)
                            .background(Color.themeSurface)
                            .cornerRadius(10)
                            .padding(.horizontal, 16)
                        }
                    }
                }

                // ── INVESTMENT PERFORMANCE ──
                VStack(alignment: .leading, spacing: 14) {
                    HStack {
                        Text("Investments")
                            .font(.custom("Palatino", size: 20))
                            .foregroundColor(.themeText)
                        Spacer()
                        if totalInvestments > 0 {
                            Text(totalInvestments, format: .currency(code: "USD"))
                                .font(.custom("Palatino", size: 16))
                                .foregroundColor(.green)
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 24)

                    if investmentAccounts.isEmpty {
                        Button {
                            Task {
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
                        } label: {
                            HStack(spacing: 12) {
                                Image(systemName: "plus.circle")
                                    .font(.system(size: 14))
                                    .foregroundColor(.themeMuted)
                                    .frame(width: 28, height: 28)
                                    .background(Color.themeSurface2)
                                    .cornerRadius(6)

                                Text("Add an Investment Account")
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
                        .padding(.horizontal, 16)
                    } else {
                        ForEach(investmentAccounts) { acct in
                            HStack(spacing: 12) {
                                Image(systemName: "chart.line.uptrend.xyaxis")
                                    .font(.system(size: 14))
                                    .foregroundColor(.green)
                                    .frame(width: 28, height: 28)
                                    .background(Color.green.opacity(0.1))
                                    .cornerRadius(6)

                                VStack(alignment: .leading, spacing: 2) {
                                    Text(acct.name)
                                        .font(.custom("Palatino", size: 15))
                                        .foregroundColor(.themeText)
                                    Text("Investment Account")
                                        .font(.custom("Palatino", size: 12))
                                        .foregroundColor(.themeMuted)
                                }

                                Spacer()

                                Text(acct.balance, format: .currency(code: "USD"))
                                    .font(.custom("Palatino", size: 15))
                                    .foregroundColor(.themeText)
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 12)
                            .background(Color.themeSurface)
                            .cornerRadius(10)
                            .padding(.horizontal, 16)
                        }
                    }
                }

                // ── CREDIT SCORE ──
                VStack(alignment: .leading, spacing: 14) {
                    Text("Credit Score")
                        .font(.custom("Palatino", size: 20))
                        .foregroundColor(.themeText)
                        .padding(.leading, 16)
                        .padding(.top, 24)

                    VStack(spacing: 14) {
                        if creditScore > 0 {
                            HStack(alignment: .center, spacing: 12) {
                                VStack(alignment: .leading, spacing: 4) {
                                    HStack(alignment: .lastTextBaseline, spacing: 6) {
                                        Text("\(creditScore)")
                                            .font(.custom("Palatino", size: 22))
                                            .fontWeight(.medium)
                                            .foregroundColor(.themeText)

                                        if creditScoreChange != 0 {
                                            HStack(spacing: 2) {
                                                Image(systemName: creditScoreImproved ? "arrow.up" : "arrow.down")
                                                    .font(.system(size: 10, weight: .bold))
                                                Text("\(abs(creditScoreChange))")
                                                    .font(.custom("Palatino", size: 12))
                                            }
                                            .foregroundColor(creditScoreImproved ? .green : .orange)
                                        }
                                    }
                                }

                                Spacer()

                                // ── 5 BARS + MARKER ──
                                let barColors: [Color] = [.red, .orange, Color(red: 1.0, green: 0.85, blue: 0.0), .green, Color(red: 0.05, green: 0.4, blue: 0.1)]
                                let barWidth: CGFloat = 34
                                let barSpacing: CGFloat = 16
                                let circleRadius: CGFloat = 4
                                let totalBarWidth = barWidth * 5 + barSpacing * 4
                                let segmentIndex: Int = {
                                    switch creditScore {
                                    case 300..<500: return 0
                                    case 500..<600: return 1
                                    case 600..<661: return 2
                                    case 661..<781: return 3
                                    case 781...850: return 4
                                    default: return creditScore < 300 ? 0 : 4
                                    }
                                }()
                                let segmentRanges: [(min: Double, max: Double)] = [(300,499),(500,599),(600,660),(661,780),(781,850)]
                                let range = segmentRanges[segmentIndex]
                                let segmentFraction = CGFloat((Double(creditScore) - range.min) / (range.max - range.min))
                                let exactX = max(0, min(1, segmentFraction)) * barWidth
                                let snapMargin: CGFloat = 8
                                let snappedX = exactX < snapMargin
                                    ? circleRadius
                                    : exactX > barWidth - snapMargin
                                        ? barWidth - circleRadius
                                        : exactX
                                let markerPosition = CGFloat(segmentIndex) * (barWidth + barSpacing) + snappedX

                                ZStack(alignment: .leading) {
                                    HStack(spacing: barSpacing) {
                                        ForEach(0..<5, id: \.self) { i in
                                            RoundedRectangle(cornerRadius: 3)
                                                .fill(barColors[i])
                                                .frame(width: barWidth, height: 4)
                                        }
                                    }

                                    Circle()
                                        .fill(Color.themeSurface)
                                        .overlay(
                                            Circle()
                                                .stroke(barColors[segmentIndex], lineWidth: 3)
                                        )
                                        .frame(width: circleRadius * 2, height: circleRadius * 2)
                                        .offset(x: markerPosition - circleRadius)
                                }
                                .frame(width: totalBarWidth, height: 14)
                                .clipped()
                            }
                            .padding(.horizontal, 16)
                        } else {
                            Text("Tap to add credit score")
                                .font(.custom("Palatino", size: 15))
                                .foregroundColor(.themeMuted)
                                .padding(.horizontal, 16)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .onTapGesture {
                                    creditScoreInput = ""
                                    showCreditScoreEntry = true
                                }
                        }

                        Text("Last updated \(creditScoreDateFormatter.string(from: lastCreditScoreUpdate))")
                            .font(.custom("Palatino", size: 11))
                            .foregroundColor(.themeMuted)
                            .padding(.horizontal, 16)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(Color.themeSurface)
                    .cornerRadius(10)
                    .padding(.horizontal, 16)
                    .onTapGesture {
                        creditScoreInput = creditScore > 0 ? "\(creditScore)" : ""
                        showCreditScoreEntry = true
                    }
                }
                .sheet(isPresented: $showCreditScoreEntry) {
                    VStack(spacing: 0) {
                        HStack {
                            Text("Update Credit Score")
                                .font(.custom("Palatino", size: 17))
                                .fontWeight(.semibold)
                                .foregroundColor(.themeText)
                            Spacer()
                            Button("Cancel") {
                                showCreditScoreEntry = false
                            }
                            .font(.custom("Palatino", size: 15))
                            .foregroundColor(.themeMuted)
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 20)
                        .padding(.bottom, 16)

                        TextField("e.g. 742", text: $creditScoreInput)
                            .font(.custom("Palatino", size: 28))
                            .fontWeight(.medium)
                            .foregroundColor(.themeText)
                            .keyboardType(.numberPad)
                            .multilineTextAlignment(.center)
                            .padding(.vertical, 20)
                            .frame(maxWidth: .infinity)
                            .background(Color.themeBackground)
                            .cornerRadius(10)
                            .padding(.horizontal, 20)

                        Button {
                            Task { await saveCreditScore() }
                        } label: {
                            if isSavingCreditScore {
                                ProgressView()
                                    .frame(height: 20)
                            } else {
                                Text("Save")
                                    .font(.custom("Palatino", size: 16))
                                    .foregroundColor(.white)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 14)
                                    .background(Color.green)
                                    .cornerRadius(10)
                            }
                        }
                        .disabled(creditScoreInput.isEmpty || isSavingCreditScore)
                        .padding(.horizontal, 20)
                        .padding(.top, 12)

                        Spacer()
                    }
                    .background(Color.themeBackground)
                    .presentationDetents([.medium])
                }
                .sheet(isPresented: $showPlaidLink) {
                    if let token = linkToken {
                        PlaidLinkView(
                            linkToken: token,
                            onComplete: { publicToken, institutionId, institutionName in
                                showPlaidLink = false
                                Task {
                                    let api = APIClient()
                                    try? await api.exchangePlaidToken(publicToken: publicToken, institutionId: institutionId, institutionName: institutionName)
                                    await loadData()
                                }
                            },
                            onCancel: {
                                showPlaidLink = false
                            }
                        )
                        .ignoresSafeArea()
                    }
                }

                // ── MONTHLY CASH FLOW ──
                if !monthlyCashFlow.isEmpty {
                    VStack(alignment: .leading, spacing: 14) {
                        Text("Monthly Cash Flow")
                            .font(.custom("Palatino", size: 20))
                            .foregroundColor(.themeText)
                            .padding(.leading, 16)
                            .padding(.top, 24)

                        HStack(spacing: 16) {
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Income")
                                    .font(.custom("Palatino", size: 12))
                                    .foregroundColor(.themeMuted)
                                Text(totalIncome, format: .currency(code: "USD"))
                                    .font(.custom("Palatino", size: 16))
                                    .foregroundColor(.green)
                            }
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Expenses")
                                    .font(.custom("Palatino", size: 12))
                                    .foregroundColor(.themeMuted)
                                Text(totalExpenses, format: .currency(code: "USD"))
                                    .font(.custom("Palatino", size: 16))
                                    .foregroundColor(.red)
                            }
                            Spacer()
                            VStack(alignment: .trailing, spacing: 2) {
                                Text("Savings Rate")
                                    .font(.custom("Palatino", size: 12))
                                    .foregroundColor(.themeMuted)
                                Text("\(savingsRate, specifier: "%.1f")%")
                                    .font(.custom("Palatino", size: 16))
                                    .foregroundColor(savingsRate >= 0 ? .green : .red)
                            }
                        }
                        .padding(.horizontal, 16)

                        Chart {
                            ForEach(monthlyCashFlow) { month in
                                BarMark(
                                    x: .value("Month", month.label),
                                    y: .value("Amount", month.income)
                                )
                                .foregroundStyle(.green.opacity(0.7))
                                BarMark(
                                    x: .value("Month", month.label),
                                    y: .value("Amount", month.expenses)
                                )
                                .foregroundStyle(.red.opacity(0.7))
                            }
                        }
                        .chartXAxis {
                            AxisMarks { _ in
                                AxisValueLabel()
                                    .foregroundStyle(Color.themeMuted)
                            }
                        }
                        .chartYAxis {
                            AxisMarks(position: .trailing) { _ in
                                AxisValueLabel()
                                    .foregroundStyle(Color.themeMuted)
                            }
                        }
                        .frame(height: 160)
                        .padding(.horizontal, 16)
                    }
                }

                // ── PROJECTIONS ──
                NavigationLink {
                    ProjectionsView()
                } label: {
                    HStack(spacing: 12) {
                        Image(systemName: "chart.line.uptrend.xyaxis")
                            .font(.system(size: 14))
                            .foregroundColor(.green)
                            .frame(width: 28, height: 28)
                            .background(Color.green.opacity(0.1))
                            .cornerRadius(6)

                        Text("Projections")
                            .font(.custom("Palatino", size: 15))
                            .foregroundColor(.themeText)

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
                .padding(.horizontal, 16)
                .padding(.top, 24)

                // Spacer() — flexible empty space that pushes everything above it upward.
                Spacer()
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color.themeBackground) // fills the entire background
        }
        .scrollContentBackground(.hidden)
        }

        .toolbarBackground(Color.themeBackground, for: .navigationBar)
        .background(Color.themeBackground)

        // .task { } — SwiftUI modifier that runs an async closure when the view appears.
        //   Automatically cancelled if the view disappears. Unlike .onAppear which can't use await.
        .toolbarBackground(Color.themeBackground, for: .navigationBar)
        .task {
            await loadData()
        }
    }

    // try? — convert throwing function into Optional (nil on error).
    // await — suspend function until async operation completes (non-blocking).
    // ?? — nil-coalescing operator: use left side if non-nil, otherwise right side.
    func loadData() async {
        let api = APIClient()
        netWorth = (try? await api.getNetWorth())?.netWorth ?? 0
        originalNetWorth = netWorth
        history = (try? await api.getNetWorthHistory()) ?? []
        accounts = (try? await api.getAccounts()) ?? []
        transactions = (try? await api.getTransactions()) ?? []

        let cs = (try? await api.getCreditScore()) 
        if let cs = cs, cs.score > 0 {
            creditScore = cs.score
            if let prev = cs.previousScore {
                previousCreditScore = prev
            } else {
                previousCreditScore = cs.score
            }
            if let dateStr = cs.date, let d = dateFormatter.date(from: dateStr) {
                lastCreditScoreUpdate = d
            }
        }

        recomputeCache()
    }

    func saveCreditScore() async {
        guard let score = Int(creditScoreInput), score >= 300, score <= 850 else { return }
        isSavingCreditScore = true
        let api = APIClient()
        let _ = try? await api.recordCreditScore(score: score)
        showCreditScoreEntry = false
        isSavingCreditScore = false

        let cs = (try? await api.getCreditScore())
        if let cs = cs, cs.score > 0 {
            creditScore = cs.score
            if let prev = cs.previousScore {
                previousCreditScore = prev
            } else {
                previousCreditScore = cs.score
            }
            if let dateStr = cs.date, let d = dateFormatter.date(from: dateStr) {
                lastCreditScoreUpdate = d
            }
        }
    }
}

// #Preview — Xcode preview canvas. Shows the view with dark mode forced on.
#Preview {
    PortfolioView()
        .preferredColorScheme(.dark) // .preferredColorScheme() — hint to use dark palette
}
