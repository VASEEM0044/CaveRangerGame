import SpriteKit

/// Describes the static layout and metadata of a cave level.
public struct LevelData: Sendable {
    /// Level identifier or stage number.
    public let levelIndex: Int
    
    /// World pixel size of the level boundaries.
    public let worldSize: CGSize
    
    /// Spawn coordinate for the player character.
    public let playerSpawnPoint: CGPoint
    
    /// Placement coordinate for the mine exit portal.
    public let exitPoint: CGPoint
    
    public init(
        levelIndex: Int,
        worldSize: CGSize,
        playerSpawnPoint: CGPoint,
        exitPoint: CGPoint
    ) {
        self.levelIndex = levelIndex
        self.worldSize = worldSize
        self.playerSpawnPoint = playerSpawnPoint
        self.exitPoint = exitPoint
    }
}

/// Architectural foundation protocol for level builders and tilemap loaders.
/// Procedural generation and tile placement will be implemented in subsequent phases.
public protocol LevelProvider: AnyObject {
    /// Builds and attaches level nodes (tilemaps, background, exits) to the target scene.
    func buildLevel(data: LevelData, in scene: SKScene) -> SKNode
}
