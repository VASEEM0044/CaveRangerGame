import SpriteKit

/// All possible animation states for the player character.
/// Each case maps to a specific row and frame range in the cowboy_player.png sprite sheet.
public enum PlayerAnimationState: String, CaseIterable, Sendable {
    case idle
    case run
    case jump
    case fall
    case land
    case climb
    case whipAttack
    case shootAttack
    case hurt
    case death
}

/// Centralized animation frame definitions extracted from the cowboy_player.png sprite sheet.
///
/// Sprite sheet layout (128×128 per frame, 12 columns × 8 rows):
///   Row 0: Idle (12 frames)
///   Row 1: Run (12 frames)
///   Row 2: Jump / Fall / Land (mixed action frames, 12 frames)
///   Row 3: Ladder climb (12 frames)
///   Row 4: Whip attack (9 frames)
///   Row 5: Revolver shoot (12 frames)
///   Row 6: Hurt (12 frames)
///   Row 7: Death (12 frames)
public struct PlayerAnimationDef: Sendable {
    /// Which row in the sprite sheet to pull frames from.
    public let row: Int
    
    /// Starting column (0-indexed) within that row.
    public let startFrame: Int
    
    /// Number of frames to extract from that row.
    public let frameCount: Int
    
    /// Seconds per frame during playback.
    public let timePerFrame: TimeInterval
    
    /// Whether the animation loops continuously.
    public let loops: Bool
    
    public init(row: Int, startFrame: Int, frameCount: Int, timePerFrame: TimeInterval, loops: Bool) {
        self.row = row
        self.startFrame = startFrame
        self.frameCount = frameCount
        self.timePerFrame = timePerFrame
        self.loops = loops
    }
}

/// Central registry mapping each PlayerAnimationState to its sprite sheet definition.
public enum PlayerAnimations {
    
    // MARK: - Implemented Animations (Phase 2)
    
    public static let idle = PlayerAnimationDef(
        row: 0, startFrame: 0, frameCount: 12, timePerFrame: 0.12, loops: true
    )
    
    public static let run = PlayerAnimationDef(
        row: 1, startFrame: 0, frameCount: 12, timePerFrame: 0.08, loops: true
    )
    
    /// Jump uses the first few frames of row 2 (the airborne action row).
    public static let jump = PlayerAnimationDef(
        row: 2, startFrame: 0, frameCount: 3, timePerFrame: 0.10, loops: false
    )
    
    /// Fall uses frames from the middle of row 2.
    public static let fall = PlayerAnimationDef(
        row: 2, startFrame: 3, frameCount: 3, timePerFrame: 0.10, loops: false
    )
    
    // MARK: - Defined for Future Use
    
    /// Landing transition uses the latter portion of row 2.
    public static let land = PlayerAnimationDef(
        row: 2, startFrame: 6, frameCount: 3, timePerFrame: 0.06, loops: false
    )
    
    public static let climb = PlayerAnimationDef(
        row: 3, startFrame: 0, frameCount: 12, timePerFrame: 0.10, loops: true
    )
    
    public static let whipAttack = PlayerAnimationDef(
        row: 4, startFrame: 0, frameCount: 9, timePerFrame: 0.06, loops: false
    )
    
    public static let shootAttack = PlayerAnimationDef(
        row: 5, startFrame: 0, frameCount: 12, timePerFrame: 0.06, loops: false
    )
    
    public static let hurt = PlayerAnimationDef(
        row: 6, startFrame: 0, frameCount: 4, timePerFrame: 0.08, loops: false
    )
    
    public static let death = PlayerAnimationDef(
        row: 7, startFrame: 0, frameCount: 8, timePerFrame: 0.10, loops: false
    )
    
    // MARK: - Lookup
    
    /// Returns the animation definition for a given state.
    public static func definition(for state: PlayerAnimationState) -> PlayerAnimationDef {
        switch state {
        case .idle:        return idle
        case .run:         return run
        case .jump:        return jump
        case .fall:        return fall
        case .land:        return land
        case .climb:       return climb
        case .whipAttack:  return whipAttack
        case .shootAttack: return shootAttack
        case .hurt:        return hurt
        case .death:       return death
        }
    }
    
    // MARK: - Texture Extraction
    
    /// Lazily-initialized sprite sheet for the cowboy player.
    private static let spriteSheet = SpriteSheet(definition: AssetConfig.cowboyPlayer)
    
    /// Extracts and caches the array of SKTexture frames for a given animation state.
    public static func textures(for state: PlayerAnimationState) -> [SKTexture] {
        let def = definition(for: state)
        return spriteSheet.animationFrames(
            row: def.row,
            startColumn: def.startFrame,
            count: def.frameCount
        )
    }
}
