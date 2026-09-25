import SpriteKit

/// Facing direction for 2D character sprites.
public enum FacingDirection: Sendable {
    case left
    case right
}

/// Architectural foundation protocol for the player character.
/// Movement, jumping, and animation state machines will be implemented in subsequent phases.
public protocol PlayerEntity: AnyObject {
    /// Node representation within the SpriteKit scene tree.
    var node: SKNode { get }
    
    /// Current facing direction of the player sprite.
    var facingDirection: FacingDirection { get set }
    
    /// Current health pool.
    var currentHealth: Int { get set }
    
    /// Maximum health pool.
    var maxHealth: Int { get }
    
    /// Whether the player is currently alive.
    var isAlive: Bool { get }
}
