import SpriteKit

enum BrickType {
    case destructible(color: SKColor)
    case indestructible

    var color: SKColor {
        switch self {
        case .destructible(let color): return color
        case .indestructible:         return .gray
        }
    }

    var isDestructible: Bool {
        if case .destructible = self { return true }
        return false
    }
}

final class Brick: SKSpriteNode {

    static let size = CGSize(width: 54, height: 22)

    let brickType: BrickType

    init(type: BrickType) {
        self.brickType = type
        super.init(texture: nil, color: type.color, size: Brick.size)
        name = "brick"

        let body = SKPhysicsBody(rectangleOf: Brick.size)
        body.categoryBitMask    = PhysicsCategory.brick
        body.contactTestBitMask = PhysicsCategory.ball
        body.collisionBitMask   = PhysicsCategory.ball
        body.isDynamic          = false
        body.restitution        = 0.0
        body.friction           = 0.0
        physicsBody = body

        // Rounded visual
        let shape = SKShapeNode(rectOf: Brick.size, cornerRadius: 5)
        shape.fillColor = type.color
        shape.strokeColor = SKColor.black.withAlphaComponent(0.25)
        shape.lineWidth = 1
        let rendered = SKView().texture(from: shape, rect: CGRect(origin: CGPoint(x: -Brick.size.width / 2, y: -Brick.size.height / 2), size: Brick.size))
        self.texture = rendered
        self.color = .white
        self.colorBlendFactor = 0
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) not implemented") }
}
