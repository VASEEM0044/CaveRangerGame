import SpriteKit

/// Thread-safe in-memory cache for base textures and programmatically extracted sub-frame textures.
public final class TextureCache: @unchecked Sendable {
    
    /// Global shared singleton instance.
    public static let shared = TextureCache()
    
    private let lock = NSLock()
    private var baseTextures: [String: SKTexture] = [:]
    private var subTextures: [String: SKTexture] = [:]
    
    public init() {}
    
    /// Retrieves or loads a base texture by asset name, ensuring nearest-neighbor pixel-art filtering.
    public func baseTexture(named imageName: String) -> SKTexture {
        lock.lock()
        defer { lock.unlock() }
        
        if let cached = baseTextures[imageName] {
            return cached
        }
        
        CrashLogger.shared.logSync("TextureCache requesting: \(imageName)")
        
        let base = (imageName as NSString).deletingPathExtension
        let ext = (imageName as NSString).pathExtension.isEmpty ? "png" : (imageName as NSString).pathExtension
        
        var foundImage: UIImage? = nil
        
        // 1. Check direct file path in Assets directory
        if let path = Bundle.main.path(forResource: base, ofType: ext, inDirectory: "Assets") {
            foundImage = UIImage(contentsOfFile: path)
        }
        // 2. Check direct file path at bundle root
        if foundImage == nil, let path = Bundle.main.path(forResource: base, ofType: ext) {
            foundImage = UIImage(contentsOfFile: path)
        }
        // 3. Check with exact filename in Assets
        if foundImage == nil, let path = Bundle.main.path(forResource: imageName, ofType: nil, inDirectory: "Assets") {
            foundImage = UIImage(contentsOfFile: path)
        }
        // 4. Check with exact filename at root
        if foundImage == nil, let path = Bundle.main.path(forResource: imageName, ofType: nil) {
            foundImage = UIImage(contentsOfFile: path)
        }
        // 5. Try UIImage(named:) from asset catalog
        if foundImage == nil {
            foundImage = UIImage(named: imageName) ?? UIImage(named: base)
        }
        
        let texture: SKTexture
        if let image = foundImage {
            CrashLogger.shared.logSync("Successfully loaded UIImage for \(imageName), dimensions: \(image.size.width)x\(image.size.height)")
            texture = SKTexture(image: image)
        } else {
            CrashLogger.shared.logSync("WARNING: Asset \(imageName) not found in bundle, creating safe 64x64 placeholder")
            let renderer = UIGraphicsImageRenderer(size: CGSize(width: 64, height: 64))
            let fallbackImage = renderer.image { ctx in
                UIColor.darkGray.setFill()
                ctx.fill(CGRect(x: 0, y: 0, width: 64, height: 64))
            }
            texture = SKTexture(image: fallbackImage)
        }
        
        texture.filteringMode = .nearest
        baseTextures[imageName] = texture
        return texture
    }
    
    /// Retrieves a cached subtexture by key, or generates and caches it if absent.
    public func subTexture(forKey key: String, generator: () -> SKTexture) -> SKTexture {
        lock.lock()
        defer { lock.unlock() }
        
        if let cached = subTextures[key] {
            return cached
        }
        
        let texture = generator()
        texture.filteringMode = .nearest
        subTextures[key] = texture
        return texture
    }
    
    /// Checks whether a given base texture is already loaded into cache.
    public func hasBaseTexture(named imageName: String) -> Bool {
        lock.lock()
        defer { lock.unlock() }
        return baseTextures[imageName] != nil
    }
    
    /// Checks whether a given subtexture key is present in cache.
    public func hasSubTexture(forKey key: String) -> Bool {
        lock.lock()
        defer { lock.unlock() }
        return subTextures[key] != nil
    }
    
    /// Clears cached textures (useful on memory warnings or level transitions).
    public func clear() {
        lock.lock()
        defer { lock.unlock() }
        baseTextures.removeAll()
        subTextures.removeAll()
    }
}
