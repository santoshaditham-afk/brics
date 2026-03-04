import SwiftUI

@main
struct BricsApp: App {
    @State private var authManager = AuthManager()

    var body: some Scene {
        WindowGroup {
            if authManager.isLoggedIn {
                GameView()
                    .alert(
                        "Account created!",
                        isPresented: Binding(
                            get: { authManager.justRegistered },
                            set: { _ in authManager.justRegistered = false }
                        )
                    ) {
                        Button("Let's play!") { authManager.justRegistered = false }
                    } message: {
                        Text("Welcome, \(authManager.currentPlayer?.username ?? "")! You're all set.")
                    }
            } else {
                AuthContainerView()
            }
        }
        .environment(authManager)
    }
}
