# Brics iOS Game — MVP Plan

## Context
Building "Brics" — a Breakout/Arkanoid-style iOS game. MVP goal: single working game screen with basic physics. Project root: `/Users/santoshaditham/Documents/code/brics`.

---

## Folder Structure
```
brics/
├── .git/
├── .gitignore          # Swift/Xcode ignores
├── README.md
├── docs/
│   └── game-rules.md
├── backend/            # Placeholder for future API
│   └── README.md
└── iOS/
    ├── project.yml     # xcodegen config
    ├── Brics.xcodeproj/  (generated, NOT committed to git)
    └── Brics/
        ├── App/
        │   ├── BricsApp.swift       # @main SwiftUI entry
        │   └── Info.plist
        ├── Game/
        │   ├── PhysicsCategory.swift  # Bitmask constants
        │   ├── GameScene.swift        # Main SKScene, game loop, state
        │   ├── Ball.swift             # SKSpriteNode + physics
        │   ├── Paddle.swift           # SKSpriteNode, touch-driven
        │   └── Brick.swift            # SKSpriteNode, type enum
        ├── UI/
        │   └── GameView.swift         # SpriteKitView wrapper (SwiftUI)
        └── Assets.xcassets/
```

---

## Step-by-Step Implementation

### 1. Git Setup
- `git init` in `/Users/santoshaditham/Documents/code/brics`
- Create `.gitignore` (Xcode/Swift standard + `*.xcodeproj/` excluded from tracking)
- Initial commit: "chore: init project structure"

### 2. Docs
- `docs/game-rules.md` — the agreed rules draft

### 3. Backend Placeholder
- `backend/README.md` — note that API is planned for post-MVP

### 4. iOS — xcodegen Setup
Install xcodegen via Homebrew: `brew install xcodegen`

`iOS/project.yml`:
```yaml
name: Brics
options:
  bundleIdPrefix: com.brics
  deploymentTarget:
    iOS: "17.0"
targets:
  Brics:
    type: application
    platform: iOS
    sources: [Brics]
    settings:
      base:
        SWIFT_VERSION: 5.10
        PRODUCT_BUNDLE_IDENTIFIER: com.brics.app
    info:
      path: Brics/App/Info.plist
```

Run `xcodegen generate` inside `iOS/` to produce `Brics.xcodeproj`.

### 5. Core Swift Files

**PhysicsCategory.swift**
```swift
struct PhysicsCategory {
    static let none:   UInt32 = 0
    static let ball:   UInt32 = 0x1 << 0
    static let brick:  UInt32 = 0x1 << 1
    static let paddle: UInt32 = 0x1 << 2
    static let wall:   UInt32 = 0x1 << 3
}
```

**Ball.swift** — `SKSpriteNode`, circular physics body, restitution=1, friction=0, linearDamping=0, no gravity.

**Paddle.swift** — `SKSpriteNode`, kinematic body (isDynamic=false), follows touch X position, clamped to screen edges.

**Brick.swift** — `SKSpriteNode` with enum `BrickType { case destructible(color), indestructible }`. Static body, removed on contact.

**GameScene.swift** — the core scene:
- `setupScene()`: starfield background, 3-wall boundary, brick grid, paddle, ball
- Brick grid: 10 cols × 5 rows colorful center + gray border (matching screenshot)
- `touchesBegan`: launch ball on first tap (apply impulse)
- `touchesMoved`: move paddle to touch X
- `didBegin(_ contact:)`: handle ball-brick and ball-death-zone collisions
- Game states: `.waiting`, `.playing`, `.gameOver`, `.levelComplete`
- HUD: Lives label (top-left), Level label (top-right), Score label (top-center)

**GameView.swift** — `SpriteView(scene:)` wrapped in SwiftUI `View`.

**BricsApp.swift** — `@main App`, presents `GameView` full-screen.

---

## Physics Design
| Body | Type | Restitution | Friction | LinearDamping |
|------|------|-------------|----------|---------------|
| Ball | dynamic | 1.0 | 0.0 | 0.0 |
| Paddle | kinematic | 0.0 | 0.0 | — |
| Bricks | static | 0.0 | 0.0 | — |
| Walls | static edge | 1.0 | 0.0 | — |

- Gravity: disabled (`scene.physicsWorld.gravity = .zero`)
- Ball speed normalized after each bounce to prevent drift

---

## Git Branching Strategy
- `main` — stable releases only
- `develop` — integration branch
- Feature branches: `feature/<name>`, merged via PR into `develop`
- MVP work: branch `feature/mvp-game-scene`

---

## Verification
1. `brew install xcodegen && cd iOS && xcodegen generate`
2. Open `Brics.xcodeproj` in Xcode
3. Run on iOS Simulator (iPhone 15)
4. Tap to launch ball → ball bounces off walls/bricks/paddle
5. Colorful bricks disappear on hit, gray bricks stay
6. Lose a life when ball falls below paddle
7. Game Over at 0 lives, Level Complete when all colorful bricks cleared
