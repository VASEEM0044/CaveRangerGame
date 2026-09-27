import SpriteKit

/// Ladder node representing a climbable vertical shaft connecting cavern tiers.
/// Extracted from `cave_props_and_enemies.png`.
public final class Ladder: SKSpriteNode {
    
    // MARK: - Properties
    
    /// Ladder frame texture extracted from the top row of `cave_props_and_enemies.png`.
    public static var ladderTexture: SKTexture {
        // Ladder bounding box: (434, 0, 221, 384) in 2816×1536 sheet
        let pixelRect = CGRect(x: 434, y: 0, width: 221, height: 384)
        return TextureCache.shared.croppedTexture(from: "cave_props_and_enemies.png", pixelRect: pixelRect)
    }
    
    /// Bounding rectangle in world coordinates for player climbing overlap.
    public var climbBounds: CGRect {
        return CGRect(
            x: position.x - size.width * 0.5,
            y: position.y - size.height * 0.5,
            width: size.width,
            height: size.height
        )
    }
    
    // MARK: - Initialization
    
    public init(position: CGPoint, height: CGFloat = 160.0) {
        let tex = Ladder.ladderTexture
        let ladderWidth: CGFloat = 36.0
        let displaySize = CGSize(width: ladderWidth, height: height)
        
        super.init(texture: tex, color: .clear, size: displaySize)
        
        self.name = "ladder"
        self.position = position
        self.zPosition = 4 // In front of background, behind player
    }
    
    public required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) is not supported for Ladder")
    }
}
