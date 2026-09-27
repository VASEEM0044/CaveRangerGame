import SpriteKit

/// Centralized configuration and texture extraction for the mine cave environment.
///
/// The mine_cave_tileset.png (2048×2048) contains 16 mine entrance/tunnel decorative
/// frames arranged in a 4×4 grid (512×512 per cell). These serve as background decoration
/// and visual set-dressing. Actual walkable terrain is built from simple colored geometry
/// with textures sampled from subregions of the tileset for visual richness.
public enum MineTileset {
    
    // MARK: - Sheet Properties
    
    private static let fileName = "mine_cave_tileset.png"
    private static let sheetWidth: CGFloat = 2048.0
    private static let sheetHeight: CGFloat = 2048.0
    
    /// Full decorative frame size (each mine entrance variant).
    public static let entranceFrameSize: CGFloat = 512.0
    public static let entranceColumns: Int = 4
    public static let entranceRows: Int = 4
    
    // MARK: - Color Palette (derived from tileset artwork)
    
    /// Dark cave rock wall color.
    public static let rockDark = SKColor(red: 0.18, green: 0.15, blue: 0.20, alpha: 1.0)
    
    /// Medium cave rock surface.
    public static let rockMedium = SKColor(red: 0.28, green: 0.24, blue: 0.27, alpha: 1.0)
    
    /// Light rock / highlighted stone.
    public static let rockLight = SKColor(red: 0.38, green: 0.33, blue: 0.30, alpha: 1.0)
    
    /// Deep cave background / void.
    public static let caveDark = SKColor(red: 0.06, green: 0.04, blue: 0.08, alpha: 1.0)
    
    /// Warm wood brown for mine supports and platforms.
    public static let woodBrown = SKColor(red: 0.40, green: 0.28, blue: 0.16, alpha: 1.0)
    
    /// Dark wood beam color.
    public static let woodDark = SKColor(red: 0.30, green: 0.20, blue: 0.10, alpha: 1.0)
    
    /// Floor/ground dirt color.
    public static let groundDirt = SKColor(red: 0.32, green: 0.25, blue: 0.18, alpha: 1.0)
    
    /// Cave ceiling highlight.
    public static let ceilingDark = SKColor(red: 0.12, green: 0.10, blue: 0.14, alpha: 1.0)
    
    // MARK: - Decorative Mine Entrance Textures
    
    /// Sprite sheet for the 512×512 mine entrance frames.
    private static let entranceSheet = SpriteSheet(
        imageName: fileName,
        frameWidth: entranceFrameSize,
        frameHeight: entranceFrameSize
    )
    
    /// Retrieves a specific mine entrance variant texture (0-indexed, row-major).
    /// Row 0: basic dark entrances. Row 1: lit entrances. Row 2: glowing. Row 3: sparkle/star.
    public static func entranceTexture(row: Int, column: Int) -> SKTexture {
        return entranceSheet.texture(row: row, column: column)
    }
    
    /// Returns a random mine entrance variant for visual variety.
    public static func randomEntranceTexture() -> SKTexture {
        let row = Int.random(in: 0..<entranceRows)
        let col = Int.random(in: 0..<entranceColumns)
        return entranceTexture(row: row, column: col)
    }
    
    // MARK: - Sub-Region Texture Extraction
    
    /// Extracts a sub-region texture from the tileset using pixel coordinates.
    /// This enables sampling small rock/wood textures from the detailed entrance artwork.
    public static func subRegionTexture(pixelRect: CGRect) -> SKTexture {
        return TextureCache.shared.croppedTexture(from: fileName, pixelRect: pixelRect)
    }
    
    // MARK: - Commonly Used Texture Regions
    
    /// Rock wall texture sampled from the top-left entrance's cave wall area.
    public static var rockWallTexture: SKTexture {
        subRegionTexture(pixelRect: CGRect(x: 0, y: 0, width: 64, height: 64))
    }
    
    /// Wooden beam texture sampled from the top-left entrance's support beam.
    public static var woodBeamTexture: SKTexture {
        subRegionTexture(pixelRect: CGRect(x: 160, y: 32, width: 32, height: 128))
    }
    
    /// Dark cave interior texture.
    public static var caveInteriorTexture: SKTexture {
        subRegionTexture(pixelRect: CGRect(x: 200, y: 128, width: 128, height: 128))
    }
}
