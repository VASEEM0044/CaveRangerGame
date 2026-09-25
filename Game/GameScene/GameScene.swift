import SpriteKit

/// Primary SpriteKit scene hosting the platformer world, physics simulation, camera, and state manager.
public class GameScene: SKScene, SKPhysicsContactDelegate, GameStateDelegate {
    
    // MARK: - Core Components
    
    /// High-level game state manager.
    public let gameStateManager = GameStateManager(initialState: .playing)
    
    /// Dedicated game camera.
    public let gameCamera = GameCamera()
    
    // MARK: - Timing Properties
    
    private var lastUpdateTime: TimeInterval = 0
    
    // MARK: - Scene Lifecycle
    
    public override func didMove(to view: SKView) {
        setupSceneProperties()
        setupPhysicsWorld()
        setupCamera()
        
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
        gameCamera.position = CGPoint(x: size.width / 2.0, y: size.height / 2.0)
        addChild(gameCamera)
        self.camera = gameCamera
    }
    
    // MARK: - Frame Update Loop
    
    public override func update(_ currentTime: TimeInterval) {
        if lastUpdateTime == 0 {
            lastUpdateTime = currentTime
        }
        let deltaTime = currentTime - lastUpdateTime
        lastUpdateTime = currentTime
        
        guard gameStateManager.currentState == .playing else { return }
        
        // Foundation frame update loop — entity systems will be hooked here in upcoming phases.
        _ = deltaTime
    }
    
    // MARK: - SKPhysicsContactDelegate
    
    public func didBegin(_ contact: SKPhysicsContact) {
        // Foundation contact callback — collision dispatching will be handled in upcoming phases.
    }
    
    public func didEnd(_ contact: SKPhysicsContact) {
        // Foundation contact resolution callback.
    }
    
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
