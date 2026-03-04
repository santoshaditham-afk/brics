# Brics — Project Lifecycle

A running log of bugs, decisions, and fixes made during development.

---

## [2026-03-03] Paddle bounce physics — ball stuck in vertical loop

### Symptom
After launching, the ball would bounce vertically up and down in a straight line, ignoring the paddle's position and any horizontal movement.

### Root Cause

Two compounding problems:

**1. Contact normal is always vertical.**
The paddle is a flat rectangle. When the ball collides with it, SpriteKit computes a contact normal of `(0, 1)` — straight up. The physics engine reflects the ball by mirroring the velocity component along that normal: `dy` flips sign, `dx` is preserved unchanged. If the ball ever reaches zero horizontal velocity (e.g. dead-center launch followed by a symmetric wall bounce), `dx` stays zero forever. The engine has no reason to introduce any horizontal component.

**2. Kinematic bodies have no velocity in the physics engine.**
The paddle uses `isDynamic = false`, which makes it kinematic — it moves when we tell it to, but the physics engine does not track its momentum. When the ball hits a fast-moving paddle, the engine sees the paddle as stationary. No momentum transfer occurs; the ball bounces as if it hit a wall.

Both issues trace back to the same design mismatch: SpriteKit's physics is correct for rigid-body simulation, but Breakout-style paddle deflection is not a physics problem — it's a game-feel problem.

### Fix

Bypassed physics reflection entirely for paddle contacts. When `didBegin(_:)` detects a ball–paddle collision, we override the ball's velocity directly using a deflection angle computed from the hit position:

```swift
// offset: -1 = left edge, 0 = center, +1 = right edge
let offset = (ball.position.x - paddle.position.x) / (Paddle.size.width / 2)
let clamped = max(-1, min(1, offset))
let maxAngle: CGFloat = .pi / 3   // 60° max from vertical
let angle = clamped * maxAngle
ball.physicsBody?.velocity = CGVector(
    dx: Ball.speed * sin(angle),
    dy: Ball.speed * cos(angle)   // always positive → always upward
)
```

`dy` is always positive so the ball can never be deflected downward by the paddle. The horizontal direction and steepness are entirely determined by where on the paddle the ball lands, not by incoming angle or paddle velocity.

The paddle contact handler also returns early before the generic `normalizeSpeed()` call, since the velocity is already set to exactly `Ball.speed`.

### Lesson
Physics engines reflect velocity correctly for wall/brick bounces. Paddle deflection in Breakout is a **design mechanic**, not physics — it must be implemented explicitly. Always intercept paddle contacts and override velocity rather than relying on the engine's reflection.

**Files changed:** `iOS/Brics/Game/GameScene.swift` — added `handleBallHitPaddle()`, dispatched before brick/wall handling in `didBegin(_:)`.

---

## [2026-03-03] Bricks not breaking on ball contact

### Symptom
The ball passed through or bounced off bricks without destroying them. No bricks were removed and the score never changed.

### Root Cause

**1. Indestructible guard blocked all removals.**
`handleBallHitBrick` had an early return for non-destructible bricks:
```swift
guard case .destructible = brick.brickType else { return }
```
Because all border bricks were typed `.indestructible`, they were skipped. But in practice the interior colored bricks were also not breaking — because `didBegin` fires on the physics thread and can be called multiple times for the same contact pair within one physics step. The first call would remove the brick; the second call would find the node already removed but `bricks` array still containing it, resulting in double-scoring and a corrupted win-check.

**2. No guard against double-contact.**
Without a `brick.parent != nil` check, the same brick contact could be processed twice in a single step — causing the `bricks` array to desync from the scene and the win condition to never trigger correctly.

**3. Win condition filtered only destructible bricks.**
```swift
let remainingDestructible = bricks.filter { $0.brickType.isDestructible }
if remainingDestructible.isEmpty { ... }
```
Since the border bricks were never removed (blocked by guard above), `remainingDestructible` could be empty while bricks were still on screen — or never reach empty at all depending on layout.

### Fix

- Removed the `guard case .destructible` check — all bricks now break on first contact regardless of type.
- Added `guard brick.parent != nil else { return }` as the first check to prevent double-processing within the same physics step.
- Changed win condition to `bricks.isEmpty` — triggers when every brick has been removed.
- Win state shows a congratulations message with final score; tapping restarts from scratch (lives and score reset).

