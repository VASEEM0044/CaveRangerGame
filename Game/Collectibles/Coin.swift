import SpriteKit

/// Coin animation frame extraction using the centralized SpriteSheet utility.
public enum CoinAnimations {
    private static let spriteSheet = SpriteSheet(definition: AssetConfig.coin)
    
    public static let idleFrames     = spriteSheet.animationFrames(row: 0, startColumn: 0, count: 8)
    public static let rotationFrames = spriteSheet.animationFrames(row: 1, startColumn: 0, count: 8)
    public static let collectFrames  = spriteSheet.animationFrames(row: 2, startColumn: 0, count: 8)
    public static let sparkleFrames  = spriteSheet.animationFrames(row: 3, startColumn: 0, count: 8)
}

/// Gold coin collectible node placed throughout the underground mine.
/// Manages continuous spinning animation, player contact detection, pick-up sparkle sequence, and score notification.
public final class Coin: Collectible {
    
    // MARK: - Properties
    
    public override var collectibleType: CollectibleType { .coin }
    public override var scoreValue: Int { value }
    
    /// Point value awarded upon collection.
    public let value: Int
    
    /// Optional callback invoked when collected by the player.
    public var onCollectedHandler: ((Coin) -> Void)?
    
    // MARK: - Initialization
    
    public init(position: CGPoint, value: Int = 1) {
        self.value = value
        let initialTexture = CoinAnimations.rotationFrames.first ?? SKTexture()
        let displaySize = CGSize(width: 24.0, height: 24.0) // Render scale for 64×64 frame
        
        super.init(texture: initialTexture, color: .clear, size: displaySize)
        
        self.name = "coin"
        self.position = position
        self.zPosition = 6
        
        setupPhysicsBody()
        startSpinAnimation()
    }
    
    public required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) is not supported for Coin")
    }
    
    // MARK: - Physics Body
    
    private func setupPhysicsBody() {
        let body = SKPhysicsBody(circleOfRadius: 10.0)
        body.categoryBitMask = PhysicsCategory.collectible.rawValue
        body.collisionBitMask = PhysicsCategory.CollisionMasks.nonSolid // Non-solid sensor
        body.contactTestBitMask = PhysicsCategory.player.rawValue
        body.isDynamic = false
        
        self.physicsBody = body
    }
    
    // MARK: - Animations
    
    private func startSpinAnimation() {
        guard !CoinAnimations.rotationFrames.isEmpty else { return }
        let spin = SKAction.animate(with: CoinAnimations.rotationFrames, timePerFrame: 0.10, resize: false, restore: false)
        self.run(SKAction.repeatForever(spin), withKey: "coin_spin")
    }
    
    // MARK: - Collection Flow
    
    public override func onCollect(by player: PlayerEntity) {
        guard !isCollected else { return }
        super.onCollect(by: player)
        
        AudioManager.shared.playSFX(.coinCollect)
        if let parentNode = self.parent {
            VFXManager.createCoinSparkles(at: position, in: parentNode, particleCount: 8)
        }
        
        // Remove physics body immediately to prevent duplicate triggers
        self.physicsBody = nil
        self.removeAction(forKey: "coin_spin")
        
        // Notify tracking callback
        onCollectedHandler?(self)
        
        // Play COLLECT -> SPARKLE sequence then remove node
        let collectAnim = SKAction.animate(with: CoinAnimations.collectFrames, timePerFrame: 0.07, resize: false, restore: false)
        let sparkleAnim = SKAction.animate(with: CoinAnimations.sparkleFrames, timePerFrame: 0.07, resize: false, restore: false)
        let removeNode  = SKAction.removeFromParent()
        
        self.run(SKAction.sequence([collectAnim, sparkleAnim, removeNode]), withKey: "coin_pickup")
    }
}
