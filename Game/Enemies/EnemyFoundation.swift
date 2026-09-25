import SpriteKit

/// Identifies categories of enemy entities.
public enum EnemyType: Sendable {
    case snake
}

/// Architectural foundation protocol for hostile entities.
/// Patrol AI, damage interactions, and attack behaviors will be implemented in subsequent phases.
public protocol EnemyEntity: AnyObject {
    /// SpriteKit node representing the enemy.
    var node: SKNode { get }
    
    /// Type classification of the enemy.
    var enemyType: EnemyType { get }
    
    /// Current health pool.
    var health: Int { get set }
    
    /// Indicates whether the enemy is still active and alive in the scene.
    var isAlive: Bool { get }
    
    /// Receives damage from weapons or hazards.
    func takeDamage(amount: Int)
}
