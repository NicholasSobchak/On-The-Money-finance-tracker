import Foundation

class APIClient {
    let base = URL(string: "http://localhost:8080/api/")!

    private func makeURL(path: String) throws -> URL {
        guard let url = URL(string: path, relativeTo: base) else {
            throw URLError(.badURL)
        }
        return url
    }

    // MARK: - Status

    func getRoot() async throws -> String {
        let (data, _) = try await URLSession.shared.data(from: base)
        guard let text = String(data: data, encoding: .utf8) else {
            throw URLError(.cannotDecodeContentData)
        }
        return text
    }

    func getStatus() async throws -> StatusResponse {
        let url = try makeURL(path: "status")
        let (data, _) = try await URLSession.shared.data(from: url)
        return try JSONDecoder().decode(StatusResponse.self, from: data)
    }

    // MARK: - Summary

    func getNetWorth() async throws -> NetWorthResponse {
        let url = try makeURL(path: "net-worth")
        let (data, _) = try await URLSession.shared.data(from: url)
        return try JSONDecoder().decode(NetWorthResponse.self, from: data)
    }

    func getTotalAssets() async throws -> TotalAssetsResponse {
        let url = try makeURL(path: "total-assets")
        let (data, _) = try await URLSession.shared.data(from: url)
        return try JSONDecoder().decode(TotalAssetsResponse.self, from: data)
    }

    func getTotalLiabilities() async throws -> TotalLiabilitiesResponse {
        let url = try makeURL(path: "total-liabilities")
        let (data, _) = try await URLSession.shared.data(from: url)
        return try JSONDecoder().decode(TotalLiabilitiesResponse.self, from: data)
    }

    func getInTheRed() async throws -> InTheRedResponse {
        let url = try makeURL(path: "in-the-red")
        let (data, _) = try await URLSession.shared.data(from: url)
        return try JSONDecoder().decode(InTheRedResponse.self, from: data)
    }

    func getInTheGreen() async throws -> InTheGreenResponse {
        let url = try makeURL(path: "in-the-green")
        let (data, _) = try await URLSession.shared.data(from: url)
        return try JSONDecoder().decode(InTheGreenResponse.self, from: data)
    }

    // MARK: - Projection

    func projectRetirement(initialBalance: Double = 10000, monthlyContribution: Double = 500, returnRate: Double = 7, years: Int = 30, simulations: Int = 10000) async throws -> ProjectionResponse {
        guard var components = URLComponents(url: try makeURL(path: "project"), resolvingAgainstBaseURL: true) else {
            throw URLError(.badURL)
        }
        components.queryItems = [
            URLQueryItem(name: "initialBalance", value: String(initialBalance)),
            URLQueryItem(name: "monthlyContribution", value: String(monthlyContribution)),
            URLQueryItem(name: "returnRate", value: String(returnRate)),
            URLQueryItem(name: "years", value: String(years)),
            URLQueryItem(name: "simulations", value: String(simulations)),
        ]
        guard let url = components.url else { throw URLError(.badURL) }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        let (data, _) = try await URLSession.shared.data(for: request)
        return try JSONDecoder().decode(ProjectionResponse.self, from: data)
    }

    // MARK: - Accounts

    func getAccounts() async throws -> [Account] {
        let url = try makeURL(path: "accounts")
        let (data, _) = try await URLSession.shared.data(from: url)
        return try JSONDecoder().decode([Account].self, from: data)
    }

    func getAccount(id: Int) async throws -> Account {
        let url = try makeURL(path: "accounts/\(id)")
        let (data, _) = try await URLSession.shared.data(from: url)
        return try JSONDecoder().decode(Account.self, from: data)
    }

    func getAccount(name: String) async throws -> Account {
        guard var components = URLComponents(url: try makeURL(path: "accounts"), resolvingAgainstBaseURL: true) else {
            throw URLError(.badURL)
        }
        components.queryItems = [URLQueryItem(name: "name", value: name)]
        guard let url = components.url else { throw URLError(.badURL) }
        let (data, _) = try await URLSession.shared.data(from: url)
        return try JSONDecoder().decode(Account.self, from: data)
    }

    func addAccount(name: String, balance: Double, accType: String) async throws -> Account {
        guard var components = URLComponents(url: try makeURL(path: "accounts"), resolvingAgainstBaseURL: true) else {
            throw URLError(.badURL)
        }
        components.queryItems = [
            URLQueryItem(name: "name", value: name),
            URLQueryItem(name: "balance", value: String(balance)),
            URLQueryItem(name: "accType", value: accType)
        ]
        guard let url = components.url else { throw URLError(.badURL) }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        let (data, _) = try await URLSession.shared.data(for: request)
        return try JSONDecoder().decode(Account.self, from: data)
    }

    func updateAccount(id: Int, name: String? = nil, balance: Double? = nil, accType: String? = nil) async throws -> Account {
        guard var components = URLComponents(url: try makeURL(path: "accounts/\(id)"), resolvingAgainstBaseURL: true) else {
            throw URLError(.badURL)
        }
        var items: [URLQueryItem] = []
        if let name = name { items.append(URLQueryItem(name: "name", value: name)) }
        if let balance = balance { items.append(URLQueryItem(name: "balance", value: String(balance))) }
        if let accType = accType { items.append(URLQueryItem(name: "accType", value: accType)) }
        components.queryItems = items
        guard let url = components.url else { throw URLError(.badURL) }
        var request = URLRequest(url: url)
        request.httpMethod = "PUT"
        let (data, _) = try await URLSession.shared.data(for: request)
        return try JSONDecoder().decode(Account.self, from: data)
    }

