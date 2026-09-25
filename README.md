# Cave Ranger (iOS)

An original 2D retro pixel-art Western platformer built with Swift and SpriteKit for iOS.

## Project Identity

- **Game Name / Display Name:** Cave Ranger
- **Bundle Identifier:** `com.vntm.caverangerx`
- **Target Platform:** iOS 16.0+ (iPhone & iPad)
- **Engine / Framework:** Native SpriteKit + UIKit (Zero third-party engines)
- **CI / GitHub Friendly:** Clean repository layout, pure code-based setup, standard Xcode project structure.

---

## Architecture Overview

The codebase is organized into modular layers to ensure scalability, testability, and clean separation of concerns:

```
CaveRangerGame/
├── App/
│   ├── AppDelegate.swift            # Clean programmatic entry point (no Storyboards)
│   ├── GameViewController.swift     # Hosts the SKView, applies GameConfig debug flags
│   └── Info.plist                   # App bundle configuration (Orientation, Display Name, Bundle ID)
│
├── Assets/                          # Source artwork & sprite sheets (preserved intact)
│   ├── icon.png                     # Application icon (treated separately from gameplay)
│   ├── cowboy_player.png            # Player sprite sheet (128 × 128 frames)
│   ├── snake_enemy.png              # Snake enemy sprite sheet (64 × 64 frames)
│   ├── coin.png                     # Coin collectible sprite sheet (64 × 64 frames)
│   ├── whip.png                     # Whip weapon sprite sheet (64 × 64 frames)
│   ├── revolver.png                 # Revolver weapon sprite sheet (64 × 64 frames)
│   ├── mine_exit.png                # Mine exit portal sprite sheet (128 × 128 frames)
│   ├── mine_cave_tileset.png        # Environment tiles & props (configurable dimensions)
│   └── AppIcon.appiconset/          # iOS icon asset catalog metadata
│
└── Game/
    ├── GameConfig/
    │   ├── GameConfig.swift         # Global settings (640×360 canvas, 60fps, gravity, debug flags)
    │   └── AssetConfig.swift        # Centralized definitions for all gameplay sprite sheets
    │
    ├── GameState/
    │   └── GameState.swift          # Session states (PLAYING, PAUSED, LEVEL_COMPLETE, PLAYER_DEAD)
    │
    ├── GameScene/
    │   └── GameScene.swift          # Core SKScene lifecycle, physics world, and camera binding
    │
    ├── Physics/
    │   └── PhysicsCategory.swift    # Central bitmask categories & collision/contact test masks
    │
    ├── Camera/
    │   └── GameCamera.swift         # SKCameraNode subclass with lerp tracking and level clamping
    │
    ├── Utils/
    │   ├── SpriteSheet.swift        # Programmatic frame extraction via SKTexture(rect:in:)
    │   └── TextureCache.swift       # Thread-safe texture and subtexture caching
    │
    ├── Player/
    │   ├── PlayerFoundation.swift   # Architectural protocol for player character
    │   ├── Player.swift             # SKSpriteNode-based playable character
    │   ├── PlayerAnimation.swift    # Animation state definitions & texture extraction
    │   └── PlayerController.swift   # Keyboard input → movement commands
    ├── Enemies/
    │   └── EnemyFoundation.swift    # Architectural protocol for enemies & damage interactions
    ├── Weapons/
    │   └── WeaponFoundation.swift   # Architectural protocol for melee/ranged weapons
    ├── Collectibles/
    │   └── CollectibleFoundation.swift # Architectural protocol for pickable items
    ├── Level/
    │   └── LevelFoundation.swift    # Level layout data and builder abstractions
    └── UI/
        └── UIFoundation.swift       # UI and HUD overlay contract
```

---

## Foundation Systems

### 1. Game Configuration (`GameConfig` & `AssetConfig`)
- **Logical Resolution:** 640 × 360 (16:9 pixel-art canvas presented with `.aspectFit`).
- **Target Frame Rate:** 60 FPS.
- **Physics World:** Downward gravity vector `(dx: 0.0, dy: -18.0)`.
- **Debug Flags:** Centralized toggles for physics collision wireframes, FPS counter, and node counts.
- **Gameplay Asset Registry:** Fixed definitions for character and item sprite sheets, plus a configurable tileset specification for `mine_cave_tileset.png`.
- **App Icon Isolation:** `icon.png` is explicitly separated from gameplay assets and designated strictly for the iOS AppIcon.

### 2. Physics & Collision System (`PhysicsCategory`)
Categorized with `OptionSet` bit flags (`UInt32`):
- `player` (`1 << 0`)
- `ground` (`1 << 1`)
- `enemy` (`1 << 2`)
- `weapon` (`1 << 3`)
- `collectible` (`1 << 4`)
- `exit` (`1 << 5`)
- `projectile` (`1 << 6`)
- `hazard` (`1 << 7`)

