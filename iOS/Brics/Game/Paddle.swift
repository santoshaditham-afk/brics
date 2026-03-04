import SpriteKit

final class Paddle: SKSpriteNode {

    static let size = CGSize(width: 100, height: 18)

    convenience init(sceneWidth: CGFloat) {
        self.init(color: .white, size: Paddle.size)
        name = "paddle"

        let body = SKPhysicsBody(rectangleOf: Paddle.size)
        body.categoryBitMask    = PhysicsCategory.paddle
        body.contactTestBitMask = PhysicsCategory.ball
        body.collisionBitMask   = PhysicsCategory.ball
        body.isDynamic          = false
        body.restitution        = 0.0
        body.friction           = 0.0
        physicsBody = body

        // Rounded corner visual
        let shape = SKShapeNode(rectOf: Paddle.size, cornerRadius: 9)
        shape.fillColor = .white
        shape.strokeColor = .clear
        let rendered = SKView().texture(from: shape, rect: CGRect(origin: CGPoint(x: -Paddle.size.width / 2, y: -Paddle.size.height / 2), size: Paddle.size))
        self.texture = rendered
    }

    /// Move paddle to targetX, clamped so it stays within the scene.
    func move(toX targetX: CGFloat, sceneWidth: CGFloat) {
        let half = Paddle.size.width / 2
        let clamped = min(max(targetX, half), sceneWidth - half)
        position.x = clamped
    }
}
