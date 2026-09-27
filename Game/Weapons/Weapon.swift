import SpriteKit

/// Base implementation class for player weapons.
open class Weapon: SKNode, WeaponEntity {
    
    // MARK: - WeaponEntity Conformance
    
    public var weaponType: WeaponType { .whip }
    public var baseDamage: Int { GameConfig.Weapons.whipDamage }
    public var attackCooldown: TimeInterval { GameConfig.Weapons.whipCooldown }
    
    /// Tracks cooldown timer remaining before the next attack can occur.
    public internal(set) var cooldownTimer: TimeInterval = 0
    
    /// Indicates whether the weapon is currently actively executing an attack swing.
    public internal(set) var isAttacking: Bool = false
    
    public override init() {
        super.init()
        self.name = "weapon"
    }
    
    public required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    /// Per-frame update for cooldown and attack timers.
    open func update(deltaTime: TimeInterval) {
        if cooldownTimer > 0 {
            cooldownTimer -= deltaTime
        }
    }
    
    /// Starts cooldown timer when an attack begins.
    public func startCooldown() {
        cooldownTimer = attackCooldown
    }
    
    /// Protocol method for attack execution.
    open func attack(from origin: CGPoint, direction: FacingDirection, in parentNode: SKNode) {
        // Implemented by subclasses
    }
}
