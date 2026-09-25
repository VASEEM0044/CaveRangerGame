import SpriteKit

/// Base enemy class providing common functionality for all game enemies.
open class Enemy: SKSpriteNode, EnemyEntity {
    
    // MARK: - EnemyEntity Properties
    
    public var node: SKNode { self }
    public var enemyType: EnemyType { .snake }
    public var health: Int = 3
    public var maxHealth: Int = 3
    public var isAlive: Bool { health > 0 }
    
    public init(texture: SKTexture?, color: SKColor, size: CGSize) {
        super.init(texture: texture, color: color, size: size)
    }
    
    public required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    /// Receives damage from weapons or hazards.
    open func takeDamage(amount: Int) {
        health = max(0, health - amount)
    }
}
