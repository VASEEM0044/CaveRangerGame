import UIKit
import SpriteKit

/// Primary view controller presenting the SpriteKit GameScene.
public class GameViewController: UIViewController {

    public override func loadView() {
        self.view = SKView(frame: UIScreen.main.bounds)
    }

    public override func viewDidLoad() {
        super.viewDidLoad()
        
        guard let skView = self.view as? SKView else { return }
        
        // Optimize rendering performance
        skView.ignoresSiblingOrder = true
        
        // Debug metrics configured via GameConfig
        skView.showsFPS = GameConfig.Debug.showFPS
        skView.showsNodeCount = GameConfig.Debug.showNodeCount
        skView.showsPhysics = GameConfig.Debug.showPhysicsOutlines
        
        // Present initial GameScene
        let scene = GameScene()
        scene.scaleMode = .aspectFit
        skView.presentScene(scene)
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
