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
    
    /// Mine environment container managing terrain visual artwork and collision geometry.
    public private(set) var mineLevel: MineLevel!
    
    /// Current level statistics tracker.
    public let levelStats = LevelStats()
    
    // MARK: - Player Components
    
    /// The playable cowboy character.
    public private(set) var player: Player!
    
    /// Keyboard input controller feeding movement commands to the player.
    public private(set) var playerController: PlayerController!
    
    /// On-screen touch controls (joystick, jump, whip, shoot, reload) for iOS devices.
    public private(set) var touchControls: TouchControls!
    
    /// On-screen HUD displaying health, ammo, coins, timer, and modal menus.
    public private(set) var gameHUD: GameHUD!
    
    /// Tracked active flying bullets in the scene.
    private var activeBullets: [Bullet] = []
    
    // MARK: - Timing Properties
    
    private var lastUpdateTime: TimeInterval = 0
    
    /// Accumulated active gameplay duration in seconds.
    public private(set) var levelElapsedTime: TimeInterval = 0.0
    
    // MARK: - Scene Lifecycle
    
    public override func didMove(to view: SKView) {
        setupSceneProperties()
        setupPhysicsWorld()
        setupPlayerController()
        setupLevel()
        setupCamera()
        setupPlayer()
        setupTouchControls()
        setupHUD()
        
        gameStateManager.delegate = self
        
        // Smooth level start fade-in
        self.alpha = 0.0
        self.run(SKAction.fadeIn(withDuration: 0.25))
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
        
        levelStats.setTotalCoins(mineLevel.coins.count)
        for coin in mineLevel.coins {
            coin.onCollectedHandler = { [weak self] c in
                self?.levelStats.recordCoinCollected(value: c.value)
            }
        }
        
        mineLevel.mineExit.onCompletionHandler = { [weak self] in
            self?.handleLevelCompletion()
        }
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
    
    private func setupTouchControls() {
        touchControls = TouchControls(controller: playerController)
        gameCamera.addChild(touchControls)
    }
    
    private func setupHUD() {
        gameHUD = GameHUD(viewportSize: self.size)
        gameCamera.addChild(gameHUD)
        
        // Initial HUD values
        gameHUD.updateHealth(current: player.currentHealth, max: player.maxHealth)
        gameHUD.updateCoins(collected: levelStats.coinsCollected, total: levelStats.totalCoins)
        gameHUD.updateAmmo(current: player.revolver.currentAmmo, max: player.revolver.magazineSize, isReloading: player.revolver.isReloading)
        gameHUD.updateTimer(elapsedTime: levelElapsedTime)
        
        // Wire HUD Callbacks
        gameHUD.onPausePressed = { [weak self] in
            guard self?.gameStateManager.currentState == .playing else { return }
            self?.gameStateManager.transition(to: .paused)
        }
        
        gameHUD.onResumePressed = { [weak self] in
            guard self?.gameStateManager.currentState == .paused else { return }
            self?.gameStateManager.transition(to: .playing)
        }
        
        gameHUD.onRestartPressed = { [weak self] in
            self?.restartLevel()
        }
    }
    
    // MARK: - Frame Update Loop
    
    public override func update(_ currentTime: TimeInterval) {
        if lastUpdateTime == 0 {
            lastUpdateTime = currentTime
        }
        let deltaTime = currentTime - lastUpdateTime
        lastUpdateTime = currentTime
        
        guard gameStateManager.currentState == .playing else { return }
        
        // Accumulate active gameplay timer
        levelElapsedTime += deltaTime
        
        // Update HUD Metrics
        gameHUD.updateTimer(elapsedTime: levelElapsedTime)
        gameHUD.updateHealth(current: player.currentHealth, max: player.maxHealth)
        gameHUD.updateCoins(collected: levelStats.coinsCollected, total: levelStats.totalCoins)
        gameHUD.updateAmmo(current: player.revolver.currentAmmo, max: player.revolver.magazineSize, isReloading: player.revolver.isReloading)
        
        // Check for player defeat
        if player.currentHealth <= 0 {
            gameStateManager.transition(to: .playerDead)
            return
        }
        
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
        
        // Handle revolver fire input (K key)
        if playerController.fireRequested {
            if let bullet = player.fireRevolver(parentScene: self) {
                activeBullets.append(bullet)
                gameCamera.shake(intensity: 2.0, duration: 0.06)
            }
        }
        
        // Handle revolver reload input (R key)
        if playerController.reloadRequested {
            player.reloadRevolver()
        }
        
        // Handle revolver aiming input (L key)
        player.setAiming(playerController.isAiming)
        
        // Update flying bullets and purge removed ones
        activeBullets.removeAll { $0.parent == nil }
        for bullet in activeBullets {
            bullet.update(deltaTime: deltaTime)
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
                gameCamera.shake(intensity: 3.5, duration: 0.10)
            }
        }
        
        // Player ↔ Collectible contact
        if bodyA.categoryBitMask == PhysicsCategory.player.rawValue &&
           bodyB.categoryBitMask == PhysicsCategory.collectible.rawValue {
            if let collectible = bodyB.node as? CollectibleEntity {
                collectible.onCollect(by: player)
            }
        }
        
        // Player ↔ Exit contact
        if bodyA.categoryBitMask == PhysicsCategory.player.rawValue &&
           bodyB.categoryBitMask == PhysicsCategory.exit.rawValue {
            mineLevel.mineExit.triggerCompletion(player: player)
            gameCamera.shake(intensity: 2.0, duration: 0.12)
        }
        
        // Bullet ↔ Enemy contact
        if bodyA.categoryBitMask == PhysicsCategory.enemy.rawValue &&
           bodyB.categoryBitMask == PhysicsCategory.projectile.rawValue {
            if let enemy = bodyA.node as? EnemyEntity, let bullet = bodyB.node as? Bullet {
                enemy.takeDamage(amount: bullet.damage)
                bullet.destroySelf(showImpact: true)
                gameCamera.shake(intensity: 1.5, duration: 0.05)
            }
        }
        
        // Bullet ↔ Ground contact
        if bodyA.categoryBitMask == PhysicsCategory.ground.rawValue &&
           bodyB.categoryBitMask == PhysicsCategory.projectile.rawValue {
            if let bullet = bodyB.node as? Bullet {
                bullet.destroySelf(showImpact: true)
            }
        }
    }
    
    // MARK: - Level Completion Coordination
    
    /// Current level identifier.
    public let currentLevelID: String = "mine_01"
    
    /// Cached completion result for level complete modal display.
    private var lastCompletionResult: SaveManager.LevelCompletionResult?
    
    /// Handles transitioning the game state and stats when the level exit sequence finishes.
    private func handleLevelCompletion() {
        guard gameStateManager.currentState == .playing else { return }
        
        // Record completion statistics in LevelStats (Current run)
        levelStats.markCompleted(elapsedTime: levelElapsedTime)
        
        // Persist completion and best records via SaveManager
        let result = SaveManager.shared.markLevelCompleted(
            levelID: currentLevelID,
            coins: levelStats.coinsCollected,
            time: levelElapsedTime
        )
        self.lastCompletionResult = result
        
        // Transition game state machine to LEVEL_COMPLETE
        gameStateManager.transition(to: .levelComplete)
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
    
    // MARK: - Touch Input (iOS Multi-Touch)
    
    public override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        // Priority 1: Check if HUD consumes touches (Pause button or modal overlays)
        if gameHUD != nil && gameHUD.handleTouchesBegan(touches, in: self) {
            return
        }
        
        // Priority 2: Forward to TouchControls during active gameplay
        guard gameStateManager.currentState == .playing else { return }
        touchControls?.handleTouchesBegan(touches, in: self)
    }
    
    public override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard gameStateManager.currentState == .playing else { return }
        touchControls?.handleTouchesMoved(touches, in: self)
    }
    
    public override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        // Check if HUD modal overlays or pause button handled touch end
        if gameHUD != nil && gameHUD.handleTouchesEnded(touches, in: self) {
            return
        }
        touchControls?.handleTouchesEnded(touches, in: self)
    }
    
    public override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        touchControls?.handleTouchesCancelled(touches, in: self)
    }
    
    /// Updates the touch control and HUD layout with iOS device safe-area insets.
    public func updateSafeAreaInsets(_ insets: UIEdgeInsets) {
        touchControls?.updateLayout(viewportSize: self.size, safeAreaInsets: insets)
        gameHUD?.updateLayout(viewportSize: self.size, safeAreaInsets: insets)
    }
    
    // MARK: - Keyboard Input (macOS Catalyst / Simulator)
    
    #if targetEnvironment(macCatalyst) || os(macOS)
    public override func keyDown(with event: NSEvent) {
        guard !event.isARepeat else { return }
        // ESC key (53) toggles pause
        if event.keyCode == 53 {
            if gameStateManager.currentState == .playing {
                gameStateManager.transition(to: .paused)
            } else if gameStateManager.currentState == .paused {
                gameStateManager.transition(to: .playing)
            }
            return
        }
        playerController.keyDown(keyCode: event.keyCode)
    }
    
    public override func keyUp(with event: NSEvent) {
        playerController.keyUp(keyCode: event.keyCode)
    }
    #endif
    
    // MARK: - Level Restart
    
    /// Resets the current level, player, enemies, collectibles, timer, and HUD for fresh playthrough.
    public func restartLevel() {
        // 1. Remove bullets
        for bullet in activeBullets {
            bullet.removeFromParent()
        }
        activeBullets.removeAll()
        
        // 2. Remove old mineLevel and recreate
        mineLevel?.levelNode.removeFromParent()
        mineLevel = MineLevel()
        addChild(mineLevel.levelNode)
        
        // Bind coins and exit
        levelStats.reset()
        levelStats.setTotalCoins(mineLevel.coins.count)
        for coin in mineLevel.coins {
            coin.onCollectedHandler = { [weak self] c in
                self?.levelStats.recordCoinCollected(value: c.value)
                self?.gameHUD?.updateCoins(collected: self?.levelStats.coinsCollected ?? 0, total: self?.levelStats.totalCoins ?? 0)
            }
        }
        
        mineLevel.mineExit.onCompletionHandler = { [weak self] in
            self?.handleLevelCompletion()
        }
        
        // 3. Remove old player and recreate
        player?.removeFromParent()
        player = Player()
        player.position = MineLevel.spawnPosition
        addChild(player)
        
        // 4. Snap camera to player
        gameCamera.snap(to: player.position)
        
        // 5. Reset touch controls and controller
        playerController = PlayerController()
        touchControls?.removeFromParent()
        touchControls = TouchControls(controller: playerController)
        gameCamera.addChild(touchControls)
        
        // 6. Reset timer
        levelElapsedTime = 0.0
        lastUpdateTime = 0.0
        
        // 7. Reset HUD
        gameHUD?.updateHealth(current: player.currentHealth, max: player.maxHealth)
        gameHUD?.updateCoins(collected: 0, total: levelStats.totalCoins)
        gameHUD?.updateAmmo(current: player.revolver.currentAmmo, max: player.revolver.magazineSize, isReloading: false)
        gameHUD?.updateTimer(elapsedTime: 0.0)
        gameHUD?.hideAllOverlays()
        
        // 8. Transition state to playing
        gameStateManager.transition(to: .playing)
    }
    
    // MARK: - GameStateDelegate
    
    public func gameStateDidChange(from oldState: GameState, to newState: GameState) {
        switch newState {
        case .playing:
            self.isPaused = false
            AudioManager.shared.resumeAllSFX()
            touchControls?.setControlsActive(true)
            gameHUD?.hideAllOverlays()
        case .paused:
            self.isPaused = true
            AudioManager.shared.pauseAllSFX()
            touchControls?.setControlsActive(false)
            gameHUD?.setPauseOverlay(visible: true)
        case .levelComplete:
            self.isPaused = false
            touchControls?.setControlsActive(false)
            let bCoins = lastCompletionResult?.currentBestCoins ?? SaveManager.shared.bestCoins(for: currentLevelID) ?? levelStats.coinsCollected
            let bTime = lastCompletionResult?.currentBestTime ?? SaveManager.shared.bestTime(for: currentLevelID) ?? levelElapsedTime
            let isNewCoins = lastCompletionResult?.isNewBestCoins ?? false
            let isNewTime = lastCompletionResult?.isNewBestTime ?? false
            
            gameHUD?.showLevelCompleteOverlay(
                coinsCollected: levelStats.coinsCollected,
                totalCoins: levelStats.totalCoins,
                elapsedTime: levelElapsedTime,
                bestCoins: bCoins,
                bestTime: bTime,
                isNewBestCoins: isNewCoins,
                isNewBestTime: isNewTime
            )
        case .playerDead:
            self.isPaused = false
            touchControls?.setControlsActive(false)
            gameHUD?.showGameOverOverlay()
        }
    }
}
