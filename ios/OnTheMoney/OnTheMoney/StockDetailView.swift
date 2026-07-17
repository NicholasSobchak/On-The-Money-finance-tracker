import SwiftUI

struct StockDetailView: View {
    @AppStorage("currency") private var currency = "USD"
    @Environment(\.dismiss) private var dismiss
    let stock: StockQuote

    @State private var quote: StockQuote

    init(stock: StockQuote) {
        self.stock = stock
        _quote = State(initialValue: stock)
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
                }
                .padding(.horizontal, 16)
                .padding(.top, 8)
                .padding(.bottom, 12)

                VStack(alignment: .leading, spacing: 5) {
                    Text(quote.symbol)
                        .font(.custom("Palatino", size: 28))
                        .foregroundColor(.themeText)
                    Text(quote.name)
                        .font(.custom("Palatino", size: 15))
                        .foregroundColor(.themeMuted)
                        .lineLimit(2)
                }
                .padding(.horizontal, 16)

                VStack(alignment: .leading, spacing: 6) {
                    Text(quote.currentPrice, format: .currency(code: currency))
                        .font(.custom("Palatino", size: 34))
                        .foregroundColor(.themeText)
                    HStack(spacing: 5) {
                        Image(systemName: quote.change >= 0 ? "arrow.up" : "arrow.down")
                            .font(.system(size: 11, weight: .bold))
                        Text("\(quote.change, format: .currency(code: currency)) (\(quote.percentChange, specifier: "%+.2f")%)")
                            .font(.custom("Palatino", size: 15))
                    }
                    .foregroundColor(quote.change >= 0 ? .green : .red)
                }
                .padding(.horizontal, 16)
                .padding(.top, 18)

                VStack(alignment: .leading, spacing: 14) {
                    Text("Today's Range")
                        .font(.custom("Palatino", size: 20))
                        .foregroundColor(.themeText)

                    dailyRangeChart
                }
                .padding(.horizontal, 16)
                .padding(.top, 28)

                VStack(alignment: .leading, spacing: 14) {
                    Text("Market Details")
                        .font(.custom("Palatino", size: 20))
                        .foregroundColor(.themeText)

                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                        detailCard(title: "Open", value: quote.open)
                        detailCard(title: "Previous Close", value: quote.previousClose)
                        detailCard(title: "Day High", value: quote.high)
                        detailCard(title: "Day Low", value: quote.low)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.top, 28)

                Spacer(minLength: 40)
            }
        }
        .background(Color.themeBackground)
        .scrollContentBackground(.hidden)
        .navigationBarHidden(true)
        .task { await loadStockData() }
    }

    private var dailyRangeChart: some View {
        VStack(spacing: 12) {
            GeometryReader { geometry in
                let range = max(quote.high - quote.low, 0.01)
                let currentPosition = min(max((quote.currentPrice - quote.low) / range, 0), 1)
                let openPosition = min(max((quote.open - quote.low) / range, 0), 1)
                let previousClosePosition = min(max((quote.previousClose - quote.low) / range, 0), 1)

                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(Color.themeSurface2)
                        .frame(height: 8)

                    Circle()
                        .fill(Color.themeMuted)
                        .frame(width: 10, height: 10)
                        .position(x: geometry.size.width * openPosition, y: 4)

                    Rectangle()
                        .fill(Color.themeMuted)
                        .frame(width: 2, height: 20)
                        .position(x: geometry.size.width * previousClosePosition, y: 4)

                    Circle()
                        .fill(quote.change >= 0 ? Color.green : Color.red)
                        .frame(width: 14, height: 14)
                        .position(x: geometry.size.width * currentPosition, y: 4)
                }
            }
            .frame(height: 20)

            HStack {
                Text(quote.low, format: .currency(code: currency))
                Spacer()
                Text(quote.high, format: .currency(code: currency))
            }
            .font(.custom("Palatino", size: 12))
            .foregroundColor(.themeMuted)

            HStack(spacing: 14) {
                rangeLegend(color: .themeMuted, label: "Open")
                rangeLegend(color: .themeMuted, label: "Previous close", isLine: true)
                rangeLegend(color: quote.change >= 0 ? .green : .red, label: "Current")
            }
            .frame(maxWidth: .infinity)
        }
        .padding(16)
        .background(Color.themeSurface)
        .cornerRadius(12)
    }

    private func detailCard(title: String, value: Double) -> some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(title)
                .font(.custom("Palatino", size: 13))
                .foregroundColor(.themeMuted)
            Text(value, format: .currency(code: currency))
                .font(.custom("Palatino", size: 16))
                .foregroundColor(.themeText)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(Color.themeSurface)
        .cornerRadius(10)
    }

    private func rangeLegend(color: Color, label: String, isLine: Bool = false) -> some View {
        HStack(spacing: 5) {
            if isLine {
                Rectangle().fill(color).frame(width: 2, height: 10)
            } else {
                Circle().fill(color).frame(width: 8, height: 8)
            }
            Text(label)
                .font(.custom("Palatino", size: 11))
                .foregroundColor(.themeMuted)
        }
    }

    private func loadStockData() async {
        let api = APIClient()
        if let latestQuote = try? await api.getStockQuote(symbol: stock.symbol) {
            quote = latestQuote
        }
    }
}

#Preview {
    NavigationStack {
        StockDetailView(stock: StockQuote(symbol: "AAPL", name: "Apple Inc.", currentPrice: 200, change: 1.5, percentChange: 0.75, high: 202, low: 198, open: 199, previousClose: 198.5))
            .preferredColorScheme(.dark)
    }
}
