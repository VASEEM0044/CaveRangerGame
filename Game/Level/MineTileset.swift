import SpriteKit

/// Centralized configuration and texture extraction for the mine cave environment.
/// Extracts 16-bit authentic Spelunky-style modular rocky cave tiles from `cave_tileset.png`.
public enum MineTileset {
    
    // MARK: - Sheet Properties
    
    private static let caveTilesetFileName = "cave_tileset.png"
    private static let decorativeFileName = "mine_cave_tileset.png"
    
    // MARK: - 16-Bit Authentic Rocky Cave Tiles (from cave_tileset.png)
    
    /// Top walkable ledge surface tile with dirt texture and stone border trim (704×384).
    public static var topLedgeTexture: SKTexture {
        let rect = CGRect(x: 0, y: 0, width: 704, height: 384)
        return TextureCache.shared.croppedTexture(from: caveTilesetFileName, pixelRect: rect)
    }
    
    /// Natural repeating wavy rocky cave wall and deep fill tile (704×384).
    public static var rockFillTexture: SKTexture {
        let rect = CGRect(x: 0, y: 384, width: 704, height: 384)
        return TextureCache.shared.croppedTexture(from: caveTilesetFileName, pixelRect: rect)
    }
    
    /// Platform corner rounded rock cliff edge (352×384).
    public static var ledgeCornerTexture: SKTexture {
        let rect = CGRect(x: 1408, y: 0, width: 352, height: 384)
        return TextureCache.shared.croppedTexture(from: caveTilesetFileName, pixelRect: rect)
    }
    
    /// Ceiling hanging stalactite rock spikes (352×384).
    public static var stalactiteTexture: SKTexture {
        let rect = CGRect(x: 2112, y: 0, width: 352, height: 384)
        return TextureCache.shared.croppedTexture(from: caveTilesetFileName, pixelRect: rect)
    }
    
    // MARK: - Color Palette (derived from tileset artwork)
    
    public static let rockDark = SKColor(red: 0.18, green: 0.15, blue: 0.20, alpha: 1.0)
    public static let rockMedium = SKColor(red: 0.28, green: 0.24, blue: 0.27, alpha: 1.0)
    public static let rockLight = SKColor(red: 0.38, green: 0.33, blue: 0.30, alpha: 1.0)
    public static let caveDark = SKColor(red: 0.06, green: 0.04, blue: 0.08, alpha: 1.0)
    public static let woodBrown = SKColor(red: 0.40, green: 0.28, blue: 0.16, alpha: 1.0)
    public static let woodDark = SKColor(red: 0.30, green: 0.20, blue: 0.10, alpha: 1.0)
    public static let groundDirt = SKColor(red: 0.32, green: 0.25, blue: 0.18, alpha: 1.0)
    
    // MARK: - Decorative Background Entrances
    
    private static let entranceSheet = SpriteSheet(
        imageName: decorativeFileName,
        frameWidth: 512.0,
        frameHeight: 512.0
    )
    
    public static func entranceTexture(row: Int, column: Int) -> SKTexture {
        return entranceSheet.texture(row: row, column: column)
    }
}
