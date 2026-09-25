import SpriteKit

/// Primary SpriteKit scene hosting the platformer world, physics simulation, camera, and state manager.
///
/// Phase 3 additions:
/// - Underground mine level environment (`MineLevel`)
/// - Replaced test platform with structured mine terrain and one-way platform mechanics
/// - Camera clamping to level bounds (no out-of-bounds rendering)
/// - Fall / death boundary reset to spawn position
public class GameScene: SKScene, SKPhysicsContactDelegate, GameStateDelegate {
    
    // MARK: - Core Components
    
    /// High-level game state manager.
    public let gameStateManager = GameStateManager(initialState: .playing)
    
    /// Dedicated game camera.
    public let gameCamera = GameCamera()
    
    // MARK: - Level Components
    
    /// Mine environment container managing terrain visual artwork and collision geometry.
    public private(set) var mineLevel: MineLevel!
    
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
        setupLevel()
        setupCamera()
        setupPlayer()
        setupPlayerController()
        
        gameStateManager.delegate = self
    }
    
    // MARK: - Scene Initialization
    
    private func setupSceneProperties() {
        self.size = GameConfig.Display.logicalSize
        self.scaleMode = .aspectFit
        // Dark retro cave ambiance background color
        self.backgroundColor = MineTileset.caveDark
    }
    
    private func setupPhysicsWorld() {
        physicsWorld.gravity = GameConfig.Physics.gravity
        physicsWorld.contactDelegate = self
    }
    
    private func setupLevel() {
        mineLevel = MineLevel()
        addChild(mineLevel.levelNode)
    }
    
    private func setupCamera() {
        gameCamera.viewportSize = self.size
        gameCamera.levelBounds = CGRect(
            x: 0,
            y: 0,
            width: MineLevel.worldWidth,
            height: MineLevel.worldHeight
        )
        addChild(gameCamera)
        self.camera = gameCamera
    }
    
    // MARK: - Player Setup
    
    private func setupPlayer() {
        player = Player()
        player.position = MineLevel.spawnPosition
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
        
        // Handle whip attack input (J or X key)
        if playerController.attackRequested {
            player.performWhipAttack(enemies: mineLevel.snakes, parentScene: self)
        }
        
        // Update all active snake enemies in the level
        for snake in mineLevel.snakes {
            snake.update(deltaTime: deltaTime, currentTime: currentTime, player: player)
        }
        
        // Safety check for level boundaries & death pit fall
        checkLevelBoundaries()
        
        // Camera follows the player with smooth interpolation inside bounds
        gameCamera.update(towards: player.position)
    }
    
    /// Handles falling out of bounds: resets player to spawn location.
    private func checkLevelBoundaries() {
        if player.position.y < MineLevel.deathY {
            // Reset player to starting spawn position
            player.position = MineLevel.spawnPosition
            player.velocityX = 0.0
            player.velocityY = 0.0
            player.isGrounded = false
            gameCamera.snap(to: player.position)
        }
        
        // Clamp player X to world boundaries
        let playerHalfW = player.size.width * 0.2
        if player.position.x < playerHalfW {
            player.position.x = playerHalfW
            player.velocityX = max(0, player.velocityX)
        } else if player.position.x > MineLevel.worldWidth - playerHalfW {
            player.position.x = MineLevel.worldWidth - playerHalfW
            player.velocityX = min(0, player.velocityX)
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
        
        // Player ↔ Enemy contact
        if bodyA.categoryBitMask == PhysicsCategory.player.rawValue &&
           bodyB.categoryBitMask == PhysicsCategory.enemy.rawValue {
            if let snake = bodyB.node as? SnakeEnemy, snake.isAlive {
                player.takeDamage(amount: snake.damage)
            }
        }
    }
    
    public func didEnd(_ contact: SKPhysicsContact) {
        let (bodyA, bodyB) = sortedBodies(contact)
        
        // Player ↔ Ground separation
        if bodyA.categoryBitMask == PhysicsCategory.player.rawValue &&
           bodyB.categoryBitMask == PhysicsCategory.ground.rawValue {
            player.onGroundContactEnd()
        }
    }
    
    /// Determines landing: the player must be contacting ground/platform from above.
    private func handlePlayerGroundContact(playerBody: SKPhysicsBody,
                                           groundBody: SKPhysicsBody,
                                           contact: SKPhysicsContact) {
        let normal = contact.contactNormal
        
        // Contact normal points from A to B. If player (A) is landing on ground (B),
        // the normal Y component is negative.
        if normal.dy < -0.3 {
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
