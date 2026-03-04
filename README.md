# Brics

A Breakout/Arkanoid-style iOS game built with SpriteKit and SwiftUI.

## Getting Started

### Prerequisites
- Xcode 15+
- iOS 17+ Simulator or device
- [xcodegen](https://github.com/yonaskolb/XcodeGen)

### Setup

```bash
brew install xcodegen
cd iOS
xcodegen generate
open Brics.xcodeproj
```

### Running
1. Select an iPhone 15 simulator in Xcode
2. Build and run (⌘R)
3. Tap to launch the ball

## Project Structure

```
brics/
├── iOS/           # iOS app (SpriteKit + SwiftUI)
├── backend/       # Future API (post-MVP)
└── docs/          # Game design docs
```

## Gameplay
- Tap to launch the ball
- Drag to move the paddle
- Destroy all colored bricks to complete a level
- Gray bricks are indestructible
- You have 3 lives — don't let the ball fall!
