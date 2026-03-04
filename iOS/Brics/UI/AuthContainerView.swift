import SwiftUI

struct AuthContainerView: View {
    @State private var showLogin = true

    var body: some View {
        if showLogin {
            LoginView(onShowRegister: { showLogin = false })
        } else {
            RegisterView(onShowLogin: { showLogin = true })
        }
    }
}
