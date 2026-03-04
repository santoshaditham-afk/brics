import Foundation
import Observation

private let tokenKey = "auth_token"

@Observable final class AuthManager {
    private(set) var token: String? {
        didSet {
            if let token {
                UserDefaults.standard.set(token, forKey: tokenKey)
            } else {
                UserDefaults.standard.removeObject(forKey: tokenKey)
            }
        }
    }
    private(set) var currentPlayer: PlayerOut?
    var justRegistered = false

    var isLoggedIn: Bool { token != nil }

    private let apiClient: APIClient

    init(apiClient: APIClient = APIClient()) {
        self.apiClient = apiClient
        self.token = UserDefaults.standard.string(forKey: tokenKey)
    }

    func login(email: String, password: String) async throws {
        let tokenResponse = try await apiClient.login(email: email, password: password)
        token = tokenResponse.access_token
        try await fetchCurrentPlayer()
    }

    func register(email: String, username: String, password: String) async throws {
        _ = try await apiClient.register(email: email, username: username, password: password)
        try await login(email: email, password: password)
        justRegistered = true
    }

    func logout() {
        token = nil
        currentPlayer = nil
    }

    private func fetchCurrentPlayer() async throws {
        guard let token else { return }
        currentPlayer = try await apiClient.me(token: token)
    }
}