```swift
private func handleBallHitBrick(_ brickBody: SKPhysicsBody) {
    guard let brick = brickBody.node as? Brick else { return }
    guard brick.parent != nil else { return }  // already removed this frame

    brick.removeFromParent()
    bricks.removeAll { $0 === brick }
    score += 10
    updateHUD()

    if bricks.isEmpty {
        triggerLevelComplete()
    }
}
```

### Lesson
Always guard against double-contact with `node.parent != nil` before removing nodes inside `didBegin`. SpriteKit can call the delegate multiple times per physics step for the same pair. Win conditions should check the authoritative collection (`bricks.isEmpty`), not a filtered subset.

**Files changed:** `iOS/Brics/Game/GameScene.swift` — `handleBallHitBrick`, `triggerLevelComplete`, `resetGame`.

---

## [2026-03-03] Ball does not reset to center after missing paddle

### Symptom
After the ball fell past the paddle and a life was lost, tapping to relaunch showed the ball at an incorrect position — offset from center or stuck at the bottom — instead of resetting to the center of the screen above the paddle.

### Root Cause

**1. Position assignment inside a physics step callback is overridden.**
`handleBallDeath` is called from `didBegin(_:)`, which fires during the physics simulation step. Setting `ball.position` directly inside this callback is unreliable — the physics engine finishes processing the current step after the callback returns and can overwrite the position that was just assigned. The velocity zero-out similarly may not take full effect until the next step.

**2. Paddle drifts off-center, disconnecting it from the reset ball.**
The paddle follows the player's touch and stays wherever it was when the ball was missed. `resetBallPosition` set `ball.position.x = size.width / 2` (correct), but the paddle was still at its last dragged position. This made the ball appear floating at center while the paddle sat to one side — visually confusing even when the position assignment did take effect.

### Fix

Deferred all position resets to the next run loop iteration via `DispatchQueue.main.async`, which executes after the current physics step has fully completed. Also reset paddle x to center at the same time so ball and paddle are visually aligned on respawn.

```swift
DispatchQueue.main.async { [weak self] in
    guard let self else { return }
    self.paddle.position.x = self.size.width / 2
    self.resetBallPosition()
}
```

### Lesson
Never set `physicsBody` position or velocity directly inside `didBegin(_:)` / `didEnd(_:)` — the physics engine is mid-step and will overwrite it. Defer mutations with `DispatchQueue.main.async` or via a flag checked in `update(_:)`.

**Files changed:** `iOS/Brics/Game/GameScene.swift` — `handleBallDeath`.

---

## [2026-03-03] Game Over screen — missing line break and paddle not recentering on restart

### Symptom
Two issues on game over:
1. "GAME OVER" and "Tap to restart" appeared on the same line as a single run-on string instead of on separate lines.
2. After tapping to restart, the ball reset to center but the paddle stayed wherever it was when the last life was lost.

### Root Cause

**1. `SKLabelNode` defaults to single-line rendering.**
`numberOfLines` defaults to `1` on `SKLabelNode`, which means `\n` characters in the text string are ignored — the label renders everything on one line. The `\n` was present in the string (`"GAME OVER\nTap to restart"`) but had no visual effect.

**2. `resetGame()` only reset the ball, not the paddle.**
`resetGame()` called `resetBallPosition()` which recenters the ball, but `paddle.position.x` was never touched. The paddle stayed at its last dragged position from the previous game, visually misaligned with the centered ball.

### Fix

Set `numberOfLines = 0` on `messageLabel` during setup (allows unlimited lines, respecting `\n`):

```swift
messageLabel.numberOfLines = 0
```

Reset paddle x to center in `resetGame()` alongside the ball:

```swift
paddle.position.x = size.width / 2
resetBallPosition()
```

### Lesson
`SKLabelNode` requires `numberOfLines = 0` to render multiline strings — the default is single-line regardless of `\n` in the content. Any reset that recenters the ball should also recenter the paddle; they are visually paired and should always be reset together.

**Files changed:** `iOS/Brics/Game/GameScene.swift` — `setupMessageLabel`, `resetGame`.
