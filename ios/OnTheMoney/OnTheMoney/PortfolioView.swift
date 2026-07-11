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

    let ranges = ["1W", "1M", "3M", "YTD", "1Y", "ALL"]

    // DateFormatter() — Foundation class. Converts Date <-> String.
    // This closure runs once when the struct is created (lazy stored property pattern).
    private let dateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd" // sets the pattern that parse/format uses
        return f
    }()
    private let dateOnlyFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "MMM d, yyyy" // outputs like "May 14, 2026"
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
        guard let min = values.min(), let max = values.max(), min != max else {
            cachedYDomain = 0...20000
            return
        }
        let padding = (max - min) * 0.1
        cachedYDomain = (min - padding)...(max + padding)
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
                        Text(inTheRed ? "−" : "+")
                            .font(.custom("Palatino", size: 10))
                            .foregroundColor(inTheRed ? .red : .green)
                            .baselineOffset(8)
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
                        .foregroundStyle(isPositive ? Color(red: 0.05, green: 0.25, blue: 0.05) : Color(red: 0.25, green: 0.05, blue: 0.05))
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
                        let plot = geometry[proxy.plotAreaFrame]
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
                                    RoundedRectangle(cornerRadius: 3)
                                        .fill(Color.white.opacity(0.15))
                                        .frame(width: geo.size.width)
                                    RoundedRectangle(cornerRadius: 3)
                                        .fill(Color.white)
                                        .frame(width: geo.size.width * pct)
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

                // Spacer() — flexible empty space that pushes everything above it upward.
                Spacer()
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color.themeBackground) // fills the entire background
        }
        }

        // .task { } — SwiftUI modifier that runs an async closure when the view appears.
        //   Automatically cancelled if the view disappears. Unlike .onAppear which can't use await.
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
        recomputeCache()
    }
}

// #Preview — Xcode preview canvas. Shows the view with dark mode forced on.
#Preview {
    PortfolioView()
        .preferredColorScheme(.dark) // .preferredColorScheme() — hint to use dark palette
}
