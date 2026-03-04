import SwiftUI

struct LoginView: View {
    @Environment(AuthManager.self) private var authManager
    var onShowRegister: () -> Void

    @State private var email = ""
    @State private var password = ""
    @State private var isLoading = false
    @State private var errorMessage: String?

    private var canSubmit: Bool {
        !email.isEmpty && !password.isEmpty && !isLoading
    }

    var body: some View {
        VStack(spacing: 20) {
            Text("Welcome Back")
                .font(.largeTitle.bold())

            TextField("Email", text: $email)
                .keyboardType(.emailAddress)
                .autocapitalization(.none)
                .textContentType(.emailAddress)
                .textFieldStyle(.roundedBorder)

            SecureField("Password", text: $password)
                .textContentType(.password)
                .textFieldStyle(.roundedBorder)

            if let errorMessage {
                Text(errorMessage)
                    .foregroundStyle(.red)
                    .font(.footnote)
            }

            Button(action: performLogin) {
                if isLoading {
                    ProgressView()
                        .frame(maxWidth: .infinity)
                } else {
                    Text("Log In")
                        .frame(maxWidth: .infinity)
                }
            }
            .buttonStyle(.borderedProminent)
            .disabled(!canSubmit)

            Button("Don't have an account? Register", action: onShowRegister)
                .font(.footnote)
        }
        .padding(32)
    }

    private func performLogin() {
        isLoading = true
        errorMessage = nil
        Task {
            do {
                try await authManager.login(email: email, password: password)
            } catch APIError.serverError(_, let detail) {
                errorMessage = detail
            } catch {
                errorMessage = "Network error. Try again."
            }
            isLoading = false
        }
    }
}
