import SpriteKit

/// State machine cases for SnakeEnemy AI.
public enum SnakeState: String, CaseIterable, Sendable {
    case idle
    case patrol
    case chase
    case attack
    case hurt
    case dead
}

/// Centralized animation definitions and texture extraction for the Snake enemy.
/// Sheet dimensions: 2048×2048, 64×64 frames (32 columns × 32 rows).
public enum SnakeAnimations {
    private static let spriteSheet = SpriteSheet(definition: AssetConfig.snakeEnemy)
    
    // MARK: - Animation Frame Definitions
    
    public static let idleFrames = spriteSheet.animationFrames(row: 0, startColumn: 0, count: 8)
    public static let slitherFrames = spriteSheet.animationFrames(row: 1, startColumn: 0, count: 8)
    public static let fastFrames = spriteSheet.animationFrames(row: 2, startColumn: 0, count: 8)
    public static let attackFrames = spriteSheet.animationFrames(row: 3, startColumn: 0, count: 8)
    public static let hurtFrames = spriteSheet.animationFrames(row: 4, startColumn: 0, count: 4)
    public static let deathFrames = spriteSheet.animationFrames(row: 5, startColumn: 0, count: 8)
    
    public static func textures(for state: SnakeState) -> [SKTexture] {
        switch state {
        case .idle:   return idleFrames
        case .patrol: return slitherFrames
        case .chase:  return fastFrames
        case .attack: return attackFrames
        case .hurt:   return hurtFrames
        case .dead:   return deathFrames
        }
    }
    
    public static func timePerFrame(for state: SnakeState) -> TimeInterval {
        switch state {
        case .idle:   return 0.12
        case .patrol: return 0.09
        case .chase:  return 0.07
        case .attack: return 0.08
        case .hurt:   return 0.10
        case .dead:   return 0.10
        }
    }
}

/// Snake enemy node implementing AI, platformer movement, animations, and combat interactions.
public final class SnakeEnemy: SKSpriteNode, EnemyEntity {
    
    // MARK: - EnemyEntity Conformance
    
    public var node: SKNode { self }
    public var enemyType: EnemyType { .snake }
    public var health: Int = 3
    public var maxHealth: Int = 3
    public var isAlive: Bool { health > 0 && currentState != .dead }
    
    // MARK: - AI & Movement Parameters
    
    public var moveSpeed: CGFloat = 35.0
    public var fastSpeed: CGFloat = 65.0
    public var detectionRange: CGFloat = 160.0
    public var attackRange: CGFloat = 36.0
    public var damage: Int = 1
    
    public var facingDirection: FacingDirection = .left
    public private(set) var currentState: SnakeState = .idle
    
    /// Spawn center position around which the snake patrols.
    public var spawnPosition: CGPoint = .zero
    public var patrolRadius: CGFloat = 70.0
    
    // MARK: - Cooldowns & Internal State
    
    private var attackCooldownTimer: TimeInterval = 0
    private var stateTimer: TimeInterval = 0
    private var patrolDirection: CGFloat = -1.0
    private var activeAnimKey: String?
    
    private var debugLabel: SKLabelNode?
    
    // MARK: - Initialization
    
    public init(spawnPosition: CGPoint) {
        self.spawnPosition = spawnPosition
        let initialTexture = SnakeAnimations.idleFrames.first ?? SKTexture()
        let displaySize = CGSize(width: 44.0, height: 44.0) // Render scale for 64×64 frame
        
        super.init(texture: initialTexture, color: .clear, size: displaySize)
        
        self.name = "snake_enemy"
        self.position = spawnPosition
        self.zPosition = 8
        
        setupPhysicsBody()
        setupDebugLabel()
        setAnimation(.idle)
    }
    
