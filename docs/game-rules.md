# Brics — Game Rules

## Objective
Destroy all destructible (colored) bricks by bouncing the ball off the paddle. Clear every colored brick to complete the level.

## Controls
- **Tap** anywhere on screen to launch the ball from its starting position.
- **Drag** horizontally to move the paddle left or right.

## Ball
- Launches at a fixed upward angle on first tap.
- Bounces off the left wall, right wall, and top wall.
- Speed is normalized after each bounce to prevent drift.
- Falls off the bottom of the screen to cost a life.

## Paddle
- Moves horizontally only.
- Clamped to screen edges — cannot leave the play area.
- Contact with the ball reflects it upward.

## Bricks
| Type | Color | Behavior |
|------|-------|----------|
| Destructible | Red, Orange, Yellow, Green, Blue, Purple | Disappears on ball contact, awards points |
| Indestructible | Gray | Reflects ball, never destroyed |

### Brick Grid Layout
- 10 columns × 5 rows centered on screen.
- Colorful bricks fill the interior; gray bricks form the border (row 0, row 4, col 0, col 9).

## Scoring
- Each destructible brick destroyed: **+10 points**.
- Score displayed at top-center of screen.

## Lives
- Player starts with **3 lives**.
- A life is lost each time the ball exits through the bottom of the screen.
- Ball resets to start position; tap to re-launch.
- At 0 lives: **Game Over**.

## Win / Lose Conditions
- **Level Complete**: All destructible bricks destroyed.
- **Game Over**: Lives reach 0.

## HUD
- Top-left: Lives remaining (`Lives: X`)
- Top-center: Current score (`Score: XXXX`)
- Top-right: Current level (`Level: X`)

## Future Rules (Post-MVP)
- Multiple levels with increasing speed or complex layouts.
- Power-ups (multi-ball, wide paddle, laser).
- Online leaderboard via backend API.
