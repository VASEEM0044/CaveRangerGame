import SpriteKit

/// Internal activation state machine for the MineExit structure.
public enum MineExitState: String, Sendable {
    case inactive
    case active
    case completing
    case completed
}

/// Animation frame extraction for mine_exit.png (2816×1536, 128×128 frame size).
public enum MineExitAnimations {
    private static let spriteSheet = SpriteSheet(definition: AssetConfig.mineExit)
    
    public static let idleFrames       = spriteSheet.animationFrames(row: 0, startColumn: 0, count: 4)
    public static let activeFrames     = spriteSheet.animationFrames(row: 1, startColumn: 0, count: 4)
    public static let completionFrames = spriteSheet.animationFrames(row: 2, startColumn: 0, count: 4)
    public static let finalFrames      = spriteSheet.animationFrames(row: 3, startColumn: 0, count: 4)
}

/// Mine exit portal / door structure placed at the end of the underground mine.
/// Manages level exit sensor detection, activation sequences, end-of-level animations, and completion event callbacks.
public final class MineExit: SKSpriteNode {
    
    // MARK: - Properties
    
    /// Current internal lifecycle state of the exit.
    public private(set) var currentState: MineExitState = .inactive
    
    /// Callback triggered when the level completion sequence finishes.
    public var onCompletionHandler: (() -> Void)?
    
    private var debugBorderNode: SKShapeNode?
    
    // MARK: - Initialization
    
    public init(position: CGPoint) {
        let initialTexture = MineExitAnimations.idleFrames.first ?? SKTexture()
        let displaySize = CGSize(width: 128.0, height: 128.0)
        
        super.init(texture: initialTexture, color: .clear, size: displaySize)
        
        self.name = "mine_exit"
        self.position = position
        self.zPosition = 5
        
        setupPhysicsBody()
        startIdleAnimation()
    }
    
    public required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) is not supported for MineExit")
    }
    
    // MARK: - Physics Body
    
    private func setupPhysicsBody() {
        let triggerSize = CGSize(width: 48.0, height: 64.0)
        let body = SKPhysicsBody(rectangleOf: triggerSize, center: CGPoint(x: 0, y: -20))
        body.categoryBitMask = PhysicsCategory.exit.rawValue
        body.collisionBitMask = PhysicsCategory.CollisionMasks.nonSolid // Non-solid trigger sensor
        body.contactTestBitMask = PhysicsCategory.player.rawValue
        body.isDynamic = false
        
        self.physicsBody = body
    }
    
    // MARK: - Animations
    
    private func startIdleAnimation() {
        guard !MineExitAnimations.idleFrames.isEmpty else { return }
        let idle = SKAction.animate(with: MineExitAnimations.idleFrames, timePerFrame: 0.15, resize: false, restore: false)
        self.run(SKAction.repeatForever(idle), withKey: "exit_anim")
    }
    
    // MARK: - Trigger & Completion Flow
    
    /// Called when the player contacts the exit portal to initiate level completion.
    public func triggerCompletion(player: PlayerEntity, completionHandler: (() -> Void)? = nil) {
        guard currentState == .inactive else { return }
        
        currentState = .active
        self.physicsBody = nil // Remove sensor to prevent duplicate triggers
        self.removeAction(forKey: "exit_anim")
        
        AudioManager.shared.playSFX(.exitActivate)
        if let parentNode = self.parent {
            VFXManager.createExitActivationBurst(at: position, in: parentNode, particleCount: 12)
        }
        
        if let handler = completionHandler {
            self.onCompletionHandler = handler
        }
        
        // Sequence: ACTIVE -> COMPLETION -> FINAL
        let activeAnim = SKAction.animate(with: MineExitAnimations.activeFrames, timePerFrame: 0.12, resize: false, restore: false)
        let setCompleting = SKAction.run { [weak self] in
            self?.currentState = .completing
        }
        let completionAnim = SKAction.animate(with: MineExitAnimations.completionFrames, timePerFrame: 0.10, resize: false, restore: false)
        let setCompleted = SKAction.run { [weak self] in
            guard let self = self else { return }
            self.currentState = .completed
            AudioManager.shared.playSFX(.levelComplete)
            if let parentNode = self.parent {
                VFXManager.createLevelCompleteBurst(at: self.position, in: parentNode, particleCount: 16)
            }
            self.onCompletionHandler?()
        }
        let finalAnim = SKAction.animate(with: MineExitAnimations.finalFrames, timePerFrame: 0.15, resize: false, restore: false)
        
        let fullSequence = SKAction.sequence([
            activeAnim,
            setCompleting,
            completionAnim,
            setCompleted,
            SKAction.repeatForever(finalAnim)
        ])
        
        self.run(fullSequence, withKey: "exit_completion_sequence")
    }
}
