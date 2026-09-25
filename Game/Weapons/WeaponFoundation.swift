import SpriteKit

/// Identifies weapon types available to the player.
public enum WeaponType: Sendable {
    case whip
    case revolver
}

/// Architectural foundation protocol for player weapons.
/// Attack swings, projectile ballistics, cooldowns, and collision resolution will be implemented in subsequent phases.
public protocol WeaponEntity: AnyObject {
    /// Type of the weapon.
    var weaponType: WeaponType { get }
    
    /// Base damage inflicted per attack.
    var baseDamage: Int { get }
    
    /// Time in seconds between consecutive attacks.
    var attackCooldown: TimeInterval { get }
    
    /// Executes the primary attack action.
    func attack(from origin: CGPoint, direction: FacingDirection, in parentNode: SKNode)
}
