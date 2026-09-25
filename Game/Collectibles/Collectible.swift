import SpriteKit

/// Base implementation class for collectible items in the cave.
open class Collectible: SKSpriteNode, CollectibleEntity {
    
    // MARK: - CollectibleEntity Conformance
    
    public var node: SKNode { self }
    public var collectibleType: CollectibleType { .coin }
    public var scoreValue: Int { 1 }
    
    /// Indicates whether this item has already been collected.
    public private(set) var isCollected: Bool = false
    
    public init(texture: SKTexture?, color: SKColor, size: CGSize) {
        super.init(texture: texture, color: color, size: size)
    }
    
    public required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    /// Called when the player contacts the collectible item.
    open func onCollect(by player: PlayerEntity) {
        guard !isCollected else { return }
        isCollected = true
    }
}