Pre-configured masks:
- `CollisionMasks`: Physical contact barriers (e.g., player/enemies against ground).
- `ContactMasks`: Gameplay event triggers without physics repulsion (e.g., player collecting coins or contacting exits).

### 3. Programmatic SpriteSheet Slicing (`SpriteSheet`)
- Extracts frames dynamically in memory using SpriteKit's `SKTexture(rect:in:)`.
- **Zero File Modification:** Original PNG files remain pristine and are never cropped or overwritten.
- **Coordinate Conversion:** Automatically converts traditional 2D sprite sheet coordinates (top-to-bottom row index) into SpriteKit's normalized unit space with bottom-left origin `(0, 0)`.
- **Pixel-Art Clarity:** Enforces `filteringMode = .nearest` to preserve sharp pixel art across all scaling factors.
- **Supported Access Patterns:**
  - By row and column: `sheet.texture(row: 0, column: 2)`
  - By linear frame index: `sheet.texture(frameIndex: 5)`
  - Animation sequences: `sheet.animationFrames(row: 1, count: 4)`

### 4. Texture Caching (`TextureCache`)
- Thread-safe caching with `NSLock`.
- Caches both full source sheet textures and individual sliced subtextures under unique composite keys.
- Eliminates redundant GPU texture uploads and CPU math during animation loops.

### 5. Camera System (`GameCamera`)
- Subclass of `SKCameraNode`.
- Viewport size tracking with coordinate clamping within configurable `levelBounds`.
- Smooth follow target via linear interpolation (`smoothFactor`).
- Orthographic zoom scaling helpers.

### 6. Game State Machine (`GameState`)
- Four primary operational states:
  - `PLAYING`
  - `PAUSED`
  - `LEVEL_COMPLETE`
  - `PLAYER_DEAD`
- Validated state transition rules via `GameStateManager` with delegate notifications.

---

## Phase 2: Player System

### Player Character (`Player.swift`)
- Custom kinematic movement model with configurable acceleration, deceleration, and max speed.
- Jump with configurable force and manual gravity simulation for tight arcade platformer feel.
- Physics body sized to ~45% width × 75% height of the sprite for smooth platform edges.
- Anti-double-jump: jump only triggers when grounded.
- Terminal velocity clamping and world floor safety net.

### Animation State Machine (`PlayerAnimation.swift`)
- All 10 animation states defined with row/frame mappings to the 128×128 sprite sheet.
- Phase 2 implements: `idle`, `run`, `jump`, `fall`.
- Remaining states (`land`, `climb`, `whipAttack`, `shootAttack`, `hurt`, `death`) configured for future phases.
- State transitions only trigger animation restarts when the state actually changes.
- Textures pre-extracted and cached via `SpriteSheet` + `TextureCache`.

