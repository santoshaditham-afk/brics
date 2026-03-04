import SwiftUI

struct RegisterView: View {
    @Environment(AuthManager.self) private var authManager
    var onShowLogin: () -> Void

    @State private var email = ""
    @State private var username = ""
    @State private var password = ""
    @State private var isLoading = false
    @State private var errorMessage: String?

    private var canSubmit: Bool {
        !email.isEmpty && !username.isEmpty && !password.isEmpty && !isLoading
    }

    var body: some View {
        VStack(spacing: 20) {
            Text("Create Account")
                .font(.largeTitle.bold())

            TextField("Email", text: $email)
                .keyboardType(.emailAddress)
                .autocapitalization(.none)
                .textContentType(.emailAddress)
                .textFieldStyle(.roundedBorder)

            TextField("Username", text: $username)
                .autocapitalization(.none)
                .textContentType(.username)
                .textFieldStyle(.roundedBorder)

            SecureField("Password", text: $password)
                .textContentType(.password)
                .textFieldStyle(.roundedBorder)

            if let errorMessage {
                Text(errorMessage)
                    .foregroundStyle(.red)
                    .font(.footnote)
            }

            Button(action: performRegister) {
                if isLoading {
                    ProgressView()
                        .frame(maxWidth: .infinity)
                } else {
                    Text("Register")
                        .frame(maxWidth: .infinity)
                }
            }
            .buttonStyle(.borderedProminent)
            .disabled(!canSubmit)

            Button("Already have an account? Log In", action: onShowLogin)
                .font(.footnote)
        }
        .padding(32)
    }

    private func performRegister() {
        isLoading = true
        errorMessage = nil
        Task {
            do {
                try await authManager.register(email: email, username: username, password: password)
            } catch APIError.serverError(_, let detail) {
                errorMessage = detail
            } catch {
                errorMessage = "Network error. Try again."
            }
            isLoading = false
        }
    }
}
