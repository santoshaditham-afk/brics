import SpriteKit

enum GameState {
    case waiting
    case playing
    case gameOver
    case levelComplete
}

final class GameScene: SKScene, SKPhysicsContactDelegate {

    // MARK: - Config
    private let cols = 10
    private let rows = 5
    private let brickSpacingX: CGFloat = 4
    private let brickSpacingY: CGFloat = 6

    // MARK: - State
    private(set) var state: GameState = .waiting
    private var lives = 3
    private var score = 0
    private var level = 1

    // MARK: - Nodes
    private var ball: Ball!
    private var paddle: Paddle!
    private var livesLabel: SKLabelNode!
    private var scoreLabel: SKLabelNode!
    private var levelLabel: SKLabelNode!
    private var messageLabel: SKLabelNode!
    private var bricks: [Brick] = []

    // MARK: - Lifecycle

    override func didMove(to view: SKView) {
        setupScene()
    }

    // MARK: - Setup

    private func setupScene() {
        backgroundColor = SKColor(red: 0.07, green: 0.07, blue: 0.15, alpha: 1)
        physicsWorld.gravity = .zero
        physicsWorld.contactDelegate = self

        setupBackground()
        setupWalls()
        setupDeathZone()
        setupBricks()
        setupPaddle()
        setupBall()
        setupHUD()
        setupMessageLabel()
        showMessage("TAP TO LAUNCH")
    }

    private func setupBackground() {
        // Starfield particle effect using individual stars
        for _ in 0..<80 {
            let star = SKShapeNode(circleOfRadius: CGFloat.random(in: 0.5...1.5))
            star.fillColor = .white
            star.alpha = CGFloat.random(in: 0.2...0.8)
            star.position = CGPoint(
                x: CGFloat.random(in: 0...size.width),
                y: CGFloat.random(in: 0...size.height)
            )
            star.strokeColor = .clear
            addChild(star)
        }
    }

    private func setupWalls() {
        // Top, left, right walls using edge physics
        let wallBody = SKPhysicsBody(edgeLoopFrom: CGRect(x: 0, y: 0, width: size.width, height: size.height))
        wallBody.categoryBitMask    = PhysicsCategory.wall
        wallBody.contactTestBitMask = PhysicsCategory.ball
        wallBody.collisionBitMask   = PhysicsCategory.ball
        wallBody.restitution        = 1.0
        wallBody.friction           = 0.0

        // We'll use a separate node so the death-zone can be open-bottom
        let wallNode = SKNode()
        wallNode.name = "walls"

        // Top wall
        let topWall = SKNode()
        topWall.physicsBody = SKPhysicsBody(edgeFrom: CGPoint(x: 0, y: size.height), to: CGPoint(x: size.width, y: size.height))
        topWall.physicsBody?.categoryBitMask    = PhysicsCategory.wall
        topWall.physicsBody?.collisionBitMask   = PhysicsCategory.ball
        topWall.physicsBody?.contactTestBitMask = PhysicsCategory.ball
        topWall.physicsBody?.restitution        = 1.0
        topWall.physicsBody?.friction           = 0.0
        addChild(topWall)

        // Left wall
        let leftWall = SKNode()
        leftWall.physicsBody = SKPhysicsBody(edgeFrom: CGPoint(x: 0, y: 0), to: CGPoint(x: 0, y: size.height))
        leftWall.physicsBody?.categoryBitMask    = PhysicsCategory.wall
        leftWall.physicsBody?.collisionBitMask   = PhysicsCategory.ball
        leftWall.physicsBody?.contactTestBitMask = PhysicsCategory.ball
        leftWall.physicsBody?.restitution        = 1.0
        leftWall.physicsBody?.friction           = 0.0
        addChild(leftWall)

        // Right wall
        let rightWall = SKNode()
        rightWall.physicsBody = SKPhysicsBody(edgeFrom: CGPoint(x: size.width, y: 0), to: CGPoint(x: size.width, y: size.height))
        rightWall.physicsBody?.categoryBitMask    = PhysicsCategory.wall
        rightWall.physicsBody?.collisionBitMask   = PhysicsCategory.ball
        rightWall.physicsBody?.contactTestBitMask = PhysicsCategory.ball
        rightWall.physicsBody?.restitution        = 1.0
        rightWall.physicsBody?.friction           = 0.0
        addChild(rightWall)
    }

    private func setupDeathZone() {
        // A thin sensor just below the screen
        let deathZone = SKNode()
        deathZone.name = "deathZone"
        let body = SKPhysicsBody(edgeFrom: CGPoint(x: 0, y: -1), to: CGPoint(x: size.width, y: -1))
        body.categoryBitMask    = PhysicsCategory.deathZone
        body.contactTestBitMask = PhysicsCategory.ball
        body.collisionBitMask   = PhysicsCategory.none
        deathZone.physicsBody = body
        addChild(deathZone)
    }

    private func setupBricks() {
        bricks.removeAll()
        let totalGridWidth = CGFloat(cols) * Brick.size.width + CGFloat(cols - 1) * brickSpacingX
        let startX = (size.width - totalGridWidth) / 2 + Brick.size.width / 2
        let startY = size.height - 120

        let colorPalette: [SKColor] = [
            SKColor(red: 0.95, green: 0.27, blue: 0.27, alpha: 1), // red
            SKColor(red: 1.00, green: 0.60, blue: 0.20, alpha: 1), // orange
            SKColor(red: 1.00, green: 0.90, blue: 0.20, alpha: 1), // yellow
            SKColor(red: 0.30, green: 0.85, blue: 0.40, alpha: 1), // green
            SKColor(red: 0.25, green: 0.60, blue: 1.00, alpha: 1), // blue
        ]

        for row in 0..<rows {
            for col in 0..<cols {
                let isBorder = row == 0 || row == rows - 1 || col == 0 || col == cols - 1
                let type: BrickType = isBorder
                    ? .indestructible
                    : .destructible(color: colorPalette[row % colorPalette.count])

                let brick = Brick(type: type)
                let x = startX + CGFloat(col) * (Brick.size.width + brickSpacingX)
                let y = startY - CGFloat(row) * (Brick.size.height + brickSpacingY)
                brick.position = CGPoint(x: x, y: y)
                addChild(brick)
                bricks.append(brick)
            }
        }
    }

