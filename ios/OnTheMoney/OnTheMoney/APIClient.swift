import Foundation

class APIClient {
    let base = URL(string: "http://localhost:8080/api")!

    func getStatus() async throws -> StatusResponse {
        let url = URL(string: "/status", relativeTo: base)!
        let (data, _) = try await URLSession.shared.data(from: url)
        return try JSONDecoder().decode(StatusResponse.self, from: data)
    }
}
