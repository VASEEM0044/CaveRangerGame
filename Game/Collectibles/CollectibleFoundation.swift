import SpriteKit

/// Identifies categories of collectible items.
public enum CollectibleType: Sendable {
    case coin
}

/// Architectural foundation protocol for items collected in the cave.
/// Pickup animations, score bonuses, and audio hooks will be implemented in subsequent phases.
public protocol CollectibleEntity: AnyObject {
    /// SpriteKit node representing the collectible item.
    var node: SKNode { get }
    
    /// Type classification of the collectible.
    var collectibleType: CollectibleType { get }
    
    /// Point or coin value awarded upon collection.
    var scoreValue: Int { get }
    
    /// Triggered when the player collects this item.
    func onCollect(by player: PlayerEntity)
}
