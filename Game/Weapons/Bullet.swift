import SpriteKit

/// Projectile bullet node fired by the Revolver weapon.
/// Manages linear flight trajectory, physics contact setup, lifetime expiration, and impact visual effects.
public final class Bullet: SKSpriteNode {
    
    // MARK: - Properties
    
    /// Base damage inflicted on impact.
    public let damage: Int
    
    /// Flight velocity in points per second.
    public let speedValue: CGFloat
    
    /// Direction of flight.
    public let direction: FacingDirection
    
    /// Maximum flight lifetime before auto-removal.
    public let lifetime: TimeInterval
    
    /// Accumulated age of the bullet in seconds.
    private var age: TimeInterval = 0
    
    // MARK: - Texture Extraction
    
    private static let spriteSheet = SpriteSheet(definition: AssetConfig.revolver)
    public static let bulletTexture = spriteSheet.texture(row: 6, column: 0)
    public static let impactFrames  = spriteSheet.animationFrames(row: 7, startColumn: 0, count: 4)
    
    // MARK: - Initialization
    
    public init(spawnPosition: CGPoint, direction: FacingDirection) {
        self.damage = GameConfig.Weapons.revolverDamage
        self.speedValue = GameConfig.Weapons.bulletSpeed
        self.direction = direction
        self.lifetime = GameConfig.Weapons.bulletLifetime
        
        let displaySize = CGSize(width: 16.0, height: 8.0)
        
        super.init(texture: Bullet.bulletTexture, color: .clear, size: displaySize)
        
        self.name = "bullet"
        self.position = spawnPosition
        self.zPosition = 11
        
        // Orient sprite to match direction
        self.xScale = direction == .right ? 1.0 : -1.0
        
        setupPhysicsBody()
    }
    
    public required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) is not supported for Bullet")
    }
    
    // MARK: - Physics Body
    
    private func setupPhysicsBody() {
        let body = SKPhysicsBody(rectangleOf: self.size)
        body.categoryBitMask = PhysicsCategory.projectile.rawValue
        body.collisionBitMask = PhysicsCategory.CollisionMasks.nonSolid // Non-solid to prevent physical pushing
        body.contactTestBitMask = PhysicsCategory.ContactMasks.projectile
        
        body.isDynamic = true
        body.affectedByGravity = false
        body.allowsRotation = false
        
        self.physicsBody = body
    }
    
    // MARK: - Per-Frame Flight Update
    
    public func update(deltaTime: TimeInterval) {
        age += deltaTime
        
        // Linear movement
        let dirSign: CGFloat = direction == .right ? 1.0 : -1.0
        self.position.x += dirSign * speedValue * CGFloat(deltaTime)
        
        // Auto-remove on lifetime expiration or out of level bounds
        if age >= lifetime || self.position.x < -50 || self.position.x > MineLevel.worldWidth + 50 {
            destroySelf(showImpact: false)
        }
    }
    
    // MARK: - Destruction & Impact Effect
    
    public func destroySelf(showImpact: Bool) {
        guard self.parent != nil else { return }
        
        if showImpact, let scene = self.scene {
            spawnImpactEffect(in: scene, position: self.position)
        }
        
        self.removeFromParent()
    }
    
    private func spawnImpactEffect(in scene: SKScene, position: CGPoint) {
        AudioManager.shared.playSFX(.bulletImpact)
        VFXManager.createImpactBurst(at: position, in: scene, color: .white, particleCount: 6)
        
        guard !Bullet.impactFrames.isEmpty else { return }
        
        let impactNode = SKSpriteNode(texture: Bullet.impactFrames.first, size: CGSize(width: 24, height: 24))
        impactNode.position = position
        impactNode.zPosition = 15
        scene.addChild(impactNode)
        
        let animate = SKAction.animate(with: Bullet.impactFrames, timePerFrame: 0.05, resize: false, restore: false)
        let remove = SKAction.removeFromParent()
        impactNode.run(SKAction.sequence([animate, remove]))
    }
}
