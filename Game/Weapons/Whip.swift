import SpriteKit

/// Whip animation frame extractor using the centralized SpriteSheet utility.
public enum WhipAnimations {
    private static let spriteSheet = SpriteSheet(definition: AssetConfig.whip)
    
    public static let drawFrames   = spriteSheet.animationFrames(row: 1, startColumn: 0, count: 4)
    public static let attackFrames = spriteSheet.animationFrames(row: 2, startColumn: 0, count: 4)
    public static let impactFrames = spriteSheet.animationFrames(row: 4, startColumn: 0, count: 4)
    public static let returnFrames = spriteSheet.animationFrames(row: 3, startColumn: 0, count: 4)
}

/// The player's Whip weapon node.
/// Manages attack animation sequence (DRAW → ATTACK → IMPACT → RETURN),
/// melee hitbox creation, enemy collision detection, and damage application.
public final class Whip: Weapon {
    
    // MARK: - Properties
    
    public override var weaponType: WeaponType { .whip }
    public override var baseDamage: Int { GameConfig.Weapons.whipDamage }
    public override var attackCooldown: TimeInterval { GameConfig.Weapons.whipCooldown }
    
    /// The sprite node rendering the whip artwork.
    private let spriteNode: SKSpriteNode
    
    /// Optional debug rectangle node for visualizing the active attack hitbox.
    private var debugHitboxNode: SKShapeNode?
    
    /// Set of enemies damaged during the current attack swing to prevent per-frame multi-hits.
    private var damagedEnemiesInCurrentAttack = Set<ObjectIdentifier>()
    
    /// Active attack direction.
    private var currentFacing: FacingDirection = .right
    
    // MARK: - Initialization
    
    public override init() {
        let initialTexture = WhipAnimations.drawFrames.first ?? SKTexture()
        let displaySize = CGSize(width: 48.0, height: 48.0) // Render scale for 64×64 frame
        self.spriteNode = SKSpriteNode(texture: initialTexture, color: .clear, size: displaySize)
        
        super.init()
        
        self.name = "whip_weapon"
        self.zPosition = 12
        self.spriteNode.isHidden = true
        addChild(spriteNode)
    }
    
    public required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) is not supported for Whip")
    }
    
    // MARK: - Per-Frame Update
    
    public override func update(deltaTime: TimeInterval) {
        super.update(deltaTime: deltaTime)
    }
    
    // MARK: - Attack Execution
    
    /// Performs a whip attack from the player's position in their current facing direction.
    public func performAttack(playerPosition: CGPoint,
                              facing: FacingDirection,
                              parentScene: SKScene,
                              enemies: [EnemyEntity]) {
        guard cooldownTimer <= 0 && !isAttacking else { return }
        
        isAttacking = true
        startCooldown()
        currentFacing = facing
        damagedEnemiesInCurrentAttack.removeAll()
        
        AudioManager.shared.playSFX(.whipAttack)
        
        // Position relative to player's hand/chest
        let xOffset: CGFloat = facing == .right ? 22.0 : -22.0
        self.position = CGPoint(x: playerPosition.x + xOffset, y: playerPosition.y + 2.0)
        
        // Orient sprite according to facing direction
        spriteNode.xScale = facing == .right ? abs(spriteNode.xScale) : -abs(spriteNode.xScale)
        spriteNode.isHidden = false
        
        // Construct full attack sequence: DRAW -> ATTACK -> IMPACT -> RETURN
        let drawAction   = SKAction.animate(with: WhipAnimations.drawFrames, timePerFrame: 0.06, resize: false, restore: false)
        let attackAction = SKAction.animate(with: WhipAnimations.attackFrames, timePerFrame: 0.07, resize: false, restore: false)
        let impactAction = SKAction.animate(with: WhipAnimations.impactFrames, timePerFrame: 0.08, resize: false, restore: false)
        let returnAction = SKAction.animate(with: WhipAnimations.returnFrames, timePerFrame: 0.07, resize: false, restore: false)
        
        // Trigger hitbox check during ATTACK and IMPACT frames
        let triggerHitCheck = SKAction.run { [weak self, weak parentScene] in
            guard let self = self, let scene = parentScene else { return }
            self.checkHitbox(playerPosition: playerPosition, facing: facing, scene: scene, enemies: enemies)
        }
        
        let sequence = SKAction.sequence([
            drawAction,
            triggerHitCheck,
            attackAction,
            triggerHitCheck,
            impactAction,
            triggerHitCheck,
            returnAction,
            SKAction.run { [weak self] in
                self?.finishAttack()
            }
        ])
        
        spriteNode.run(sequence, withKey: "whip_strike")
    }
    
    // MARK: - Melee Hit Detection
    
    private func checkHitbox(playerPosition: CGPoint,
                            facing: FacingDirection,
                            scene: SKScene,
                            enemies: [EnemyEntity]) {
        let reach = GameConfig.Weapons.whipReach
        let hitboxWidth: CGFloat = reach
        let hitboxHeight: CGFloat = 28.0
        
        // Position hitbox in front of player depending on facing direction
        let hitboxX: CGFloat
        if facing == .right {
            hitboxX = playerPosition.x + 10.0 + hitboxWidth / 2.0
        } else {
            hitboxX = playerPosition.x - 10.0 - hitboxWidth / 2.0
        }
        let hitboxY = playerPosition.y
        let hitboxRect = CGRect(
            x: hitboxX - hitboxWidth / 2.0,
            y: hitboxY - hitboxHeight / 2.0,
            width: hitboxWidth,
            height: hitboxHeight
        )
        
        // Show debug outline if enabled
        updateDebugHitbox(rect: hitboxRect, scene: scene)
        
        // Check intersection against active enemies
        for enemy in enemies where enemy.isAlive {
            let enemyNode = enemy.node
            let enemyFrame = enemyNode.calculateAccumulatedFrame()
            
            if hitboxRect.intersects(enemyFrame) {
                let enemyId = ObjectIdentifier(enemy)
                if !damagedEnemiesInCurrentAttack.contains(enemyId) {
                    damagedEnemiesInCurrentAttack.insert(enemyId)
                    enemy.takeDamage(amount: baseDamage)
                    AudioManager.shared.playSFX(.whipImpact)
                    VFXManager.createImpactBurst(
                        at: enemyNode.position,
                        in: scene,
                        color: SKColor(red: 1.0, green: 0.85, blue: 0.30, alpha: 1.0),
                        particleCount: 8
                    )
                }
            }
        }
    }
    
    // MARK: - Attack Finish
    
    private func finishAttack() {
        isAttacking = false
        spriteNode.isHidden = true
        damagedEnemiesInCurrentAttack.removeAll()
        removeDebugHitbox()
    }
    
    // MARK: - Debug Hitbox Overlay
    
    private func updateDebugHitbox(rect: CGRect, scene: SKScene) {
        guard GameConfig.Debug.showPlayerDebug else { return }
        
        removeDebugHitbox()
        
        let shape = SKShapeNode(rect: rect, cornerRadius: 2)
        shape.strokeColor = .yellow
        shape.fillColor = SKColor.yellow.withAlphaComponent(0.2)
        shape.lineWidth = 1.0
        shape.zPosition = 100
        scene.addChild(shape)
        
        self.debugHitboxNode = shape
        
        // Auto-remove debug node after short delay
        shape.run(SKAction.sequence([
            SKAction.wait(forDuration: 0.2),
            SKAction.removeFromParent()
        ]))
    }
    
    private func removeDebugHitbox() {
        debugHitboxNode?.removeFromParent()
        debugHitboxNode = nil
    }
}
