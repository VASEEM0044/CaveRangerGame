import Foundation
import CoreGraphics

/// Centralized configuration for all gameplay sprite sheets and asset definitions.
///
/// Note: The application icon (`icon.png`) is intentionally excluded from this configuration.
/// It represents the iOS application bundle icon and must not be loaded via the gameplay sprite sheet system.
public enum AssetConfig {
    
    /// Specification for a single sprite sheet asset.
    public struct SpriteSheetDefinition: Sendable {
        /// File name of the asset on disk / asset catalog.
        public let fileName: String
        
        /// Width of an individual frame in points/pixels.
        public let frameWidth: CGFloat
        
        /// Height of an individual frame in points/pixels.
        public let frameHeight: CGFloat
        
        /// Indicates whether this asset represents a configurable tile set.
        public let isTileset: Bool
        
        /// Frame dimension as CGSize.
        public var frameSize: CGSize {
            CGSize(width: frameWidth, height: frameHeight)
        }
        
        public init(fileName: String, frameWidth: CGFloat, frameHeight: CGFloat, isTileset: Bool = false) {
            self.fileName = fileName
            self.frameWidth = frameWidth
            self.frameHeight = frameHeight
            self.isTileset = isTileset
        }
    }
    
    // MARK: - Gameplay Sprite Sheet Definitions
    
    /// Cowboy player character sprite sheet (32 × 32 frame size).
    public static let cowboyPlayer = SpriteSheetDefinition(
        fileName: "cowboy_player.png",
        frameWidth: 32.0,
        frameHeight: 32.0
    )
    
    /// Snake enemy sprite sheet (64 × 64 frame size).
    public static let snakeEnemy = SpriteSheetDefinition(
        fileName: "snake_enemy.png",
        frameWidth: 64.0,
        frameHeight: 64.0
    )
    
    /// Coin collectible sprite sheet (64 × 64 frame size).
    public static let coin = SpriteSheetDefinition(
        fileName: "coin.png",
        frameWidth: 64.0,
        frameHeight: 64.0
    )
    
    /// Whip weapon sprite sheet (64 × 64 frame size).
    public static let whip = SpriteSheetDefinition(
        fileName: "whip.png",
        frameWidth: 64.0,
        frameHeight: 64.0
    )
    
    /// Revolver weapon sprite sheet (64 × 64 frame size).
    public static let revolver = SpriteSheetDefinition(
        fileName: "revolver.png",
        frameWidth: 64.0,
        frameHeight: 64.0
    )
    
    /// Mine exit structure / door sprite sheet (128 × 128 frame size).
    public static let mineExit = SpriteSheetDefinition(
        fileName: "mine_exit.png",
        frameWidth: 128.0,
        frameHeight: 128.0
    )
    
    // MARK: - Configurable Tileset Definition
    
    /// Mine cave tileset configuration for environment blocks, hazards, and decorative props.
    /// Because tiles and props may have varying dimensions, this configuration is fully flexible.
    public struct TilesetConfig: Sendable {
        public let fileName: String
        public var defaultTileWidth: CGFloat
        public var defaultTileHeight: CGFloat
        
        public var defaultTileSize: CGSize {
            CGSize(width: defaultTileWidth, height: defaultTileHeight)
        }
        
        public init(
            fileName: String = "mine_cave_tileset.png",
            defaultTileWidth: CGFloat = 32.0,
            defaultTileHeight: CGFloat = 32.0
        ) {
            self.fileName = fileName
            self.defaultTileWidth = defaultTileWidth
            self.defaultTileHeight = defaultTileHeight
        }
        
        /// Generates a custom sprite sheet definition for non-standard tile or prop dimensions.
        public func definition(tileWidth: CGFloat, tileHeight: CGFloat) -> SpriteSheetDefinition {
            SpriteSheetDefinition(
                fileName: fileName,
                frameWidth: tileWidth,
                frameHeight: tileHeight,
                isTileset: true
            )
        }
    }
    
    /// Central configurable instance for the mine cave environment tileset.
    public static var mineCaveTileset = TilesetConfig()
    
    /// Lookup of all standard fixed-dimension gameplay sprite sheets.
    public static let allStandardAssets: [SpriteSheetDefinition] = [
        cowboyPlayer,
        snakeEnemy,
        coin,
        whip,
        revolver,
        mineExit
    ]
}
