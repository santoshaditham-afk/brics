import XCTest
@testable import Brics

private let testTokenKey = "auth_token"

final class AuthManagerTests: XCTestCase {
    var mockSession: MockURLSession!

    override func setUp() {
        super.setUp()
        mockSession = MockURLSession()
        UserDefaults.standard.removeObject(forKey: testTokenKey)
    }

    override func tearDown() {
        super.tearDown()
        UserDefaults.standard.removeObject(forKey: testTokenKey)
    }

    // MARK: - Helpers

    private func makePlayerJSON(email: String = "test@example.com", username: String = "testuser") -> Data {
        """
        {"id":"1","email":"\(email)","username":"\(username)","created_at":"2024-01-01T00:00:00"}
        """.data(using: .utf8)!
    }

    private func makeTokenJSON(token: String = "tok123") -> Data {
        #"{"access_token":"\#(token)","token_type":"bearer"}"#.data(using: .utf8)!
    }

    private func makeHTTPResponse(status: Int) -> HTTPURLResponse {
        HTTPURLResponse(url: URL(string: "http://localhost")!, statusCode: status, httpVersion: nil, headerFields: nil)!
    }

    // MARK: - Tests

    func testLoginStoresToken() async throws {
        mockSession.responses = [
            (makeTokenJSON(), makeHTTPResponse(status: 200)),
            (makePlayerJSON(), makeHTTPResponse(status: 200)),
        ]
        let manager = AuthManager(apiClient: APIClient(session: mockSession))

        try await manager.login(email: "test@example.com", password: "secret")

        XCTAssertTrue(manager.isLoggedIn)
        XCTAssertEqual(UserDefaults.standard.string(forKey: testTokenKey), "tok123")
    }

    func testLogoutClearsState() async throws {
        mockSession.responses = [
            (makeTokenJSON(), makeHTTPResponse(status: 200)),
            (makePlayerJSON(), makeHTTPResponse(status: 200)),
        ]
        let manager = AuthManager(apiClient: APIClient(session: mockSession))
        try await manager.login(email: "test@example.com", password: "secret")

        manager.logout()

        XCTAssertFalse(manager.isLoggedIn)
        XCTAssertNil(manager.currentPlayer)
        XCTAssertNil(UserDefaults.standard.string(forKey: testTokenKey))
    }

    func testRegisterAutoLogins() async throws {
        // register → login → me
        mockSession.responses = [
            (makePlayerJSON(), makeHTTPResponse(status: 201)),
            (makeTokenJSON(), makeHTTPResponse(status: 200)),
            (makePlayerJSON(), makeHTTPResponse(status: 200)),
        ]
        let manager = AuthManager(apiClient: APIClient(session: mockSession))

        try await manager.register(email: "test@example.com", username: "testuser", password: "secret")

        XCTAssertTrue(manager.isLoggedIn)
        XCTAssertNotNil(manager.currentPlayer)
    }

    func testLoginErrorPropagates() async {
        let errorJSON = #"{"detail":"Invalid credentials"}"#.data(using: .utf8)!
        mockSession.responses = [(errorJSON, makeHTTPResponse(status: 401))]
        let manager = AuthManager(apiClient: APIClient(session: mockSession))

        do {
            try await manager.login(email: "test@example.com", password: "wrong")
            XCTFail("Expected throw")
        } catch APIError.serverError(let code, _) {
            XCTAssertEqual(code, 401)
        } catch {
            XCTFail("Unexpected error: \(error)")
        }

        XCTAssertFalse(manager.isLoggedIn)
    }
}
