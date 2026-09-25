import Foundation

/// Centralized bitmask categories for SpriteKit physics bodies and contact detection.
public struct PhysicsCategory: OptionSet, Sendable {
    public let rawValue: UInt32
    
    public init(rawValue: UInt32) {
        self.rawValue = rawValue
    }
    
    // MARK: - Categories (Bit Flags)
    
    public static let none        = PhysicsCategory([])
    public static let all         = PhysicsCategory(rawValue: UInt32.max)
    
    /// Player character physics body.
    public static let player      = PhysicsCategory(rawValue: 1 << 0) // 1
    
    /// Solid world ground, platforms, and static cave terrain.
    public static let ground      = PhysicsCategory(rawValue: 1 << 1) // 2
    
    /// Hostile creatures / enemies (e.g., snakes).
    public static let enemy       = PhysicsCategory(rawValue: 1 << 2) // 4
    
    /// Active melee weapons (e.g., whip).
    public static let weapon      = PhysicsCategory(rawValue: 1 << 3) // 8
    
    /// Collectible items (e.g., coins).
    public static let collectible = PhysicsCategory(rawValue: 1 << 4) // 16
    
    /// Stage exit door / mine exit portal.
    public static let exit        = PhysicsCategory(rawValue: 1 << 5) // 32
    
    /// Projectiles (e.g., revolver bullets).
    public static let projectile  = PhysicsCategory(rawValue: 1 << 6) // 64
    
    /// Environmental hazards (spikes, cave-ins, falling debris).
    public static let hazard      = PhysicsCategory(rawValue: 1 << 7) // 128
    
    // MARK: - Collision Mask Presets (Physical Impassable Barriers)
    
    public enum CollisionMasks {
        /// Standard solid collision mask for the player (stands on ground).
        public static let player: UInt32 = PhysicsCategory.ground.rawValue
        
        /// Standard solid collision mask for ground-bound enemies.
        public static let enemy: UInt32 = PhysicsCategory.ground.rawValue
        
        /// Projectiles collide with ground surfaces and enemies.
        public static let projectile: UInt32 = PhysicsCategory.ground.rawValue
            | PhysicsCategory.enemy.rawValue
            
        /// Triggers and sensors (collectibles, exit zones, weapon arcs) do not physically push bodies.
        public static let nonSolid: UInt32 = PhysicsCategory.none.rawValue
    }
    
    // MARK: - Contact Test Mask Presets (Event Notifications)
    
    public enum ContactMasks {
        /// Player registers contact events with enemies, collectibles, exits, and hazards.
        public static let player: UInt32 = PhysicsCategory.enemy.rawValue
            | PhysicsCategory.collectible.rawValue
            | PhysicsCategory.exit.rawValue
            | PhysicsCategory.hazard.rawValue
            
        /// Weapons register contact events with enemies and breakable hazards.
        public static let weapon: UInt32 = PhysicsCategory.enemy.rawValue
            | PhysicsCategory.hazard.rawValue
            
        /// Projectiles register contact events with enemies, ground, and hazards.
        public static let projectile: UInt32 = PhysicsCategory.enemy.rawValue
            | PhysicsCategory.ground.rawValue
            | PhysicsCategory.hazard.rawValue
    }
}
