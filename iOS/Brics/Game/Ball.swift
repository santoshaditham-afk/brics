import SpriteKit

final class Ball: SKSpriteNode {

    static let radius: CGFloat = 10
    static let speed: CGFloat = 400

    convenience init() {
        let size = CGSize(width: Ball.radius * 2, height: Ball.radius * 2)
        self.init(color: .white, size: size)
        name = "ball"

        let body = SKPhysicsBody(circleOfRadius: Ball.radius)
        body.categoryBitMask    = PhysicsCategory.ball
        body.contactTestBitMask = PhysicsCategory.brick | PhysicsCategory.paddle |
                                  PhysicsCategory.wall  | PhysicsCategory.deathZone
        body.collisionBitMask   = PhysicsCategory.brick | PhysicsCategory.paddle |
                                  PhysicsCategory.wall
        body.restitution        = 1.0
        body.friction           = 0.0
        body.linearDamping      = 0.0
        body.angularDamping     = 0.0
        body.affectedByGravity  = false
        body.allowsRotation     = false
        physicsBody = body

        // Round visual corners
        let radius = Ball.radius
        let texture = SKShapeNode(circleOfRadius: radius)
        texture.fillColor = .white
        texture.strokeColor = .clear
        let rendered = SKView().texture(from: texture, crop: CGRect(x: -radius, y: -radius, width: radius * 2, height: radius * 2))
        self.texture = rendered
    }

    /// Normalize velocity so speed stays constant after bounces.
    func normalizeSpeed() {
        guard let body = physicsBody else { return }
        let v = body.velocity
        let currentSpeed = hypot(v.dx, v.dy)
        guard currentSpeed > 0 else { return }
        let scale = Ball.speed / currentSpeed
        body.velocity = CGVector(dx: v.dx * scale, dy: v.dy * scale)
    }

    /// Launch the ball upward with a slight random horizontal angle.
    func launch() {
        guard let body = physicsBody else { return }
        let angle = CGFloat.random(in: (-CGFloat.pi / 6)...(CGFloat.pi / 6))
        body.velocity = CGVector(
            dx: Ball.speed * sin(angle),
            dy: Ball.speed * cos(angle)
        )
    }
}
