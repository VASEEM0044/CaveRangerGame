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
    
    // MARK: - Player Movement & Physics
    public enum Player {
        /// Maximum horizontal movement speed in points per second.
        public static let movementSpeed: CGFloat = 120.0
        
        /// Horizontal acceleration rate in points per second².
        public static let acceleration: CGFloat = 800.0
        
        /// Horizontal deceleration (friction) rate in points per second².
        public static let deceleration: CGFloat = 1200.0
        
        /// Upward impulse force applied when the player jumps.
        public static let jumpForce: CGFloat = 420.0
        
        /// Custom gravity acceleration applied to the player in points per second².
        public static let gravity: CGFloat = 980.0
        
        /// Maximum downward velocity clamp (terminal velocity).
        public static let maxFallSpeed: CGFloat = 500.0
        
        /// Default spawn position for the player in the test scene.
        public static let spawnPosition: CGPoint = CGPoint(x: 320.0, y: 200.0)
        
        /// Render scale multiplier applied to the 128×128 sprite frame for on-screen display.
        /// A value of 0.5 renders the character at roughly 64×64 points.
        public static let renderScale: CGFloat = 0.5
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
        
        /// Toggle player debug overlay (position readout, grounded state).
        public static let showPlayerDebug: Bool = false
    }
}
