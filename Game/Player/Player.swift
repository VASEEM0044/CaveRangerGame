import SpriteKit

/// The playable cowboy character — an SKSpriteNode-based entity with custom kinematic
/// movement, sprite-sheet animation, and physics body integration.
///
/// Movement uses a custom velocity model (acceleration / deceleration / gravity) applied
/// each frame rather than relying on SpriteKit's built-in dynamic simulation for horizontal
/// control, giving tight arcade-platformer feel. The physics body is used only for
/// collision detection and ground contact, not for driving movement.
public final class Player: SKSpriteNode, PlayerEntity {
    
    // MARK: - PlayerEntity Conformance
    
    public var node: SKNode { self }
    public var facingDirection: FacingDirection = .right
    public var currentHealth: Int = 3
    public let maxHealth: Int = 3
    public var isAlive: Bool { currentHealth > 0 }
    
    // MARK: - Movement Properties
    
    /// Current horizontal velocity in points per second.
    public var velocityX: CGFloat = 0.0
    
    /// Current vertical velocity in points per second.
    public var velocityY: CGFloat = 0.0
    
    /// Maximum horizontal speed (configurable via GameConfig).
    public var movementSpeed: CGFloat = GameConfig.Player.movementSpeed
    
    /// Horizontal acceleration (configurable via GameConfig).
    public var acceleration: CGFloat = GameConfig.Player.acceleration
    
    /// Horizontal deceleration / friction (configurable via GameConfig).
    public var deceleration: CGFloat = GameConfig.Player.deceleration
    
    /// Upward impulse applied on jump (configurable via GameConfig).
    public var jumpForce: CGFloat = GameConfig.Player.jumpForce
    
    /// Downward acceleration (configurable via GameConfig).
    public var gravity: CGFloat = GameConfig.Player.gravity
    
    // MARK: - State
    
    /// Whether the player is currently touching a ground surface.
    public var isGrounded: Bool = false
    
    /// The current animation state driving sprite playback.
    public private(set) var currentAnimationState: PlayerAnimationState = .idle
    
    /// Tracks which animation is actively playing to avoid restarting on every frame.
    private var activeAnimationKey: String?
    
    // MARK: - Debug
    
    private var debugLabel: SKLabelNode?
    
    // MARK: - Weapon Properties
    
    /// Currently equipped Whip weapon.
    public private(set) var whip: Whip!
    
    // MARK: - Initialization
    
    /// Creates a new Player node with the first idle frame as the initial texture.
    public init() {
        let initialTextures = PlayerAnimations.textures(for: .idle)
        let firstFrame = initialTextures.first ?? SKTexture(imageNamed: AssetConfig.cowboyPlayer.fileName)
        let renderScale = GameConfig.Player.renderScale
        let frameSize = AssetConfig.cowboyPlayer.frameSize
        let displaySize = CGSize(
            width: frameSize.width * renderScale,
            height: frameSize.height * renderScale
        )
        
        super.init(texture: firstFrame, color: .clear, size: displaySize)
        
        self.name = "player"
        self.zPosition = 10
        
        setupWeapon()
        setupPhysicsBody()
        setupDebugLabel()
    }
    
    private func setupWeapon() {
        whip = Whip()
        addChild(whip)
    }
    