    func deleteAccount(id: Int) async throws {
        var request = URLRequest(url: try makeURL(path: "accounts/\(id)"))
        request.httpMethod = "DELETE"
        let (_, _) = try await URLSession.shared.data(for: request)
    }

    func deleteAllAccounts() async throws {
        var request = URLRequest(url: try makeURL(path: "accounts"))
        request.httpMethod = "DELETE"
        let (_, _) = try await URLSession.shared.data(for: request)
    }

    // MARK: - Transactions

    func deposit(id: Int, amount: Double, description: String? = nil, date: String? = nil) async throws -> Transaction {
        guard var components = URLComponents(url: try makeURL(path: "accounts/\(id)/deposit"), resolvingAgainstBaseURL: true) else {
            throw URLError(.badURL)
        }
        components.queryItems = [
            URLQueryItem(name: "amount", value: String(amount)),
        ]
        if let desc = description {
            components.queryItems?.append(URLQueryItem(name: "description", value: desc))
        }
        if let d = date {
            components.queryItems?.append(URLQueryItem(name: "date", value: d))
        }
        guard let url = components.url else { throw URLError(.badURL) }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        let (data, _) = try await URLSession.shared.data(for: request)
        return try JSONDecoder().decode(Transaction.self, from: data)
    }

    func withdraw(id: Int, amount: Double, description: String? = nil, date: String? = nil) async throws -> Transaction {
        guard var components = URLComponents(url: try makeURL(path: "accounts/\(id)/withdraw"), resolvingAgainstBaseURL: true) else {
            throw URLError(.badURL)
        }
        components.queryItems = [
            URLQueryItem(name: "amount", value: String(amount)),
        ]
        if let desc = description {
            components.queryItems?.append(URLQueryItem(name: "description", value: desc))
        }
        if let d = date {
            components.queryItems?.append(URLQueryItem(name: "date", value: d))
        }
        guard let url = components.url else { throw URLError(.badURL) }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        let (data, _) = try await URLSession.shared.data(for: request)
        return try JSONDecoder().decode(Transaction.self, from: data)
    }

    func transfer(fromAccountId: Int, toAccountId: Int, amount: Double, date: String? = nil) async throws -> Transaction {
        guard var components = URLComponents(url: try makeURL(path: "transfers"), resolvingAgainstBaseURL: true) else {
            throw URLError(.badURL)
        }
        components.queryItems = [
            URLQueryItem(name: "fromAccountId", value: String(fromAccountId)),
            URLQueryItem(name: "toAccountId", value: String(toAccountId)),
            URLQueryItem(name: "amount", value: String(amount))
        ]
        if let d = date {
            components.queryItems?.append(URLQueryItem(name: "date", value: d))
        }
        guard let url = components.url else { throw URLError(.badURL) }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        let (data, _) = try await URLSession.shared.data(for: request)
        return try JSONDecoder().decode(Transaction.self, from: data)
    }

    func getTransactions() async throws -> [Transaction] {
        let url = try makeURL(path: "transactions")
        let (data, _) = try await URLSession.shared.data(from: url)
        return try JSONDecoder().decode([Transaction].self, from: data)
    }

    func getTransactions(start: String, end: String, accountId: Int? = nil) async throws -> [Transaction] {
        guard var components = URLComponents(url: try makeURL(path: "transactions"), resolvingAgainstBaseURL: true) else {
            throw URLError(.badURL)
        }
        components.queryItems = [
            URLQueryItem(name: "start", value: start),
            URLQueryItem(name: "end", value: end),
        ]
        if let id = accountId {
            components.queryItems?.append(URLQueryItem(name: "accountId", value: String(id)))
        }
        guard let url = components.url else { throw URLError(.badURL) }
        let (data, _) = try await URLSession.shared.data(from: url)
        return try JSONDecoder().decode([Transaction].self, from: data)
    }

    func updateTransaction(id: Int, amount: Double? = nil, description: String? = nil, date: String? = nil) async throws -> Transaction {
        guard var components = URLComponents(url: try makeURL(path: "transactions/\(id)"), resolvingAgainstBaseURL: true) else {
            throw URLError(.badURL)
        }
        var items: [URLQueryItem] = []
        if let amount = amount { items.append(URLQueryItem(name: "amount", value: String(amount))) }
        if let desc = description { items.append(URLQueryItem(name: "description", value: desc)) }
        if let d = date { items.append(URLQueryItem(name: "date", value: d)) }
        components.queryItems = items
        guard let url = components.url else { throw URLError(.badURL) }
        var request = URLRequest(url: url)
        request.httpMethod = "PUT"
        let (data, _) = try await URLSession.shared.data(for: request)
        return try JSONDecoder().decode(Transaction.self, from: data)
    }

    func deleteTransaction(id: Int) async throws {
        var request = URLRequest(url: try makeURL(path: "transactions/\(id)"))
        request.httpMethod = "DELETE"
        let (_, _) = try await URLSession.shared.data(for: request)
    }
}
