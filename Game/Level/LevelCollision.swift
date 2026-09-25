import SpriteKit

/// Describes a single collision segment in the mine level.
/// Collision geometry is kept separate from visual tiles for performance.
public struct CollisionRect: Sendable {
    /// World position of the collision rectangle's center.
    public let position: CGPoint
    
    /// Size of the collision rectangle.
    public let size: CGSize
    
    /// Whether this is a one-way platform (player can jump through from below).
    public let isOneWay: Bool
    
    public init(position: CGPoint, size: CGSize, isOneWay: Bool = false) {
        self.position = position
        self.size = size
        self.isOneWay = isOneWay
    }
    
    /// Convenience: create from left-x, top-y, width, height (easier for level layout).
    public static func fromTopLeft(x: CGFloat, y: CGFloat, width: CGFloat, height: CGFloat, isOneWay: Bool = false) -> CollisionRect {
        return CollisionRect(
            position: CGPoint(x: x + width / 2.0, y: y - height / 2.0),
            size: CGSize(width: width, height: height),
            isOneWay: isOneWay
        )
    }
}

/// Builds optimized static collision geometry for a mine level.
///
/// Instead of giving every visual tile a physics body, this system creates
/// a small number of merged rectangular collision bodies from a list of
/// CollisionRect definitions.
public final class LevelCollision {
    
    /// The container node that holds all collision body nodes.
    public let collisionNode: SKNode
    
    /// The container node for world boundary edges.
    public let boundaryNode: SKNode
    
    public init() {
        collisionNode = SKNode()
        collisionNode.name = "level_collision"
        collisionNode.zPosition = 0
        
        boundaryNode = SKNode()
        boundaryNode.name = "level_boundary"
        boundaryNode.zPosition = 0
    }
    
    /// Builds all collision bodies from the provided rects and adds them to collisionNode.
    public func buildCollision(from rects: [CollisionRect]) {
        collisionNode.removeAllChildren()
        
        for rect in rects {
            let node = SKNode()
            node.position = rect.position
            
            let body = SKPhysicsBody(rectangleOf: rect.size)
            body.isDynamic = false
            body.friction = 0.0
            body.restitution = 0.0
            
            if rect.isOneWay {
                // One-way platforms: player collides from above only.
                // We use a separate category so we can selectively disable collision
                // based on player's vertical velocity in the scene's update loop.
                body.categoryBitMask = PhysicsCategory.ground.rawValue
                body.collisionBitMask = PhysicsCategory.player.rawValue | PhysicsCategory.enemy.rawValue
                body.contactTestBitMask = PhysicsCategory.player.rawValue
                node.name = "oneway_platform"
            } else {
                body.categoryBitMask = PhysicsCategory.ground.rawValue
                body.collisionBitMask = PhysicsCategory.player.rawValue | PhysicsCategory.enemy.rawValue
                body.contactTestBitMask = PhysicsCategory.player.rawValue
                node.name = "solid_ground"
            }
            
            node.physicsBody = body
            collisionNode.addChild(node)
        }
    }
    
    /// Creates world boundary edges so the player cannot leave the level.
    public func buildBoundaries(worldSize: CGSize, deathY: CGFloat) {
        boundaryNode.removeAllChildren()
        
        // Left wall
        let leftWall = SKNode()
        leftWall.position = CGPoint(x: 0, y: worldSize.height / 2.0)
        leftWall.physicsBody = SKPhysicsBody(edgeFrom: CGPoint(x: 0, y: -worldSize.height / 2.0),
                                             to: CGPoint(x: 0, y: worldSize.height / 2.0))
        leftWall.physicsBody?.categoryBitMask = PhysicsCategory.ground.rawValue
        leftWall.physicsBody?.friction = 0.0
        leftWall.physicsBody?.restitution = 0.0
        leftWall.name = "left_boundary"
        boundaryNode.addChild(leftWall)
        
        // Right wall
        let rightWall = SKNode()
        rightWall.position = CGPoint(x: worldSize.width, y: worldSize.height / 2.0)
        rightWall.physicsBody = SKPhysicsBody(edgeFrom: CGPoint(x: 0, y: -worldSize.height / 2.0),
                                              to: CGPoint(x: 0, y: worldSize.height / 2.0))
        rightWall.physicsBody?.categoryBitMask = PhysicsCategory.ground.rawValue
        rightWall.physicsBody?.friction = 0.0
        rightWall.physicsBody?.restitution = 0.0
        rightWall.name = "right_boundary"
        boundaryNode.addChild(rightWall)
    }
}
