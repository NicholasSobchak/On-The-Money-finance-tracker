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
    let inTheRed: Double
}

struct InTheGreenResponse: Codable {
    let inTheGreen: Double
}

struct ProjectionResponse: Codable {
    let finalBalance: Double?
    let median: Double?
    let percentiles: [String: Double]?
}

struct Account: Codable, Identifiable {
    let id: Int
    let name: String
    let balance: Double
    let accType: String
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
