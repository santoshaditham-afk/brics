import XCTest
@testable import Brics

final class MockURLSession: URLSessionProtocol {
    var responses: [(Data, URLResponse)] = []
    var lastRequest: URLRequest?

    func data(for request: URLRequest) async throws -> (Data, URLResponse) {
        lastRequest = request
        return responses.removeFirst()
    }
}

private func makeHTTPResponse(status: Int) -> HTTPURLResponse {
    HTTPURLResponse(url: URL(string: "http://localhost")!, statusCode: status, httpVersion: nil, headerFields: nil)!
}

final class APIClientTests: XCTestCase {
    var mockSession: MockURLSession!
    var client: APIClient!

    override func setUp() {
        super.setUp()
        mockSession = MockURLSession()
        client = APIClient(session: mockSession)
    }

    func testRegisterSuccess() async throws {
        let json = """
        {"id":"1","email":"a@b.com","username":"alice","created_at":"2024-01-01T00:00:00"}
        """.data(using: .utf8)!
        mockSession.responses = [(json, makeHTTPResponse(status: 201))]

        let player = try await client.register(email: "a@b.com", username: "alice", password: "pass")
        XCTAssertEqual(player.email, "a@b.com")
        XCTAssertEqual(player.username, "alice")
    }

    func testRegister409ThrowsServerError() async {
        let json = #"{"detail":"Email already registered"}"#.data(using: .utf8)!
        mockSession.responses = [(json, makeHTTPResponse(status: 409))]

        do {
            _ = try await client.register(email: "a@b.com", username: "alice", password: "pass")
            XCTFail("Expected throw")
        } catch APIError.serverError(let code, let detail) {
            XCTAssertEqual(code, 409)
            XCTAssertEqual(detail, "Email already registered")
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }

    func testLoginSuccess() async throws {
        let json = #"{"access_token":"tok123","token_type":"bearer"}"#.data(using: .utf8)!
        mockSession.responses = [(json, makeHTTPResponse(status: 200))]

        let token = try await client.login(email: "a@b.com", password: "pass")
        XCTAssertEqual(token.access_token, "tok123")
    }

    func testLogin401ThrowsServerError() async {
        let json = #"{"detail":"Invalid credentials"}"#.data(using: .utf8)!
        mockSession.responses = [(json, makeHTTPResponse(status: 401))]

        do {
            _ = try await client.login(email: "a@b.com", password: "wrong")
            XCTFail("Expected throw")
        } catch APIError.serverError(let code, let detail) {
            XCTAssertEqual(code, 401)
            XCTAssertEqual(detail, "Invalid credentials")
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }

    func testMeSetsAuthorizationHeader() async throws {
        let json = """
        {"id":"1","email":"a@b.com","username":"alice","created_at":"2024-01-01T00:00:00"}
        """.data(using: .utf8)!
        mockSession.responses = [(json, makeHTTPResponse(status: 200))]

        _ = try await client.me(token: "mytoken")
        XCTAssertEqual(mockSession.lastRequest?.value(forHTTPHeaderField: "Authorization"), "Bearer mytoken")
    }
}
