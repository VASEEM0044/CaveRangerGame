import UIKit
import SpriteKit

/// Primary view controller presenting the SpriteKit GameScene.
public class GameViewController: UIViewController {

    public override func loadView() {
        CrashLogger.shared.logSync("GameViewController loadView started")
        self.view = SKView(frame: UIScreen.main.bounds)
        CrashLogger.shared.logSync("GameViewController loadView SKView created")
    }

    public override func viewDidLoad() {
        super.viewDidLoad()
        CrashLogger.shared.logSync("GameViewController viewDidLoad started")
        
        guard let skView = self.view as? SKView else {
            CrashLogger.shared.logSync("ERROR: self.view is not SKView")
            return
        }
        
        // Optimize rendering performance
        skView.ignoresSiblingOrder = true
        skView.isMultipleTouchEnabled = true
        
        // Debug metrics configured via GameConfig
        skView.showsFPS = GameConfig.Debug.showFPS
        skView.showsNodeCount = GameConfig.Debug.showNodeCount
        skView.showsPhysics = GameConfig.Debug.showPhysicsOutlines
        
        // Present initial GameScene with fixed logical 16:9 canvas
        CrashLogger.shared.logSync("Creating GameScene with size \(GameConfig.Display.logicalSize)")
        let scene = GameScene(size: GameConfig.Display.logicalSize)
        scene.scaleMode = .aspectFit
        CrashLogger.shared.logSync("Presenting GameScene in SKView...")
        skView.presentScene(scene)
        CrashLogger.shared.logSync("GameScene presented successfully in SKView")
    }

    public override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        guard let skView = self.view as? SKView,
              let gameScene = skView.scene as? GameScene else { return }
        gameScene.updateSafeAreaInsets(skView.safeAreaInsets)
    }

    // MARK: - Screen Orientation & Status Bar
    
    public override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        // Platformer experience locked to landscape
        return .landscape
    }

    public override var prefersStatusBarHidden: Bool {
        return true
    }

    public override var prefersHomeIndicatorAutoHidden: Bool {
        return true
    }
}