    public required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) is not supported for SnakeEnemy")
    }
    
    // MARK: - Physics Body Setup
    
    private func setupPhysicsBody() {
        let bodyWidth: CGFloat = self.size.width * 0.65  // ~28 pt
        let bodyHeight: CGFloat = self.size.height * 0.45 // ~20 pt
        let yOffset: CGFloat = -(self.size.height - bodyHeight) / 2.0 * 0.5
        
        let body = SKPhysicsBody(rectangleOf: CGSize(width: bodyWidth, height: bodyHeight),
                                 center: CGPoint(x: 0, y: yOffset))
        body.categoryBitMask = PhysicsCategory.enemy.rawValue
        body.collisionBitMask = PhysicsCategory.CollisionMasks.enemy
        body.contactTestBitMask = PhysicsCategory.ContactMasks.player
            | PhysicsCategory.ground.rawValue
        
        body.isDynamic = true
        body.affectedByGravity = true
        body.allowsRotation = false
        body.friction = 0.0
        body.restitution = 0.0
        
        self.physicsBody = body
    }
    
    // MARK: - Debug Label
    
    private func setupDebugLabel() {
        guard GameConfig.Debug.showPlayerDebug else { return }
        
        let label = SKLabelNode(fontNamed: "Courier")
        label.fontSize = 8
        label.fontColor = .red
        label.horizontalAlignmentMode = .center
        label.verticalAlignmentMode = .bottom
        label.position = CGPoint(x: 0, y: self.size.height / 2.0 + 2)
        label.zPosition = 100
        addChild(label)
        self.debugLabel = label
    }
    
    // MARK: - Per-Frame AI Update
    
    public func update(deltaTime: TimeInterval, currentTime: TimeInterval, player: Player?) {
        guard isAlive else { return }
        
        let dt = min(deltaTime, 1.0 / 30.0)
        
        // Cooldown timer tick
        if attackCooldownTimer > 0 {
            attackCooldownTimer -= dt
        }
        
        guard let player = player, player.isAlive else {
            updatePatrol(dt: CGFloat(dt))
            updateDebugLabel(distToPlayer: 999)
            return
        }
        
        let distToPlayer = hypot(player.position.x - self.position.x, player.position.y - self.position.y)
        
        // AI State Decision
        switch currentState {
        case .idle, .patrol:
            if distToPlayer <= detectionRange {
                transitionTo(.chase)
            } else {
                updatePatrol(dt: CGFloat(dt))
            }
            
        case .chase:
            if distToPlayer > detectionRange * 1.3 {
                transitionTo(.patrol)
            } else if distToPlayer <= attackRange && attackCooldownTimer <= 0 {
                performAttack(on: player)
            } else {
                updateChase(towards: player.position, dt: CGFloat(dt))
            }
            
        case .attack:
            // Waiting for attack animation to finish
            stateTimer -= dt
            if stateTimer <= 0 {
                transitionTo(.chase)
            }
            
        case .hurt:
            stateTimer -= dt
            if stateTimer <= 0 {
                transitionTo(.chase)
            }
            
        case .dead:
            break
        }
        
        updateDebugLabel(distToPlayer: distToPlayer)
    }
    
    // MARK: - AI Behaviors
    
    private func updatePatrol(dt: CGFloat) {
        let currentX = self.position.x
        
        // Turn around at patrol boundary
        if currentX <= spawnPosition.x - patrolRadius {
            patrolDirection = 1.0
        } else if currentX >= spawnPosition.x + patrolRadius {
            patrolDirection = -1.0
        }
        
        self.position.x += patrolDirection * moveSpeed * dt
        updateFacing(direction: patrolDirection)
        setAnimation(.patrol)
    }
    
    private func updateChase(towards target: CGPoint, dt: CGFloat) {
        let dx = target.x - self.position.x
        let dir: CGFloat = dx > 0 ? 1.0 : -1.0
        
        // Move towards player
        let currentSpeed = abs(dx) < 80.0 ? fastSpeed : moveSpeed
        self.position.x += dir * currentSpeed * dt
        
        updateFacing(direction: dir)
        setAnimation(currentSpeed == fastSpeed ? .chase : .patrol)
    }
    
    private func performAttack(on player: Player) {
        transitionTo(.attack)
        stateTimer = 0.6 // Attack duration
        attackCooldownTimer = 1.4 // Cooldown before next attack
        
        AudioManager.shared.playSFX(.snakeAttack)
        
        // Face player during attack
        let dir: CGFloat = (player.position.x - self.position.x) > 0 ? 1.0 : -1.0
        updateFacing(direction: dir)
        
        // Apply damage to player
        player.takeDamage(amount: damage)
    }
    
    // MARK: - State Machine & Animation
    
    private func transitionTo(_ newState: SnakeState) {
        guard currentState != newState && currentState != .dead else { return }
        currentState = newState
        setAnimation(newState)
    }
    
    private func setAnimation(_ state: SnakeState) {
        let key = "snake_anim_\(state.rawValue)"
        guard activeAnimKey != key else { return }
        
        self.removeAction(forKey: "snake_anim")
        activeAnimKey = key
        
        let textures = SnakeAnimations.textures(for: state)
        guard !textures.isEmpty else { return }
        
        let timePerFrame = SnakeAnimations.timePerFrame(for: state)
        let animate = SKAction.animate(with: textures, timePerFrame: timePerFrame, resize: false, restore: false)
        
        let action: SKAction
        if state == .attack || state == .hurt || state == .dead {
            action = animate
        } else {
            action = SKAction.repeatForever(animate)
        }
        
        self.run(action, withKey: "snake_anim")
    }
    
    private func updateFacing(direction: CGFloat) {
        if direction > 0.01 {
            facingDirection = .right
            self.xScale = -abs(self.xScale) // Sprite faces left by default in sheet
        } else if direction < -0.01 {
            facingDirection = .left
            self.xScale = abs(self.xScale)
        }
    }
    
    // MARK: - Damage & Death
    
    public func takeDamage(amount: Int) {
        guard isAlive else { return }
        
        health = max(0, health - amount)
        if health == 0 {
            die()
        } else {
            AudioManager.shared.playSFX(.snakeHurt)
            VFXManager.flashNode(self, color: .red, duration: 0.12)
            transitionTo(.hurt)
            stateTimer = 0.4
        }
    }
    
    private func die() {
        currentState = .dead
        physicsBody?.categoryBitMask = 0
        physicsBody?.collisionBitMask = 0
        
        AudioManager.shared.playSFX(.snakeDeath)
        if let parentNode = self.parent {
            VFXManager.createDustPuff(at: position, in: parentNode, particleCount: 8)
        }
        
        setAnimation(.dead)
        
        let fadeOut = SKAction.sequence([
            SKAction.wait(forDuration: 0.8),
            SKAction.fadeOut(withDuration: 0.4),
            SKAction.removeFromParent()
        ])
        self.run(fadeOut)
    }
    
    // MARK: - Debug
    
    private func updateDebugLabel(distToPlayer: CGFloat) {
        guard let label = debugLabel else { return }
        label.text = String(format: "HP:%d [%@] d:%.0f", health, currentState.rawValue.prefix(4).uppercased(), distToPlayer)
    }
}
