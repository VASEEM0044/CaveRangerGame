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
        
        // 1. Try standard SKTexture(imageNamed:)
        var texture = SKTexture(imageNamed: imageName)
        
        // 2. If SKTexture returned an empty/unbacked texture, search Bundle resources
        if texture.size().width <= 0 || texture.size().height <= 0 {
            let base = (imageName as NSString).deletingPathExtension
            let ext = (imageName as NSString).pathExtension.isEmpty ? "png" : (imageName as NSString).pathExtension
            
            var foundPath: String? = nil
            if let path = Bundle.main.path(forResource: base, ofType: ext, inDirectory: "Assets") {
                foundPath = path
            } else if let path = Bundle.main.path(forResource: base, ofType: ext) {
                foundPath = path
            } else if let path = Bundle.main.path(forResource: imageName, ofType: nil, inDirectory: "Assets") {
                foundPath = path
            } else if let path = Bundle.main.path(forResource: imageName, ofType: nil) {
                foundPath = path
            }
            
            if let path = foundPath, let image = UIImage(contentsOfFile: path) {
                texture = SKTexture(image: image)
            }
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
