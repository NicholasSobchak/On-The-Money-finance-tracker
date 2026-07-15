import SwiftUI

struct StocksView: View {
    @State private var marketIndices: [StockQuote] = []
    @State private var topStocks: [StockQuote] = []
    @State private var searchText = ""
    @State private var searchResults: [SearchResult] = []
    @State private var isSearching = false
    @State private var watchlist: [StockQuote] = []
    @State private var isLoading = false

    private let topSymbols = ["AAPL", "MSFT", "GOOGL", "AMZN", "NVDA"]

    var body: some View {
        NavigationStack {
            ScrollView(.vertical, showsIndicators: false) {
                VStack(alignment: .leading, spacing: 0) {

                    // ── MARKET OVERVIEW ──
                    VStack(alignment: .leading, spacing: 14) {
                        HStack {
                            Text("Market Overview")
                                .font(.custom("Palatino", size: 20))
                                .foregroundColor(.themeText)

                            Spacer()

                            NavigationLink {
                                ProjectionsView()
                            } label: {
                                HStack(spacing: 5) {
                                    Image(systemName: "chart.line.uptrend.xyaxis")
                                        .font(.system(size: 12))
                                    Text("Projections")
                                        .font(.custom("Palatino", size: 13))
                                }
                                .foregroundColor(.themeAccent)
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.top, 24)

                        if !marketIndices.isEmpty {
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 10) {
                                    ForEach(marketIndices) { index in
                                        NavigationLink {
                                            StockDetailView(stock: index)
                                        } label: {
                                            VStack(alignment: .leading, spacing: 4) {
                                                Text(index.name)
                                                    .font(.custom("Palatino", size: 12))
                                                    .foregroundColor(.themeMuted)

                                                Text(index.currentPrice, format: .currency(code: "USD"))
                                                    .font(.custom("Palatino", size: 15))
                                                    .foregroundColor(.themeText)

                                                HStack(spacing: 4) {
                                                    Image(systemName: index.change >= 0 ? "arrow.up" : "arrow.down")
                                                        .font(.system(size: 8, weight: .bold))
                                                    Text(String(format: "%+.2f%%", index.percentChange))
                                                        .font(.custom("Palatino", size: 12))
                                                }
                                                .foregroundColor(index.change >= 0 ? .green : .red)
                                            }
                                        }
                                        .frame(width: 100, alignment: .leading)
                                        .padding(12)
                                        .background(Color.themeSurface)
                                        .cornerRadius(10)
                                        .buttonStyle(.plain)
                                    }
                                }
                                .padding(.horizontal, 16)
                            }
                        } else if isLoading {
                            ProgressView()
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 20)
                        }
                    }

                    // ── TOP STOCKS ──
                    if !topStocks.isEmpty {
                        VStack(alignment: .leading, spacing: 14) {
                            Text("Top Stocks Today")
                                .font(.custom("Palatino", size: 20))
                                .foregroundColor(.themeText)
                                .padding(.leading, 16)
                                .padding(.top, 24)

                            VStack(spacing: 10) {
                                ForEach(topStocks) { stock in
                                    NavigationLink {
                                        StockDetailView(stock: stock)
                                    } label: {
                                        HStack(spacing: 12) {
                                        VStack(alignment: .leading, spacing: 2) {
                                            Text(stock.symbol)
                                                .font(.custom("Palatino", size: 16))
                                                .foregroundColor(.themeText)
                                            Text(stock.name)
                                                .font(.custom("Palatino", size: 12))
                                                .foregroundColor(.themeMuted)
                                                .lineLimit(1)
                                        }
                                        .frame(width: 60, alignment: .leading)

                                        GeometryReader { geo in
                                            let maxChange: Double = 5.0
                                            let clampedChange = max(-maxChange, min(maxChange, stock.percentChange))
                                            let normalizedWidth = abs(clampedChange) / maxChange
                                            let barWidth = normalizedWidth * 0.5

                                            RoundedRectangle(cornerRadius: 3)
                                                .fill(Color.themeSurface2)
                                                .frame(width: geo.size.width, height: 8)
                                                .overlay(
                                                    HStack(spacing: 0) {
                                                        if clampedChange >= 0 {
                                                            Spacer().frame(width: geo.size.width * 0.5)
                                                            RoundedRectangle(cornerRadius: 3)
                                                                .fill(Color.green)
                                                                .frame(width: geo.size.width * barWidth, height: 8)
                                                        } else {
                                                            RoundedRectangle(cornerRadius: 3)
                                                                .fill(Color.red)
                                                                .frame(width: geo.size.width * barWidth, height: 8)
                                                            Spacer().frame(width: geo.size.width * (1 - barWidth))
                                                        }
                                                    }
                                                )
                                                .overlay(
                                                    Rectangle()
                                                        .fill(Color.themeMuted.opacity(0.3))
                                                        .frame(width: 1, height: 12)
                                                        .offset(x: 0)
                                                )
                                                .frame(height: 8)
                                        }
                                        .frame(height: 8)

                                        VStack(alignment: .trailing, spacing: 2) {
                                            Text(stock.currentPrice, format: .currency(code: "USD"))
                                                .font(.custom("Palatino", size: 14))
                                                .foregroundColor(.themeText)
                                            Text(String(format: "%+.2f%%", stock.percentChange))
                                                .font(.custom("Palatino", size: 12))
                                                .foregroundColor(stock.change >= 0 ? .green : .red)
                                        }
                                        .frame(width: 70, alignment: .trailing)
                                        }
                                    }
                                    .buttonStyle(.plain)
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 10)

                                    if stock.id != topStocks.last?.id {
                                        Divider().background(Color.themeMuted.opacity(0.1)).padding(.leading, 88)
                                    }
                                }
                            }
                            .padding(.vertical, 4)
                            .background(Color.themeSurface)
                            .cornerRadius(10)
                            .padding(.horizontal, 16)
                        }
                    }

                    // ── WATCHLIST ──
                    VStack(alignment: .leading, spacing: 14) {
                        HStack {
                            Text("Your Watchlist")
                                .font(.custom("Palatino", size: 20))
                                .foregroundColor(.themeText)
                            Spacer()
                        }
                        .padding(.leading, 16)
                        .padding(.top, 24)

                        // ── SEARCH BAR ──
                        VStack(alignment: .leading, spacing: 0) {
                            HStack(spacing: 8) {
                                Image(systemName: "magnifyingglass")
                                    .font(.system(size: 13))
                                    .foregroundColor(.themeMuted)

                                TextField("Search stocks...", text: $searchText)
                                    .font(.custom("Palatino", size: 15))
                                    .foregroundColor(.themeText)
                                    .autocapitalization(.none)
                                    .disableAutocorrection(true)
                                    .onChange(of: searchText) { _, newValue in
                                        Task { await search(query: newValue) }
                                    }
                            }
                            .padding(12)
                            .background(Color.themeSurface)
                            .cornerRadius(10)
                            .padding(.horizontal, 16)

                            if !searchResults.isEmpty {
                                VStack(spacing: 0) {
                                    ForEach(searchResults.prefix(6)) { result in
                                        HStack {
                                            NavigationLink {
                                                StockDetailView(stock: StockQuote(
                                                    symbol: result.symbol,
                                                    name: result.description,
                                                    currentPrice: 0,
                                                    change: 0,
                                                    percentChange: 0,
                                                    high: 0,
                                                    low: 0,
                                                    open: 0,
                                                    previousClose: 0
                                                ))
                                            } label: {
                                                VStack(alignment: .leading, spacing: 2) {
                                                    Text(result.symbol)
                                                        .font(.custom("Palatino", size: 15))
                                                        .foregroundColor(.themeText)
                                                    Text(result.description)
                                                        .font(.custom("Palatino", size: 12))
                                                        .foregroundColor(.themeMuted)
                                                        .lineLimit(1)
                                                }
                                            }
                                            .buttonStyle(.plain)

                                            Spacer()

                                            Button {
                                                Task { await addToWatchlist(symbol: result.symbol) }
                                            } label: {
                                                Image(systemName: "plus.circle")
                                                    .font(.system(size: 14))
                                                    .foregroundColor(.themeMuted)
                                            }
                                            .buttonStyle(.plain)
                                        }
                                        .padding(.horizontal, 16)
                                        .padding(.vertical, 10)

                                        if result.id != searchResults.prefix(6).last?.id {
                                            Divider().background(Color.themeMuted.opacity(0.1)).padding(.leading, 16)
                                        }
                                    }
                                }
                                .background(Color.themeSurface)
                                .cornerRadius(10)
                                .padding(.horizontal, 16)
                                .padding(.top, 8)
                            }
                        }

                        if watchlist.isEmpty && !isLoading {
                            HStack(spacing: 12) {
                                Image(systemName: "star")
                                    .font(.system(size: 14))
                                    .foregroundColor(.themeMuted)
                                    .frame(width: 28, height: 28)
                                    .background(Color.themeSurface2)
                                    .cornerRadius(6)

                                Text("Search and add stocks to your watchlist")
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
                            ForEach(watchlist) { stock in
                                HStack(spacing: 12) {
                                    NavigationLink {
                                        StockDetailView(stock: stock)
                                    } label: {
                                        HStack(spacing: 12) {
                                            VStack(alignment: .leading, spacing: 2) {
                                                Text(stock.symbol)
                                                    .font(.custom("Palatino", size: 16))
                                                    .foregroundColor(.themeText)
                                                Text(stock.name)
                                                    .font(.custom("Palatino", size: 12))
                                                    .foregroundColor(.themeMuted)
                                                    .lineLimit(1)
                                            }

                                            Spacer()

                                            VStack(alignment: .trailing, spacing: 2) {
                                                Text(stock.currentPrice, format: .currency(code: "USD"))
                                                    .font(.custom("Palatino", size: 15))
                                                    .foregroundColor(.themeText)

                                                HStack(spacing: 4) {
                                                    Image(systemName: stock.change >= 0 ? "arrow.up" : "arrow.down")
                                                        .font(.system(size: 8, weight: .bold))
                                                    Text(String(format: "%+.2f%%", stock.percentChange))
                                                        .font(.custom("Palatino", size: 12))
                                                }
                                                .foregroundColor(stock.change >= 0 ? .green : .red)
                                            }
                                        }
                                    }
                                    .buttonStyle(.plain)

                                    Button {
                                        Task { await removeFromWatchlist(symbol: stock.symbol) }
                                    } label: {
                                        Image(systemName: "xmark.circle")
                                            .font(.system(size: 16))
                                            .foregroundColor(.themeMuted)
                                    }
                                    .buttonStyle(.plain)
                                }
                                .padding(.horizontal, 16)
                                .padding(.vertical, 12)
                                .background(Color.themeSurface)
                                .cornerRadius(10)
                                .padding(.horizontal, 16)
                            }
                            }

                    }
                    .padding(.bottom, 24)
                }
            }
            .background(Color.themeBackground)
            .scrollContentBackground(.hidden)
        }
        .background(Color.themeBackground)
        .toolbarBackground(Color.themeBackground, for: .navigationBar)
        .task {
            await loadData()
        }
    }

    func loadData() async {
        isLoading = true
        let api = APIClient()
        if let overview = try? await api.getMarketOverview() {
            marketIndices = overview.indices
        }
        if let list = try? await api.getWatchlist() {
            watchlist = list
        }

        var stocks: [StockQuote] = []
        for symbol in topSymbols {
            if let quote = try? await api.getStockQuote(symbol: symbol) {
                stocks.append(quote)
            }
        }
        topStocks = stocks

        isLoading = false
    }

    func search(query: String) async {
        guard query.count >= 2 else {
            searchResults = []
            return
        }
        isSearching = true
        let api = APIClient()
        if let results = try? await api.searchStocks(query: query) {
            searchResults = results
        } else {
            searchResults = []
        }
        isSearching = false
    }

    func addToWatchlist(symbol: String) async {
        let api = APIClient()
        try? await api.addToWatchlist(symbol: symbol)
        searchText = ""
        searchResults = []
        if let list = try? await api.getWatchlist() {
            watchlist = list
        }
    }

    func removeFromWatchlist(symbol: String) async {
        let api = APIClient()
        try? await api.removeFromWatchlist(symbol: symbol)
        if let list = try? await api.getWatchlist() {
            watchlist = list
        }
    }
}

#Preview {
    StocksView()
        .preferredColorScheme(.dark)
}
