import SwiftUI
import SpriteKit

struct GameView: View {

    private let scene: GameScene = {
        let s = GameScene()
        s.scaleMode = .resizeFill
        return s
    }()

    var body: some View {
        SpriteView(scene: scene)
            .ignoresSafeArea()
            .statusBarHidden(true)
    }
}

#Preview {
    GameView()
}
