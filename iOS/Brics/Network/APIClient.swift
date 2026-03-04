import Foundation

private struct _ErrorBody: Decodable { let detail: String }

struct PlayerOut: Codable {
    let id: String
    let email: String
    let username: String
    let created_at: String
}

struct Token: Decodable {
    let access_token: String
    let token_type: String
}

struct GameSessionOut: Decodable {
    let id: String
    let score: Int
    let level_reached: Int
}

struct LeaderboardEntry: Decodable, Identifiable {
    let rank: Int
    let username: String
    let score: Int
    let level_reached: Int
    let duration_secs: Double
    let played_at: String

    var id: Int { rank }
}

enum APIError: Error {
    case serverError(Int, String)
    case decodingError
    case networkError(Error)
}

protocol URLSessionProtocol {
    func data(for request: URLRequest) async throws -> (Data, URLResponse)
}

extension URLSession: URLSessionProtocol {}

struct APIClient {
    static let baseURL = "http://localhost:6543"

    private let session: URLSessionProtocol

    init(session: URLSessionProtocol = URLSession.shared) {
        self.session = session
    }

    func register(email: String, username: String, password: String) async throws -> PlayerOut {
        let body = ["email": email, "username": username, "password": password]
        return try await performRequest(path: "/auth/register", method: "POST", body: body, token: nil)
    }

    func login(email: String, password: String) async throws -> Token {
        let body = ["email": email, "password": password]
        return try await performRequest(path: "/auth/login", method: "POST", body: body, token: nil)
    }

    func me(token: String) async throws -> PlayerOut {
        return try await performRequest(path: "/auth/me", method: "GET", body: nil as [String: String]?, token: token)
    }

    func submitSession(score: Int, levelReached: Int, durationSecs: Double, token: String) async throws -> GameSessionOut {
        struct Body: Encodable { let score: Int; let level_reached: Int; let duration_secs: Double }
        return try await performRequest(
            path: "/game/sessions", method: "POST",
            body: Body(score: score, level_reached: levelReached, duration_secs: durationSecs),
            token: token
        )
    }

    func leaderboard(token: String) async throws -> [LeaderboardEntry] {
        return try await performRequest(path: "/game/sessions/leaderboard", method: "GET", body: nil as [String: String]?, token: token)
    }

    private func performRequest<Body: Encodable, Response: Decodable>(
        path: String,
        method: String,
        body: Body?,
        token: String?
    ) async throws -> Response {
        guard let url = URL(string: Self.baseURL + path) else {
            throw APIError.decodingError
        }
        var request = URLRequest(url: url)
        request.httpMethod = method
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        if let token {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        if let body {
            request.httpBody = try? JSONEncoder().encode(body)
        }

        let (data, response): (Data, URLResponse)
        do {
            (data, response) = try await session.data(for: request)
        } catch {
            throw APIError.networkError(error)
        }

        let statusCode = (response as? HTTPURLResponse)?.statusCode ?? 0
        guard (200...299).contains(statusCode) else {
            let detail = (try? JSONDecoder().decode(_ErrorBody.self, from: data))?.detail ?? "Unknown error"
            throw APIError.serverError(statusCode, detail)
        }

        guard let decoded = try? JSONDecoder().decode(Response.self, from: data) else {
            throw APIError.decodingError
        }
        return decoded
    }
}