    public required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) is not supported for Player")
    }
    
    // MARK: - Attack Action
    
    /// Triggers a whip attack towards current facing direction if not on cooldown.
    public func performWhipAttack(enemies: [EnemyEntity], parentScene: SKScene) {
        guard isAlive && !whip.isAttacking else { return }
        
        setAnimation(.whipAttack)
        whip.performAttack(
            playerPosition: self.position,
            facing: facingDirection,
            parentScene: parentScene,
            enemies: enemies
        )
    }
    
    // MARK: - Physics Body
    
    private func setupPhysicsBody() {
        // Use a smaller rectangular body around the character's torso and legs,
        // not the full 64×64 rendered size. This prevents snagging on edges and
        // gives tighter platforming feel.
        let bodyWidth: CGFloat = self.size.width * 0.45   // ~29 pt wide
        let bodyHeight: CGFloat = self.size.height * 0.75 // ~48 pt tall
        
        // Offset the body downward so the feet sit at the bottom of the sprite.
        let yOffset: CGFloat = -(self.size.height - bodyHeight) / 2.0 * 0.5
        let bodyCenter = CGPoint(x: 0.0, y: yOffset)
        let bodySize = CGSize(width: bodyWidth, height: bodyHeight)
        
        let body = SKPhysicsBody(rectangleOf: bodySize, center: bodyCenter)
        body.categoryBitMask = PhysicsCategory.player.rawValue
        body.collisionBitMask = PhysicsCategory.CollisionMasks.player
        body.contactTestBitMask = PhysicsCategory.ContactMasks.player
            | PhysicsCategory.ground.rawValue  // Detect ground contact for landing
        
        // The player is dynamic but we drive velocity manually each frame.
        body.isDynamic = true
        body.affectedByGravity = false        // We apply gravity manually for tighter control.
        body.allowsRotation = false
        body.friction = 0.0
        body.restitution = 0.0
        body.linearDamping = 0.0
        
        self.physicsBody = body
    }
    
    // MARK: - Debug Label
    
    private func setupDebugLabel() {
        guard GameConfig.Debug.showPlayerDebug else { return }
        
        let label = SKLabelNode(fontNamed: "Courier")
        label.fontSize = 8
        label.fontColor = .green
        label.horizontalAlignmentMode = .center
        label.verticalAlignmentMode = .bottom
        label.position = CGPoint(x: 0, y: self.size.height / 2.0 + 4)
        label.zPosition = 100
        label.name = "player_debug_label"
        addChild(label)
        self.debugLabel = label
    }
    
    // MARK: - Per-Frame Update
    
    /// Called every frame by GameScene to apply movement, gravity, and animation.
    public func update(deltaTime: TimeInterval, inputDirection: CGFloat, jumpRequested: Bool) {
        let dt = CGFloat(min(deltaTime, 1.0 / 30.0)) // Cap delta to prevent spiral on lag spikes
        
        whip.update(deltaTime: deltaTime)
        applyHorizontalMovement(direction: inputDirection, dt: dt)
        applyGravityAndJump(jumpRequested: jumpRequested, dt: dt)
        applyVelocity(dt: dt)
        updateFacing(direction: inputDirection)
        updateAnimationState()
        updateDebugLabel()
    }
    
    // MARK: - Horizontal Movement
    
    private func applyHorizontalMovement(direction: CGFloat, dt: CGFloat) {
        if abs(direction) > 0.01 {
            // Accelerate towards desired direction
            velocityX += direction * acceleration * dt
            // Clamp to max speed
            velocityX = max(-movementSpeed, min(movementSpeed, velocityX))
        } else {
            // Decelerate (friction)
            if abs(velocityX) < deceleration * dt {
                velocityX = 0.0
            } else {
                velocityX -= (velocityX > 0 ? 1.0 : -1.0) * deceleration * dt
            }
        }
    }
    
    // MARK: - Gravity & Jump
    
    private func applyGravityAndJump(jumpRequested: Bool, dt: CGFloat) {
        // Jump only when grounded and jump is requested
        if jumpRequested && isGrounded {
            velocityY = jumpForce
            isGrounded = false
        }
        
        // Apply gravity every frame (manual simulation)
        velocityY -= gravity * dt
        
        // Clamp terminal velocity
        velocityY = max(-GameConfig.Player.maxFallSpeed, velocityY)
    }
    
    // MARK: - Apply Velocity
    
    private func applyVelocity(dt: CGFloat) {
        self.position.x += velocityX * dt
        self.position.y += velocityY * dt
    }
    
    // MARK: - Facing Direction
    
    private func updateFacing(direction: CGFloat) {
        if direction > 0.01 {
            facingDirection = .right
            self.xScale = abs(self.xScale) // Face right (default sheet orientation)
        } else if direction < -0.01 {
            facingDirection = .left
            self.xScale = -abs(self.xScale) // Flip horizontally
        }
        // If direction == 0, keep current facing
    }
    
    // MARK: - Animation State Machine
    
    private func updateAnimationState() {
        let newState: PlayerAnimationState
        
        if isGrounded {
            if abs(velocityX) > 5.0 {
                newState = .run
            } else {
                newState = .idle
            }
        } else {
            if velocityY > 0.0 {
                newState = .jump
            } else {
                newState = .fall
            }
        }
        
        setAnimation(newState)
    }
    
    /// Switches the running SKAction animation only when the state actually changes.
    public func setAnimation(_ newState: PlayerAnimationState) {
        guard newState != currentAnimationState else { return }
        
        currentAnimationState = newState
        let animKey = "player_anim"
        
        // Remove previous animation action
        self.removeAction(forKey: animKey)
        activeAnimationKey = nil
        
        let def = PlayerAnimations.definition(for: newState)
        let textures = PlayerAnimations.textures(for: newState)
        guard !textures.isEmpty else { return }
        
        let animateAction = SKAction.animate(
            with: textures,
            timePerFrame: def.timePerFrame,
            resize: false,
            restore: false
        )
        
        let action: SKAction
        if def.loops {
            action = SKAction.repeatForever(animateAction)
        } else {
            action = animateAction
        }
        
        self.run(action, withKey: animKey)
        activeAnimationKey = animKey
    }
    
    // MARK: - Health & Damage
    
    /// Whether the player is currently in temporary post-hit invulnerability.
    public private(set) var isInvulnerable: Bool = false
    
    /// Applies damage to the player, triggering hurt response and invulnerability flash.
    public func takeDamage(amount: Int) {
        guard isAlive && !isInvulnerable else { return }
        
        currentHealth = max(0, currentHealth - amount)
        isInvulnerable = true
        
        // Slight knockback velocity impulse
        let knockbackDir: CGFloat = facingDirection == .right ? -1.0 : 1.0
        velocityX = knockbackDir * 160.0
        velocityY = 180.0
        isGrounded = false
        
        // Play hurt animation
        setAnimation(.hurt)
        
        // Flash invulnerability action (1.0 second duration)
        let fadeOut = SKAction.fadeAlpha(to: 0.3, duration: 0.1)
        let fadeIn = SKAction.fadeAlpha(to: 1.0, duration: 0.1)
        let pulse = SKAction.sequence([fadeOut, fadeIn])
        let flashLoop = SKAction.repeat(pulse, count: 5)
        
        let resetInvuln = SKAction.run { [weak self] in
            self?.isInvulnerable = false
            self?.alpha = 1.0
        }
        
        self.run(SKAction.sequence([flashLoop, resetInvuln]), withKey: "player_hurt_flash")
    }
    
    // MARK: - Ground Contact
    
    /// Called by GameScene when the player lands on ground.
    public func onGroundContact() {
        if !isGrounded {
            isGrounded = true
            // Zero out downward velocity on landing
            if velocityY < 0 {
                velocityY = 0.0
            }
        }
    }
    
    /// Called by GameScene when the player leaves ground contact.
    public func onGroundContactEnd() {
        isGrounded = false
    }
    
    // MARK: - Debug Label Update
    
    private func updateDebugLabel() {
        guard let label = debugLabel else { return }
        let grounded = isGrounded ? "GND" : "AIR"
        label.text = String(
            format: "x:%.0f y:%.0f vx:%.0f vy:%.0f %@",
            position.x, position.y, velocityX, velocityY, grounded
        )
    }
}
