import Foundation
import CoreGraphics

/// Central configuration for game-wide settings, display dimensions, physics parameters, and debug flags.
public enum GameConfig {
    
    // MARK: - Display & Resolution
    public enum Display {
        /// Base logical resolution width for 2D retro pixel-art rendering.
        public static let logicalWidth: CGFloat = 640.0
        
        /// Base logical resolution height for 2D retro pixel-art rendering (16:9 aspect ratio).
        public static let logicalHeight: CGFloat = 360.0
        
        /// Logical canvas size used for scene presentation.
        public static var logicalSize: CGSize {
            CGSize(width: logicalWidth, height: logicalHeight)
        }
        
        /// Target frame rate for the game loop.
        public static let targetFrameRate: Int = 60
    }
    
    // MARK: - World Physics
    public enum Physics {
        /// World gravity vector (downward acceleration in SpriteKit points/second^2).
        public static let gravity: CGVector = CGVector(dx: 0.0, dy: -18.0)
        
        /// Global pixel-to-meter ratio approximation.
        public static let pointsPerMeter: CGFloat = 32.0
    }
    
    // MARK: - Debug Settings
    public enum Debug {
        /// Toggle physics collision and contact outline display on SKView.
        public static let showPhysicsOutlines: Bool = false
        
        /// Toggle FPS counter display on SKView.
        public static let showFPS: Bool = true
        
        /// Toggle node count display on SKView.
        public static let showNodeCount: Bool = true
        
        /// Toggle quad count display on SKView.
        public static let showQuadCount: Bool = false
    }
}
