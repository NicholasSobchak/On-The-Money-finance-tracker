import SwiftUI
import Charts

struct PortfolioView: View {
    @State private var netWorth = 0.0
    @State private var originalNetWorth = 0.0
    @State private var history: [NetWorthHistory] = []
    @State private var selectedRange = "ALL"
    @State private var selectedDate: String?
    @State private var cachedFilteredHistory: [NetWorthHistory] = []
    @State private var cachedYDomain: ClosedRange<Double> = 0...20000

    let ranges = ["1W", "1M", "3M", "YTD", "1Y", "ALL"]

    private let dateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        return f
    }()
    private let dateOnlyFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "MMM d, yyyy"
        return f
    }()

    var isHovering: Bool { selectedDate != nil }

    var hoverDate: String {
        guard let d = selectedDate.flatMap({ dateFormatter.date(from: $0) }) else { return "" }
        return dateOnlyFormatter.string(from: d)
    }

    var hoveredEntry: NetWorthHistory? {
        guard cachedFilteredHistory.count >= 2 else { return nil }
        if let date = selectedDate {
            return cachedFilteredHistory.first(where: { $0.date == date })
        }
        return cachedFilteredHistory.last
    }

    var change: Double {
        guard cachedFilteredHistory.count >= 2, let entry = hoveredEntry else { return 0 }
        return entry.netWorth - cachedFilteredHistory.first!.netWorth
    }

    var changePercent: Double {
        guard cachedFilteredHistory.count >= 2, let entry = hoveredEntry, cachedFilteredHistory.first!.netWorth != 0 else { return 0 }
        return (change / cachedFilteredHistory.first!.netWorth) * 100
    }

    var isPositive: Bool { change >= 0 }

    func formattedLabel(for dateString: String) -> String {
        guard let d = dateFormatter.date(from: dateString) else { return dateString }
        return dateOnlyFormatter.string(from: d)
    }

    var leftSegment: [NetWorthHistory] {
        guard let selected = selectedDate else { return cachedFilteredHistory }
        let idx = cachedFilteredHistory.firstIndex(where: { $0.date == selected }) ?? cachedFilteredHistory.count - 1
        return Array(cachedFilteredHistory.prefix(idx + 1))
    }

    var rightSegment: [NetWorthHistory] {
        guard let selected = selectedDate,
              let idx = cachedFilteredHistory.firstIndex(where: { $0.date == selected }),
              idx + 1 < cachedFilteredHistory.count else { return [] }
        return Array(cachedFilteredHistory.suffix(from: idx))
    }

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
        let values = cachedFilteredHistory.map(\.netWorth)
        guard let min = values.min(), let max = values.max(), min != max else {
            cachedYDomain = 0...20000
            return
        }
        let padding = (max - min) * 0.1
        cachedYDomain = (min - padding)...(max + padding)
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(isHovering ? hoverDate : "Net Worth")
                        .font(.custom("Palatino", size: 16))
                        .foregroundColor(.themeMuted)
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
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.leading, 16)
                .padding(.top, 24)

                Chart {
                    ForEach(leftSegment, id: \.id) { point in
                        LineMark(
                            x: .value("Date", point.date),
                            y: .value("Net Worth", point.netWorth)
                        )
                        .foregroundStyle(Color.themeAccent)
                    }
                    ForEach(rightSegment, id: \.id) { point in
                        LineMark(
                            x: .value("Date", point.date),
                            y: .value("Net Worth", point.netWorth)
                        )
                        .foregroundStyle(Color.themeAccent.opacity(0.3))
                    }
                }
                .chartXAxis { AxisMarks { _ in } }
                .chartYAxis {
                    AxisMarks(position: .trailing) { _ in
                        AxisValueLabel()
                            .foregroundStyle(Color.themeMuted)
                    }
                }
                .chartYScale(domain: cachedYDomain)
                .frame(height: 260)
                .padding(.horizontal)
                .padding(.top, 8)
                .chartOverlay { proxy in
                    GeometryReader { geometry in
                        let plot = geometry[proxy.plotAreaFrame]
                        let origin = plot.origin
                        ZStack(alignment: .topLeading) {
                            if let selected = selectedDate,
                               let entry = leftSegment.last {
                                let x = proxy.position(forX: selected) ?? 0
                                let y = proxy.position(forY: entry.netWorth) ?? 0
                                let pointX = origin.x + x
                                let pointY = origin.y + y
                                let labelY = max(pointY - 64, origin.y + 4)

                                Path { path in
                                    path.move(to: CGPoint(x: pointX, y: origin.y + plot.height))
                                    path.addLine(to: CGPoint(x: pointX, y: labelY))
                                }
                                .stroke(Color.themeMuted.opacity(0.4), lineWidth: 1)

                                Circle()
                                    .fill(Color.themeAccent)
                                    .frame(width: 8, height: 8)
                                    .position(x: pointX, y: pointY)

                                Text(formattedLabel(for: selected))
                                    .font(.custom("Palatino", size: 11))
                                    .foregroundColor(.themeText)
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 3)
                                    .position(x: pointX, y: labelY)
                            }

                            Rectangle()
                                .fill(.clear)
                                .contentShape(Rectangle())
                                .gesture(
                                    DragGesture(minimumDistance: 0)
                                        .onChanged { value in
                                            let x = value.location.x - origin.x
                                            let w = plot.width
                                            if x < 0 || x > w { return }
                                            guard let date: String = proxy.value(atX: x) else { return }
                                            selectedDate = date
                                            if let entry = cachedFilteredHistory.first(where: { $0.date == date }) {
                                                netWorth = entry.netWorth
                                            }
                                        }
                                        .onEnded { _ in
                                            selectedDate = nil
                                            netWorth = originalNetWorth
                                        }
                                )
                        }
                    }
                }

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
                                .foregroundColor(selectedRange == range ? .white : .themeMuted)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 6)
                                .background(
                                    selectedRange == range
                                        ? Color.themeAccent
                                        : Color.clear
                                )
                                .cornerRadius(6)
                        }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.top, 12)

                Spacer()
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color.themeBackground)
        }
        .task {
            await loadData()
        }
    }

    func loadData() async {
        let api = APIClient()
        netWorth = (try? await api.getNetWorth())?.netWorth ?? 0
        originalNetWorth = netWorth
        history = (try? await api.getNetWorthHistory()) ?? []
        recomputeCache()
    }
}

#Preview {
    PortfolioView()
        .preferredColorScheme(.dark)
}
