import SpriteKit

/// Primary SpriteKit scene hosting the platformer world, physics simulation, camera, and state manager.
///
/// Phase 2 additions:
/// - Player character instantiation and per-frame update
/// - Keyboard input via PlayerController
/// - Temporary test ground platform for movement/jump testing
/// - Camera follow tracking
/// - Physics contact handling for ground detection
public class GameScene: SKScene, SKPhysicsContactDelegate, GameStateDelegate {
    
    // MARK: - Core Components
    
    /// High-level game state manager.
    public let gameStateManager = GameStateManager(initialState: .playing)
    
    /// Dedicated game camera.
    public let gameCamera = GameCamera()
    
    // MARK: - Player Components
    
    /// The playable cowboy character.
    public private(set) var player: Player!
    
    /// Keyboard input controller feeding movement commands to the player.
    public private(set) var playerController: PlayerController!
    
    // MARK: - Timing Properties
    
    private var lastUpdateTime: TimeInterval = 0
    
    // MARK: - Scene Lifecycle
    
    public override func didMove(to view: SKView) {
        setupSceneProperties()
        setupPhysicsWorld()
        setupCamera()
        setupTestGround()
        setupPlayer()
        setupPlayerController()
        
        gameStateManager.delegate = self
    }
    
    // MARK: - Scene Initialization
    
    private func setupSceneProperties() {
        self.size = GameConfig.Display.logicalSize
        self.scaleMode = .aspectFit
        // Dark retro cave ambiance background color
        self.backgroundColor = SKColor(red: 0.08, green: 0.06, blue: 0.10, alpha: 1.0)
    }
    
    private func setupPhysicsWorld() {
        physicsWorld.gravity = GameConfig.Physics.gravity
        physicsWorld.contactDelegate = self
    }
    
    private func setupCamera() {
        gameCamera.viewportSize = self.size
        addChild(gameCamera)
        self.camera = gameCamera
    }
    
    // MARK: - Test Ground (Temporary Development Platform)
    
    /// Creates a simple flat platform for testing player movement and collision.
    /// This will be replaced by the tilemap-based level system in a later phase.
    private func setupTestGround() {
        let groundWidth: CGFloat = 1200.0
        let groundHeight: CGFloat = 24.0
        let groundY: CGFloat = 60.0
        
        let ground = SKSpriteNode(color: SKColor(red: 0.25, green: 0.18, blue: 0.12, alpha: 1.0),
                                  size: CGSize(width: groundWidth, height: groundHeight))
        ground.position = CGPoint(x: groundWidth / 2.0, y: groundY)
        ground.name = "test_ground"
        ground.zPosition = 1
        
        let body = SKPhysicsBody(rectangleOf: ground.size)
        body.isDynamic = false
        body.categoryBitMask = PhysicsCategory.ground.rawValue
        body.collisionBitMask = PhysicsCategory.player.rawValue | PhysicsCategory.enemy.rawValue
        body.contactTestBitMask = PhysicsCategory.player.rawValue
        body.friction = 0.0
        body.restitution = 0.0
        ground.physicsBody = body
        
        addChild(ground)
        
        // Small platform to the right for jump testing
        let platformWidth: CGFloat = 160.0
        let platformHeight: CGFloat = 16.0
        let platform = SKSpriteNode(color: SKColor(red: 0.30, green: 0.22, blue: 0.15, alpha: 1.0),
                                    size: CGSize(width: platformWidth, height: platformHeight))
        platform.position = CGPoint(x: 800.0, y: groundY + 70.0)
        platform.name = "test_platform"
        platform.zPosition = 1
        
        let platBody = SKPhysicsBody(rectangleOf: platform.size)
        platBody.isDynamic = false
        platBody.categoryBitMask = PhysicsCategory.ground.rawValue
        platBody.collisionBitMask = PhysicsCategory.player.rawValue
        platBody.contactTestBitMask = PhysicsCategory.player.rawValue
        platBody.friction = 0.0
        platBody.restitution = 0.0
        platform.physicsBody = platBody
        
        addChild(platform)
    }
    
    // MARK: - Player Setup
    
