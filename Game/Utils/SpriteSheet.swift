import SpriteKit

/// Utility capable of programmatically extracting sub-frame textures from a PNG sprite sheet
/// without creating individual files on disk or modifying original assets.
public struct SpriteSheet: Sendable {
    
    /// File or asset name of the sprite sheet PNG.
    public let imageName: String
    
    /// Width of a single frame in points/pixels.
    public let frameWidth: CGFloat
    
    /// Height of a single frame in points/pixels.
    public let frameHeight: CGFloat
    
    // MARK: - Initializers
    
    public init(imageName: String, frameWidth: CGFloat, frameHeight: CGFloat) {
        self.imageName = imageName
        self.frameWidth = frameWidth
        self.frameHeight = frameHeight
    }
    
    public init(definition: AssetConfig.SpriteSheetDefinition) {
        self.init(
            imageName: definition.fileName,
            frameWidth: definition.frameWidth,
            frameHeight: definition.frameHeight
        )
    }
    
    // MARK: - Properties
    
    /// Retrieves the base full-size texture from cache.
    public var baseTexture: SKTexture {
        TextureCache.shared.baseTexture(named: imageName)
    }
    
    /// Total dimensions of the underlying image.
    public var textureSize: CGSize {
        baseTexture.size()
    }
    
    /// Total number of columns in the sprite sheet.
    public var columns: Int {
        guard frameWidth > 0 else { return 0 }
        let width = textureSize.width
        return max(1, Int(width / frameWidth))
    }
    
    /// Total number of rows in the sprite sheet.
    public var rows: Int {
        guard frameHeight > 0 else { return 0 }
        let height = textureSize.height
        return max(1, Int(height / frameHeight))
    }
    
    /// Total number of frames available in the grid.
    public var totalFrames: Int {
        columns * rows
    }
    
    // MARK: - Frame Extraction
    
    /// Extracts a single frame texture specified by row and column (0-indexed, where row 0 is the top row).
    public func texture(row: Int, column: Int) -> SKTexture {
        let pixelRect = CGRect(
            x: CGFloat(column) * frameWidth,
            y: CGFloat(row) * frameHeight,
            width: frameWidth,
            height: frameHeight
        )
        return TextureCache.shared.croppedTexture(from: imageName, pixelRect: pixelRect)
    }
    
    /// Extracts a single frame texture specified by a linear frame index
    /// (0-indexed, traversing left-to-right, row-by-row from top to bottom).
    public func texture(frameIndex: Int) -> SKTexture {
        guard columns > 0 else { return baseTexture }
        let safeIndex = max(0, frameIndex)
        let row = safeIndex / columns
        let column = safeIndex % columns
        return texture(row: row, column: column)
    }
    
    /// Extracts an array of textures for an animation along a specific row.
    public func animationFrames(row: Int, startColumn: Int = 0, count: Int) -> [SKTexture] {
        guard count > 0 else { return [] }
        return (startColumn..<(startColumn + count)).map { col in
            texture(row: row, column: col)
        }
    }
    
    /// Extracts an array of textures across a contiguous range of linear frame indices.
    public func animationFrames(from startIndex: Int, to endIndex: Int) -> [SKTexture] {
        guard startIndex <= endIndex else { return [] }
        return (startIndex...endIndex).map { index in
            texture(frameIndex: index)
        }
    }
}
