import SpriteKit

/// Architectural foundation protocol for UI overlays and HUD layers.
/// On-screen buttons, health bars, coin counters, and pause menus will be implemented in subsequent phases.
public protocol UIOverlay: AnyObject {
    /// Container node hosting all HUD and UI elements.
    var containerNode: SKNode { get }
    
    /// Updates the UI display when player metrics change.
    func updateHealth(current: Int, max: Int)
    
    /// Updates the UI display when coin count changes.
    func updateCoins(count: Int)
    
    /// Shows or hides the pause overlay menu.
    func setPauseOverlay(visible: Bool)
}
