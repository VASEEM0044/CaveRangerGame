import SpriteKit

/// Dedicated camera node for managing the viewport, tracking targets, and clamping world boundaries.
public class GameCamera: SKCameraNode {
    
    /// Optional bounding rectangle in world coordinates to confine camera movement.
    public var levelBounds: CGRect?
    
    /// Viewport size rendered through this camera (defaults to logical resolution).
    public var viewportSize: CGSize = GameConfig.Display.logicalSize
    
    /// Damping factor for smooth following (0.0 = instantaneous snap, 0.9 = heavy lag).
    public var smoothFactor: CGFloat = 0.1
    
    public override init() {
        super.init()
        self.name = "game_camera"
    }
    
    public required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        self.name = "game_camera"
    }
    
    /// Instantly positions the camera at the given world point, clamped to level bounds.
    public func snap(to targetPosition: CGPoint) {
        self.position = clampedPosition(for: targetPosition)
    }
    
    /// Smoothly interpolates the camera towards targetPosition based on smoothFactor.
    public func update(towards targetPosition: CGPoint) {
        let destination = clampedPosition(for: targetPosition)
        let lerpFactor = max(0.0, min(1.0, 1.0 - smoothFactor))
        let dx = (destination.x - self.position.x) * lerpFactor
        let dy = (destination.y - self.position.y) * lerpFactor
        self.position = CGPoint(x: self.position.x + dx, y: self.position.y + dy)
    }
    
    /// Clamps candidate camera coordinates inside levelBounds if configured.
    public func clampedPosition(for point: CGPoint) -> CGPoint {
        guard let bounds = levelBounds else { return point }
        
        let halfWidth = (viewportSize.width * xScale) / 2.0
        let halfHeight = (viewportSize.height * yScale) / 2.0
        
        let minX = bounds.minX + halfWidth
        let maxX = bounds.maxX - halfWidth
        let minY = bounds.minY + halfHeight
        let maxY = bounds.maxY - halfHeight
        
        let clampedX: CGFloat
        if minX > maxX {
            clampedX = bounds.midX
        } else {
            clampedX = max(minX, min(point.x, maxX))
        }
        
        let clampedY: CGFloat
        if minY > maxY {
            clampedY = bounds.midY
        } else {
            clampedY = max(minY, min(point.y, maxY))
        }
        
        return CGPoint(x: clampedX, y: clampedY)
    }
    
    /// Configures the camera zoom factor (1.0 = standard 1:1 scale, 2.0 = 2x zoomed in).
    public func setZoom(_ zoom: CGFloat) {
        guard zoom > 0 else { return }
        let scale = 1.0 / zoom
        self.setScale(scale)
    }
}
