import SpriteKit

/// 4-frame animation extractor for ScorpionEnemy from row 2 of `cave_props_and_enemies.png`.
public enum ScorpionAnimations {
    public static var walkFrames: [SKTexture] {
        // Row 2: (200, 807, 417, 324), (888, 807, 418, 324), (1519, 807, 420, 324), (2168, 829, 451, 302)
        let rects = [
            CGRect(x: 200, y: 807, width: 417, height: 324),
            CGRect(x: 888, y: 807, width: 418, height: 324),
            CGRect(x: 1519, y: 807, width: 420, height: 324),
            CGRect(x: 2168, y: 829, width: 451, height: 302)
        ]
        return rects.map { TextureCache.shared.croppedTexture(from: "cave_props_and_enemies.png", pixelRect: $0) }
    }
}

/// Mid-tier cave patrol enemy that crawls along rocky ledges.
public final class ScorpionEnemy: SKSpriteNode, EnemyEntity {
    
    // MARK: - EnemyEntity Conformance
    
    public var node: SKNode { self }
    public var enemyType: EnemyType { .snake } // Re-uses basic enemy type category
    public var health: Int = 2
    public var maxHealth: Int = 2
    public var isAlive: Bool { health > 0 }
    
    public var moveSpeed: CGFloat = 40.0
    public var damage: Int = 1
    public var facingDirection: FacingDirection = .left
    
    public var spawnPosition: CGPoint = .zero
    public var patrolRadius: CGFloat = 80.0
    private var patrolDirection: CGFloat = -1.0
    
    // MARK: - Initialization
    
    public init(spawnPosition: CGPoint) {
        self.spawnPosition = spawnPosition
        let frames = ScorpionAnimations.walkFrames
        let initialTexture = frames.first ?? SKTexture()
        let displaySize = CGSize(width: 42.0, height: 32.0)
        
        super.init(texture: initialTexture, color: .clear, size: displaySize)
        
        self.name = "scorpion_enemy"
        self.position = spawnPosition
        self.zPosition = 8
        
        setupPhysicsBody()
        startWalkAnimation()
    }
    
    public required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) is not supported for ScorpionEnemy")
    }
    
    private func setupPhysicsBody() {
        let body = SKPhysicsBody(rectangleOf: CGSize(width: size.width * 0.8, height: size.height * 0.6),
                                 center: CGPoint(x: 0, y: -size.height * 0.15))
        body.categoryBitMask = PhysicsCategory.enemy.rawValue
        body.collisionBitMask = PhysicsCategory.CollisionMasks.enemy
        body.contactTestBitMask = PhysicsCategory.ContactMasks.player | PhysicsCategory.ground.rawValue
        body.isDynamic = true
        body.affectedByGravity = true
        body.allowsRotation = false
        self.physicsBody = body
    }
    
    private func startWalkAnimation() {
        let frames = ScorpionAnimations.walkFrames
        guard !frames.isEmpty else { return }
        let walk = SKAction.animate(with: frames, timePerFrame: 0.12, resize: false, restore: false)
        self.run(SKAction.repeatForever(walk), withKey: "scorpion_walk")
    }
    
    public func update(deltaTime: TimeInterval) {
        guard isAlive else { return }
        let dt = CGFloat(min(deltaTime, 1.0 / 30.0))
        
        if position.x <= spawnPosition.x - patrolRadius {
            patrolDirection = 1.0
            xScale = -abs(xScale) // face right
        } else if position.x >= spawnPosition.x + patrolRadius {
            patrolDirection = -1.0
            xScale = abs(xScale) // face left
        }
        
        position.x += patrolDirection * moveSpeed * dt
    }
    
    public func takeDamage(amount: Int) {
        guard isAlive else { return }
        health = max(0, health - amount)
        
        if health == 0 {
            AudioManager.shared.playSFX(.snakeDeath)
            if let parent = self.parent {
                VFXManager.createDustPuff(at: position, in: parent, particleCount: 6)
            }
            self.physicsBody = nil
            let die = SKAction.sequence([
                SKAction.scale(to: 0.2, duration: 0.2),
                SKAction.removeFromParent()
            ])
            self.run(die)
        } else {
            AudioManager.shared.playSFX(.snakeHurt)
            VFXManager.flashNode(self, color: .red, duration: 0.12)
        }
    }
}