    private func setupPaddle() {
        paddle = Paddle(sceneWidth: size.width)
        paddle.position = CGPoint(x: size.width / 2, y: 80)
        addChild(paddle)
    }

    private func setupBall() {
        ball = Ball()
        resetBallPosition()
        addChild(ball)
    }

    private func resetBallPosition() {
        ball.position = CGPoint(x: size.width / 2, y: paddle.position.y + Paddle.size.height / 2 + Ball.radius + 4)
        ball.physicsBody?.velocity = .zero
    }

    // MARK: - HUD

    private func setupHUD() {
        let topY = size.height - 40

        livesLabel = makeLabel(text: "Lives: \(lives)", align: .left)
        livesLabel.position = CGPoint(x: 20, y: topY)
        addChild(livesLabel)

        scoreLabel = makeLabel(text: "Score: \(score)", align: .center)
        scoreLabel.position = CGPoint(x: size.width / 2, y: topY)
        addChild(scoreLabel)

        levelLabel = makeLabel(text: "Level: \(level)", align: .right)
        levelLabel.position = CGPoint(x: size.width - 20, y: topY)
        addChild(levelLabel)
    }

    private func makeLabel(text: String, align: SKLabelHorizontalAlignmentMode) -> SKLabelNode {
        let label = SKLabelNode(fontNamed: "AvenirNext-Bold")
        label.text = text
        label.fontSize = 18
        label.fontColor = .white
        label.horizontalAlignmentMode = align
        label.zPosition = 10
        return label
    }

    private func setupMessageLabel() {
        messageLabel = SKLabelNode(fontNamed: "AvenirNext-Bold")
        messageLabel.fontSize = 28
        messageLabel.fontColor = .white
        messageLabel.horizontalAlignmentMode = .center
        messageLabel.position = CGPoint(x: size.width / 2, y: size.height / 2 - 80)
        messageLabel.zPosition = 10
        messageLabel.alpha = 0
        addChild(messageLabel)
    }

    private func showMessage(_ text: String) {
        messageLabel.text = text
        messageLabel.alpha = 1
    }

    private func hideMessage() {
        messageLabel.alpha = 0
    }

    private func updateHUD() {
        livesLabel.text = "Lives: \(lives)"
        scoreLabel.text = "Score: \(score)"
        levelLabel.text = "Level: \(level)"
    }

    // MARK: - Touch Handling

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }

        switch state {
        case .waiting:
            state = .playing
            hideMessage()
            ball.launch()

        case .gameOver, .levelComplete:
            resetGame()

        case .playing:
            let location = touch.location(in: self)
            paddle.move(toX: location.x, sceneWidth: size.width)
        }
    }

    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard state == .playing, let touch = touches.first else { return }
        let location = touch.location(in: self)
        paddle.move(toX: location.x, sceneWidth: size.width)
    }

    // MARK: - Physics Contact

    func didBegin(_ contact: SKPhysicsContact) {
        let bodyA = contact.bodyA
        let bodyB = contact.bodyB

        let masks = bodyA.categoryBitMask | bodyB.categoryBitMask

        if masks & PhysicsCategory.deathZone != 0 {
            handleBallDeath()
            return
        }

        if masks & PhysicsCategory.brick != 0 {
            let brickBody = bodyA.categoryBitMask == PhysicsCategory.brick ? bodyA : bodyB
            handleBallHitBrick(brickBody)
        }

        // Normalize speed after any contact
        DispatchQueue.main.async { [weak self] in
            self?.ball?.normalizeSpeed()
        }
    }

    private func handleBallHitBrick(_ brickBody: SKPhysicsBody) {
        guard let brick = brickBody.node as? Brick else { return }
        guard case .destructible = brick.brickType else { return }

        brick.removeFromParent()
        bricks.removeAll { $0 === brick }
        score += 10
        updateHUD()

        // Check win condition
        let remainingDestructible = bricks.filter { $0.brickType.isDestructible }
        if remainingDestructible.isEmpty {
            triggerLevelComplete()
        }
    }

    private func handleBallDeath() {
        guard state == .playing else { return }
        lives -= 1
        updateHUD()

        if lives <= 0 {
            triggerGameOver()
        } else {
            state = .waiting
            resetBallPosition()
            showMessage("TAP TO LAUNCH")
        }
    }

    private func triggerGameOver() {
        state = .gameOver
        ball.physicsBody?.velocity = .zero
        showMessage("GAME OVER\nTap to restart")
    }

    private func triggerLevelComplete() {
        state = .levelComplete
        ball.physicsBody?.velocity = .zero
        level += 1
        showMessage("LEVEL COMPLETE!\nTap to continue")
    }

    private func resetGame() {
        // Remove all brick nodes
        bricks.forEach { $0.removeFromParent() }
        bricks.removeAll()

        if state == .gameOver {
            lives = 3
            score = 0
        }

        setupBricks()
        resetBallPosition()
        state = .waiting
        updateHUD()
        showMessage("TAP TO LAUNCH")
    }

    // MARK: - Update

    override func update(_ currentTime: TimeInterval) {
        guard state == .playing else { return }
        ball.normalizeSpeed()
    }
}
