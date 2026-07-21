import SwiftUI
import Charts

struct ProjectionLine: Identifiable {
    let id = UUID()
    let year: Int
    let value: Double
    let scenario: String
}

struct ProjectionsView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var initialBalance: String = ""
    @State private var monthlyContribution: String = ""
    @State private var returnRate: String = ""
    @State private var years: String = ""
    @State private var result: ProjectionResponse?
    @State private var isLoading = false
    @State private var hasRun = false
    @State private var showError = false

    private var chartData: [ProjectionLine] {
        guard let result else { return [] }
        var lines: [ProjectionLine] = []

        if let worst = result.worst10Trajectory {
            for (i, val) in worst.enumerated() {
                lines.append(ProjectionLine(year: i, value: val, scenario: "Pessimistic"))
            }
        }
        if let median = result.medianTrajectory {
            for (i, val) in median.enumerated() {
                lines.append(ProjectionLine(year: i, value: val, scenario: "Median"))
            }
        }
        if let mean = result.meanTrajectory {
            for (i, val) in mean.enumerated() {
                lines.append(ProjectionLine(year: i, value: val, scenario: "Mean"))
            }
        }
        if let best = result.best10Trajectory {
            for (i, val) in best.enumerated() {
                lines.append(ProjectionLine(year: i, value: val, scenario: "Optimistic"))
            }
        }
        return lines
    }

    private var maxChartValue: Double {
        guard let result else { return 100000 }
        let vals = [result.worst10 ?? 0, result.median ?? 0, result.best10 ?? 0, result.mean ?? 0]
        return vals.max() ?? 100000
    }

    var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(alignment: .leading, spacing: 0) {
                HStack {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.themeMuted)
                        .onTapGesture { dismiss() }
                    Spacer()
                    Button {
                        Task { await runProjection() }
                    } label: {
                        Group {
                            if isLoading {
                                ProgressView()
                                    .tint(.themeAccent)
                            } else {
                                Image(systemName: "play.fill")
                                    .font(.system(size: 13))
                                    .foregroundColor(.themeAccent)
                            }
                        }
                        .frame(width: 32, height: 32)
                        .background(Color.themeSurface)
                        .cornerRadius(8)
                    }
                    .buttonStyle(.plain)
                    .disabled(isLoading)
                }
                .padding(.horizontal, 16)
                .padding(.top, 8)
                .padding(.bottom, 12)

                // ── RESULTS ──
                // Summary cards
                        VStack(alignment: .leading, spacing: 14) {
                            Text("Results")
                                .font(.custom("Palatino", size: 20))
                                .foregroundColor(.themeText)
                                .padding(.top, 28)

                            HStack(spacing: 10) {
                                summaryCard(title: "Pessimistic", value: result?.worst10, color: .red)
                                summaryCard(title: "Median", value: result?.median, color: .themeAccent)
                            }
                            HStack(spacing: 10) {
                                summaryCard(title: "Optimistic", value: result?.best10, color: .green)
                                summaryCard(title: "Mean", value: result?.mean, color: .blue)
                            }
                        }
                        .padding(.horizontal, 16)

                        // Chart
                        VStack(alignment: .leading, spacing: 14) {
                            Text("Growth Over Time")
                                .font(.custom("Palatino", size: 20))
                                .foregroundColor(.themeText)
                                .padding(.top, 28)

                            Chart(chartData) { line in
                                // area gradient under each line
                                AreaMark(
                                    x: .value("Year", line.year),
                                    y: .value("Balance", line.value),
                                    series: .value("Scenario", line.scenario)
                                )
                                .foregroundStyle(
                                    LinearGradient(
                                        colors: [
                                            colorForScenario(line.scenario).opacity(line.scenario == "Median" ? 0.25 : 0.12),
                                            colorForScenario(line.scenario).opacity(0.0)
                                        ],
                                        startPoint: .top,
                                        endPoint: .bottom
                                    )
                                )
                                .interpolationMethod(.catmullRom)

                                LineMark(
                                    x: .value("Year", line.year),
                                    y: .value("Balance", line.value),
                                    series: .value("Scenario", line.scenario)
                                )
                                .foregroundStyle(colorForScenario(line.scenario))
                                .lineStyle(StrokeStyle(
                                    lineWidth: line.scenario == "Median" ? 2.5 : 1.5,
                                    lineCap: .round,
                                    lineJoin: .round
                                ))
                                .interpolationMethod(.catmullRom)
                            }
                            .chartForegroundStyleScale([
                                "Pessimistic": .red,
                                "Median": .themeAccent,
                                "Mean": .blue,
                                "Optimistic": .green
                            ])
                            .chartYScale(domain: 0...maxChartValue * 1.1)
                            .chartXAxis {
                                AxisMarks(position: .bottom) { value in
                                    AxisGridLine(stroke: StrokeStyle(dash: [4]))
                                    AxisValueLabel {
                                        if let year = value.as(Int.self) {
                                            Text("Y\(year)")
                                                .font(.custom("Palatino", size: 10))
                                                .foregroundColor(.themeMuted)
                                        }
                                    }
                                }
                            }
                            .chartYAxis {
                                AxisMarks(position: .leading) { value in
                                    AxisGridLine(stroke: StrokeStyle(dash: [4]))
                                    AxisValueLabel {
                                        if let val = value.as(Double.self) {
                                            Text(formatLargeNumber(val))
                                                .font(.custom("Palatino", size: 10))
                                                .foregroundColor(.themeMuted)
                                        }
                                    }
                                }
                            }
                            .frame(height: 260)

                            // Legend
                            HStack(spacing: 16) {
                                legendDot(color: .red, label: "10th %ile")
                                legendDot(color: .themeAccent, label: "Median")
                                legendDot(color: .blue, label: "Mean")
                                legendDot(color: .green, label: "90th %ile")
                            }
                            .frame(maxWidth: .infinity)
                        }
                        .padding(.horizontal, 16)

                        // Simulation info
                        HStack {
                            Image(systemName: "info.circle")
                                .font(.system(size: 11))
                                .foregroundColor(.themeMuted)
                            Text("Based on \(result?.simulations?.formatted() ?? "—") Monte Carlo simulations over \(result?.years ?? 0) years")
                                .font(.custom("Palatino", size: 12))
                                .foregroundColor(.themeMuted)
                        }
                        .padding(.horizontal, 16)
                        .padding(.top, 12)
                // ── INPUTS ──
                VStack(alignment: .leading, spacing: 16) {
                    Text("Make a Projection")
                        .font(.custom("Palatino", size: 20))
                        .foregroundColor(.themeText)
                        .padding(.top, 28)

                    inputRow(label: "Starting Balance", placeholder: "$10,000", text: $initialBalance, icon: "dollarsign.circle")
                    inputRow(label: "Monthly Contribution", placeholder: "$500", text: $monthlyContribution, icon: "plus.circle")
                    inputRow(label: "Expected Annual Return", placeholder: "7%", text: $returnRate, icon: "chart.line.uptrend.xyaxis")
                    inputRow(label: "Time Horizon", placeholder: "30 years", text: $years, icon: "calendar")

                }
                .padding(.horizontal, 16)

                Spacer(minLength: 40)
            }
        }
        .background(Color.themeBackground)
        .scrollContentBackground(.hidden)
        .navigationBarHidden(true)
    }

    // MARK: - Helpers

    func inputRow(label: String, placeholder: String, text: Binding<String>, icon: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 12))
                    .foregroundColor(.themeMuted)
                Text(label)
                    .font(.custom("Palatino", size: 14))
                    .foregroundColor(.themeMuted)
            }
            TextField(placeholder, text: text)
                .font(.custom("Palatino", size: 16))
                .foregroundColor(.themeText)
                .keyboardType(.decimalPad)
                .padding(12)
                .background(Color.themeSurface)
                .cornerRadius(10)
        }
    }

    func summaryCard(title: String, value: Double?, color: Color) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.custom("Palatino", size: 13))
                .foregroundColor(.themeMuted)
            Text(value.map(formatCurrency) ?? "-")
                .font(.custom("Palatino", size: 18))
                .foregroundColor(color)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(Color.themeSurface)
        .cornerRadius(10)
    }

    func legendDot(color: Color, label: String) -> some View {
        HStack(spacing: 5) {
            Circle().fill(color).frame(width: 8, height: 8)
            Text(label)
                .font(.custom("Palatino", size: 11))
                .foregroundColor(.themeMuted)
        }
    }

    func colorForScenario(_ scenario: String) -> Color {
        switch scenario {
        case "Pessimistic": return .red
        case "Median": return .themeAccent
        case "Mean": return .blue
        case "Optimistic": return .green
        default: return .gray
        }
    }

    func formatCurrency(_ value: Double) -> String {
        if value >= 1_000_000 {
            return String(format: "$%.1fM", value / 1_000_000)
        } else if value >= 1_000 {
            return String(format: "$%.0fK", value / 1_000)
        }
        return String(format: "$%.0f", value)
    }

    func formatLargeNumber(_ value: Double) -> String {
        if value >= 1_000_000 {
            return String(format: "%.1fM", value / 1_000_000)
        } else if value >= 1_000 {
            return String(format: "%.0fK", value / 1_000)
        }
        return String(format: "%.0f", value)
    }

    // MARK: - API

    func runProjection() async {
        isLoading = true
        showError = false
        hasRun = false

        let ib = Double(initialBalance.replacingOccurrences(of: "$", with: "").replacingOccurrences(of: ",", with: "")) ?? 10000
        let mc = Double(monthlyContribution.replacingOccurrences(of: "$", with: "").replacingOccurrences(of: ",", with: "")) ?? 500
        let rr = Double(returnRate.replacingOccurrences(of: "%", with: "")) ?? 7
        let yr = Int(years) ?? 30

        let api = APIClient()
        do {
            result = try await api.projectRetirement(
                initialBalance: ib,
                monthlyContribution: mc,
                returnRate: rr,
                years: yr,
                simulations: 10000
            )
            hasRun = true
        } catch {
            showError = true
        }
        isLoading = false
    }
}

#Preview {
    NavigationStack {
        ProjectionsView()
            .preferredColorScheme(.dark)
    }
}
