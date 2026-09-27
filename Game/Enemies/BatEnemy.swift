import SpriteKit

/// 4-frame animation extractor for BatEnemy from row 3 of `cave_props_and_enemies.png`.
public enum BatAnimations {
    public static var flyFrames: [SKTexture] {
        // Row 3: (175, 1219, 450, 245), (909, 1169, 337, 289), (1594, 1224, 293, 239), (2193, 1205, 352, 247)
        let rects = [
            CGRect(x: 175, y: 1219, width: 450, height: 245),
            CGRect(x: 909, y: 1169, width: 337, height: 289),
            CGRect(x: 1594, y: 1224, width: 293, height: 239),
            CGRect(x: 2193, y: 1205, width: 352, height: 247)
        ]
        return rects.map { TextureCache.shared.croppedTexture(from: "cave_props_and_enemies.png", pixelRect: $0) }
    }
}

/// Ceiling hanging enemy that swoops down in a dive-arc when the player gets close.
public final class BatEnemy: SKSpriteNode, EnemyEntity {
    
    // MARK: - EnemyEntity Conformance
    
    public var node: SKNode { self }
    public var enemyType: EnemyType { .snake }
    public var health: Int = 1
    public var maxHealth: Int = 1
    public var isAlive: Bool { health > 0 }
    
    public var damage: Int = 1
    public var facingDirection: FacingDirection = .left
    
    public let roostPosition: CGPoint
    private var isSwooping: Bool = false
    private var swoopTimer: CGFloat = 0.0
    
    // MARK: - Initialization
    
    public init(roostPosition: CGPoint) {
        self.roostPosition = roostPosition
        let frames = BatAnimations.flyFrames
        let initialTexture = frames.first ?? SKTexture()
        let displaySize = CGSize(width: 38.0, height: 26.0)
        
        super.init(texture: initialTexture, color: .clear, size: displaySize)
        
        self.name = "bat_enemy"
        self.position = roostPosition
        self.zPosition = 8
        
        setupPhysicsBody()
        startFlyAnimation()
    }
    
    public required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) is not supported for BatEnemy")
    }
    
    private func setupPhysicsBody() {
        let body = SKPhysicsBody(circleOfRadius: 12.0)
        body.categoryBitMask = PhysicsCategory.enemy.rawValue
        body.collisionBitMask = PhysicsCategory.none.rawValue // Non-solid flying enemy
        body.contactTestBitMask = PhysicsCategory.ContactMasks.player
        body.isDynamic = false
        self.physicsBody = body
    }
    
    private func startFlyAnimation() {
        let frames = BatAnimations.flyFrames
        guard !frames.isEmpty else { return }
        let fly = SKAction.animate(with: frames, timePerFrame: 0.10, resize: false, restore: false)
        self.run(SKAction.repeatForever(fly), withKey: "bat_fly")
    }
    
    public func update(deltaTime: TimeInterval, player: Player?) {
        guard isAlive else { return }
        let dt = CGFloat(min(deltaTime, 1.0 / 30.0))
        
        guard let player = player, player.isAlive else { return }
        let dist = hypot(player.position.x - position.x, player.position.y - position.y)
        
        if !isSwooping && dist < 180.0 && player.position.y < position.y {
            isSwooping = true
            swoopTimer = 0.0
            AudioManager.shared.playSFX(.snakeAttack)
        }
        
        if isSwooping {
            swoopTimer += dt * 2.5
            // Sinusoidal swoop down and back up
            let dx = (player.position.x - roostPosition.x) * min(1.0, swoopTimer)
            let dy = -sin(swoopTimer * .pi) * 120.0
            
            position = CGPoint(x: roostPosition.x + dx, y: roostPosition.y + dy)
            
            if swoopTimer >= 1.0 {
                // Return to roost
                isSwooping = false
                position = roostPosition
            }
        }
    }
    
    public func takeDamage(amount: Int) {
        guard isAlive else { return }
        health = max(0, health - amount)
        
        if health == 0 {
            AudioManager.shared.playSFX(.snakeDeath)
            if let parent = self.parent {
                VFXManager.createDustPuff(at: position, in: parent, particleCount: 5)
            }
            self.physicsBody = nil
            let die = SKAction.sequence([
                SKAction.scale(to: 0.1, duration: 0.15),
                SKAction.removeFromParent()
            ])
            self.run(die)
        }
    }
}
