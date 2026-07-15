import Foundation

struct StatusResponse: Codable {
    let engineStatus: String
}

struct NetWorthResponse: Codable {
    let netWorth: Double
}

struct TotalAssetsResponse: Codable {
    let totalAssets: Double
}

struct TotalLiabilitiesResponse: Codable {
    let totalLiabilities: Double
}

struct InTheRedResponse: Codable {
    let inTheRed: Bool 
}

struct InTheGreenResponse: Codable {
    let inTheGreen: Bool 
}

struct ProjectionResponse: Codable {
    let status: String?
    let finalBalance: Double?
    let worst10: Double?
    let median: Double?
    let best10: Double?
    let mean: Double?
    let simulations: Int?
    let percentiles: [Double]?
    let worst10Trajectory: [Double]?
    let medianTrajectory: [Double]?
    let best10Trajectory: [Double]?
    let meanTrajectory: [Double]?
    let years: Int?
}

struct Account: Codable, Identifiable {
    let id: Int
    let name: String
    let balance: Double
    let accType: String
    var accountNumber: String?
    var interestRate: Double?
}

struct Transaction: Codable, Identifiable {
    let id: Int
    let fromAccountId: Int?
    let toAccountId: Int?
    let amount: Double
    let description: String?
    let date: String
    let type: String
}

struct NetWorthHistory: Codable, Identifiable {
    let id: Int
    let netWorth: Double
    let date: String
}

struct CreditScoreResponse: Codable {
    let score: Int
    let date: String?
    let id: Int
    let previousScore: Int?
}

struct StockQuote: Codable, Identifiable {
    let symbol: String
    var name: String
    let currentPrice: Double
    let change: Double
    let percentChange: Double
    let high: Double
    let low: Double
    let open: Double
    let previousClose: Double
    var addedDate: String?
    var id: String { symbol }
}

struct MarketOverview: Codable {
    let indices: [StockQuote]
}

struct SearchResult: Codable, Identifiable {
    let symbol: String
    let description: String
    let type: String
    var id: String { symbol }
}

struct StockCandle: Codable {
    let s: String
    let t: [Int]
    let c: [Double]
}
