import Foundation

// When Swift decodes {"engineStatus": "online"} into this struct, it automatically maps the 
// JSON key engineStatus to the property engineStatus.
struct StatusResponse: Codable { // Codeable means that this struct can decode/encode itself from JSON
    let engineStatus: String // engineStatus is the exact JSON key "engineStatus" from my java code
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