### Input System (`PlayerController.swift`)
- `GCKeyboard` (Game Controller framework) for iOS hardware keyboard support.
- macOS Catalyst / Simulator key event forwarding via `keyDown`/`keyUp`.
- Controls: `A`/`←` move left, `D`/`→` move right, `Space` jump.
- Edge-triggered jump (single press = single jump, holding doesn't repeat).

### Keyboard Controls (Development)

| Key | Action |
| :---: | :--- |
| `A` / `←` | Move left |
| `D` / `→` | Move right |
| `Space` | Jump |

### Test Ground
- Temporary flat platform (1200 pt wide) + elevated jump test platform.
- Uses `PhysicsCategory.ground` for proper collision and contact detection.
- Will be replaced by the tilemap level system in Phase 3.

### Camera
- `GameCamera` smoothly follows the player position each frame.

### Debug
- `GameConfig.Debug.showPlayerDebug`: when `true`, renders position/velocity/grounded overlay above the player.

---

## Phase 3: Mine Environment & Terrain Collision

### Mine Tileset & Environment (`MineTileset.swift` & `MineLevel.swift`)
- Configured 2048×2048 `mine_cave_tileset.png` with 4×4 grid of 512×512 decorative entrance frames.
- Color palette constants sampled from artwork: `rockDark`, `rockMedium`, `rockLight`, `caveDark`, `woodBrown`, `woodDark`, `groundDirt`, `ceilingDark`.
- Background depth layer with dimmed mine entrance frames for parallax/cave atmosphere.
- Multi-section cave level structure (2400 pt wide × 720 pt tall):
  1. Starting cave corridor
  2. Stepping platforms over lower pit
  3. Lower cave section
  4. Raised wooden trestle platform
  5. Open cave area with high platform and exit tunnel

### Optimized Collision Geometry (`LevelCollision.swift`)
- Decoupled collision geometry from visual artwork — merged rectangular collision shapes.
- One-way platforms for upper stepping ledges and wooden trestles.
- Left and right world boundaries to prevent leaving the level.
- Death pit fall detection (`deathY = -100`) resetting player to spawn point `(100, 180)`.
- Camera clamped strictly within world boundaries `(2400 × 720)`.

---

## Phase 4: Snake Enemy System

### Base Enemy Abstraction & Snake Enemy (`Enemy.swift` & `SnakeEnemy.swift`)
- Base `Enemy` class implementing `EnemyEntity` interface for future enemy expansion.
- `SnakeEnemy` node with 6-state AI state machine: `idle`, `patrol`, `chase`, `attack`, `hurt`, `dead`.
- Integrated with `snake_enemy.png` (2048×2048, 64×64 frame grid, 32×32 cells) and cached texture animations via `SnakeAnimations`:
  - `IDLE` (8 frames, 0.12s/frame)
  - `SLITHER` (8 frames, 0.09s/frame)
  - `FAST` (8 frames, 0.07s/frame)
  - `ATTACK` (8 frames, 0.08s/frame)
  - `HURT` (4 frames, 0.10s/frame)
  - `DEATH` (8 frames, 0.10s/frame)

### AI Behavior & Player Interaction
- **Patrol**: Snake slowly patrols horizontal radius (±70pt) around spawn point, turning when reaching boundary or wall.
- **Player Detection & Chase**: Distance check (`detectionRange = 160pt`). Switches from patrol to chase when player enters range, accelerating to fast speed when close.
- **Attack & Damage**: Triggers attack animation when player within `attackRange = 36pt` with a 1.4s cooldown. Calls `player.takeDamage(amount: 1)`.
- **Player Response**: Player receives 1.0s invulnerability flashing, slight knockback impulse, and hurt animation without per-frame damage spam.
- **Death**: On reaching 0 health, snake plays death animation, disables physics/collision, and fades out.
- **Placement**: 3 test snakes spawned in MineLevel (Starting corridor, Lower cave, Open cave area).

---

## Phase 5: Whip Combat System

### Base Weapon Abstraction & Whip Weapon (`Weapon.swift` & `Whip.swift`)
- Base `Weapon` class implementing `WeaponEntity` protocol for weapon expansion (Whip & Revolver).
- `Whip` node attached to the player with animation sequence via `WhipAnimations`:
  - Sequence: `DRAW` (0.06s/frame) → `ATTACK` (0.07s/frame) → `IMPACT` (0.08s/frame) → `RETURN` (0.07s/frame)
- Integrated with `whip.png` (2048×2048, 64×64 frames).

### Controls, Timing & Melee Hit Detection
- **Input**: `J` or `X` keys trigger the whip attack.
- **Cooldown**: `0.40s` cooldown between consecutive attacks (`GameConfig.Weapons.whipCooldown`).
- **Hit Detection**: Active rectangular hitbox (`reach = 55pt`, `height = 28pt`) extending in front of the player based on facing direction.
- **Damage & Anti-Multi-Hit**: Inflicts `whipDamage = 1` to enemies in range. Uses a per-swing `Set<ObjectIdentifier>` to ensure each enemy is hit only once per attack swing.
- **Snake Combat Response**: Whip hits trigger `snake.takeDamage(amount: 1)`, causing hurt animations, health deduction, and eventual death flow.
- **Debug Hitbox**: Displays yellow outline around the active attack range when `GameConfig.Debug.showPlayerDebug` is enabled.

---

## Building and Continuous Integration (CI)

To compile and verify the project using command-line tools on macOS or CI runners (GitHub Actions):

```bash
# Build the project
xcodebuild clean build \
  -project CaveRangerGame.xcodeproj \
  -scheme CaveRangerGame \
  -destination 'generic/platform=iOS' \
  -configuration Debug
```

---

## Next Development Steps

1. ~~**Phase 2:** Player movement, platform physics, and jump curves.~~ ✅ Complete
2. ~~**Phase 3:** Tilemap rendering and cave level layout using `mine_cave_tileset.png`.~~ ✅ Complete
3. ~~**Phase 4:** Snake enemy system (AI, animations, combat contact, death).~~ ✅ Complete
4. ~~**Phase 5:** Whip combat system (animations, J/X input, melee hitbox, snake damage).~~ ✅ Complete
5. **Phase 6:** Revolver weapon & projectile ballistics.
6. **Phase 7:** Coins & exit portal triggers.
7. **Phase 8:** On-screen controls, HUD, and pause menu overlays.