    private func setupPlayer() {
        player = Player()
        player.position = GameConfig.Player.spawnPosition
        addChild(player)
        
        // Snap camera immediately to player start
        gameCamera.snap(to: player.position)
    }
    
    private func setupPlayerController() {
        playerController = PlayerController()
    }
    
    // MARK: - Frame Update Loop
    
    public override func update(_ currentTime: TimeInterval) {
        if lastUpdateTime == 0 {
            lastUpdateTime = currentTime
        }
        let deltaTime = currentTime - lastUpdateTime
        lastUpdateTime = currentTime
        
        guard gameStateManager.currentState == .playing else { return }
        
        // Feed input into the player and run its update cycle
        player.update(
            deltaTime: deltaTime,
            inputDirection: playerController.inputDirection,
            jumpRequested: playerController.jumpRequested
        )
        
        // Prevent falling through the world floor
        clampPlayerToWorldBounds()
        
        // Camera follows the player with smooth interpolation
        gameCamera.update(towards: player.position)
    }
    
    /// Safety clamp: if the player falls below the visible world, reset to ground level.
    private func clampPlayerToWorldBounds() {
        let floorY: CGFloat = 72.0 + player.size.height / 2.0  // ground top + half sprite
        if player.position.y < floorY {
            player.position.y = floorY
            player.onGroundContact()
        }
    }
    
    // MARK: - SKPhysicsContactDelegate
    
    public func didBegin(_ contact: SKPhysicsContact) {
        let (bodyA, bodyB) = sortedBodies(contact)
        
        // Player ↔ Ground contact
        if bodyA.categoryBitMask == PhysicsCategory.player.rawValue &&
           bodyB.categoryBitMask == PhysicsCategory.ground.rawValue {
            handlePlayerGroundContact(playerBody: bodyA, groundBody: bodyB, contact: contact)
        }
    }
    
    public func didEnd(_ contact: SKPhysicsContact) {
        let (bodyA, bodyB) = sortedBodies(contact)
        
        // Player ↔ Ground separation
        if bodyA.categoryBitMask == PhysicsCategory.player.rawValue &&
           bodyB.categoryBitMask == PhysicsCategory.ground.rawValue {
            // Only mark as airborne if the player is moving upward or not on any ground
            player.onGroundContactEnd()
        }
    }
    
    /// Determines landing: the player must be contacting the ground from above.
    private func handlePlayerGroundContact(playerBody: SKPhysicsBody,
                                           groundBody: SKPhysicsBody,
                                           contact: SKPhysicsContact) {
        // Contact normal points from A to B. If player (A) is above ground (B),
        // the normal's Y component will be negative (pointing downward from player to ground).
        let normal = contact.contactNormal
        
        // The player is landing on top if the contact normal has a significant downward Y component
        // (meaning the ground surface is below the player).
        if normal.dy < -0.5 {
            player.onGroundContact()
        }
    }
    
    /// Returns physics bodies sorted by category bitmask (lower first) for consistent handling.
    private func sortedBodies(_ contact: SKPhysicsContact) -> (SKPhysicsBody, SKPhysicsBody) {
        if contact.bodyA.categoryBitMask <= contact.bodyB.categoryBitMask {
            return (contact.bodyA, contact.bodyB)
        } else {
            return (contact.bodyB, contact.bodyA)
        }
    }
    
    // MARK: - Keyboard Input (macOS Catalyst / Simulator)
    
    #if targetEnvironment(macCatalyst) || os(macOS)
    public override func keyDown(with event: NSEvent) {
        guard !event.isARepeat else { return }
        playerController.keyDown(keyCode: event.keyCode)
    }
    
    public override func keyUp(with event: NSEvent) {
        playerController.keyUp(keyCode: event.keyCode)
    }
    #endif
    
    // MARK: - GameStateDelegate
    
    public func gameStateDidChange(from oldState: GameState, to newState: GameState) {
        switch newState {
        case .playing:
            self.isPaused = false
        case .paused:
            self.isPaused = true
        case .levelComplete:
            self.isPaused = false
        case .playerDead:
            self.isPaused = false
        }
    }
}
