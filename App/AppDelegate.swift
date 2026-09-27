import UIKit
import SpriteKit

@main
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?

    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
        // Pure programmatic application setup without Storyboards
        let window = UIWindow(frame: UIScreen.main.bounds)
        window.rootViewController = GameViewController()
        window.makeKeyAndVisible()
        self.window = window
        return true
    }
    
    func applicationWillResignActive(_ application: UIApplication) {
        // Pause active gameplay when the application leaves foreground or is interrupted
        guard let gameViewController = window?.rootViewController as? GameViewController,
              let skView = gameViewController.view as? SKView,
              let scene = skView.scene as? GameScene else { return }
        
        if scene.gameStateManager.currentState == .playing {
            scene.gameStateManager.transition(to: .paused)
        }
    }
}
