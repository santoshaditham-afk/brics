import SwiftUI
import SpriteKit

struct GameView: View {
    @Environment(AuthManager.self) private var authManager

    // @State ensures the same GameScene instance survives re-renders (e.g. when
    // showScoreboard flips), preventing a silent scene swap that clears onGameEnd.
    @State private var scene: GameScene = {
        let s = GameScene()
        s.scaleMode = .resizeFill
        return s
    }()

    @State private var showScoreboard = false
    @State private var showLogoutConfirm = false

    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            SpriteView(scene: scene)
                .ignoresSafeArea()
                .statusBarHidden(true)

            Menu {
                Button {
                    showScoreboard = true
                } label: {
                    Label("Scoreboard", systemImage: "trophy")
                }

                Button(role: .destructive) {
                    showLogoutConfirm = true
                } label: {
                    Label("Log Out", systemImage: "rectangle.portrait.and.arrow.right")
                }
            } label: {
                Image(systemName: "ellipsis.circle")
                    .font(.system(size: 18, weight: .medium))
                    .foregroundStyle(.white.opacity(0.6))
                    .padding(12)
                    .background(.black.opacity(0.3))
                    .clipShape(Circle())
            }
            .padding(20)
        }
        .confirmationDialog("Log out?", isPresented: $showLogoutConfirm, titleVisibility: .visible) {
            Button("Log Out", role: .destructive) { authManager.logout() }
            Button("Cancel", role: .cancel) {}
        }
        .sheet(isPresented: $showScoreboard) {
            ScoreboardView()
        }
        .onAppear {
            let manager = authManager
            scene.onGameEnd = { score, level, duration in
                print("[GameView] onGameEnd fired — score:\(score) level:\(level) duration:\(duration)s")
                guard let token = manager.token else {
                    print("[GameView] onGameEnd skipped — no token")
                    return
                }
                Task {
                    do {
                        let result = try await APIClient().submitSession(
                            score: score,
                            levelReached: level,
                            durationSecs: duration,
                            token: token
                        )
                        print("[GameView] session submitted — id:\(result.id)")
                    } catch {
                        print("[GameView] submitSession failed — \(error)")
                    }
                }
            }
            print("[GameView] onGameEnd callback registered on scene \(ObjectIdentifier(scene))")
        }
    }
}
