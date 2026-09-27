import SpriteKit
import UIKit

/// Thread-safe in-memory cache for base textures and programmatically extracted sub-frame textures.
/// Uses native CoreGraphics sub-image cropping to eliminate SpriteKit texture subdivision crashes.
public final class TextureCache: @unchecked Sendable {
    
    /// Global shared singleton instance.
    public static let shared = TextureCache()
    
    private let lock = NSLock()
    private var baseImages: [String: UIImage] = [:]
    private var baseTextures: [String: SKTexture] = [:]
    private var subTextures: [String: SKTexture] = [:]
    
    public init() {}
    
    /// Retrieves or loads a base UIImage from bundle assets or disk.
    public func baseImage(named imageName: String) -> UIImage {
        lock.lock()
        defer { lock.unlock() }
        
        if let cached = baseImages[imageName] {
            return cached
        }
        
        CrashLogger.shared.logSync("TextureCache loading UIImage: \(imageName)")
        
        let base = (imageName as NSString).deletingPathExtension
        let ext = (imageName as NSString).pathExtension.isEmpty ? "png" : (imageName as NSString).pathExtension
        
        var foundImage: UIImage? = nil
        
        // 1. Direct file path in Assets directory
        if let path = Bundle.main.path(forResource: base, ofType: ext, inDirectory: "Assets") {
            foundImage = UIImage(contentsOfFile: path)
        }
        // 2. Direct file path at root
        if foundImage == nil, let path = Bundle.main.path(forResource: base, ofType: ext) {
            foundImage = UIImage(contentsOfFile: path)
        }
        // 3. Exact filename in Assets
        if foundImage == nil, let path = Bundle.main.path(forResource: imageName, ofType: nil, inDirectory: "Assets") {
            foundImage = UIImage(contentsOfFile: path)
        }
        // 4. Exact filename at root
        if foundImage == nil, let path = Bundle.main.path(forResource: imageName, ofType: nil) {
            foundImage = UIImage(contentsOfFile: path)
        }
        // 5. Asset catalog fallback
        if foundImage == nil {
            foundImage = UIImage(named: imageName) ?? UIImage(named: base)
        }
        
        let image: UIImage
        if let loaded = foundImage {
            CrashLogger.shared.logSync("Loaded UIImage for \(imageName): \(loaded.size.width)x\(loaded.size.height)")
            image = loaded
        } else {
            CrashLogger.shared.logSync("WARNING: Image \(imageName) missing on disk. Creating 64x64 safe fallback.")
            let renderer = UIGraphicsImageRenderer(size: CGSize(width: 64, height: 64))
            image = renderer.image { ctx in
                UIColor(red: 0.2, green: 0.2, blue: 0.25, alpha: 1.0).setFill()
                ctx.fill(CGRect(x: 0, y: 0, width: 64, height: 64))
            }
        }
        
        baseImages[imageName] = image
        return image
    }
    
    /// Retrieves or loads a base texture by asset name, ensuring nearest-neighbor pixel-art filtering.
    public func baseTexture(named imageName: String) -> SKTexture {
        lock.lock()
        defer { lock.unlock() }
        
        if let cached = baseTextures[imageName] {
            return cached
        }
        
        let image = baseImageUnlocked(named: imageName)
        let texture = SKTexture(image: image)
        texture.filteringMode = .nearest
        baseTextures[imageName] = texture
        return texture
    }
    
    /// Extracts a sub-region texture safely using native CoreGraphics CGImage cropping.
    /// Eliminates SpriteKit EXC_BAD_ACCESS texture subdivision bugs on physical hardware.
    public func croppedTexture(from imageName: String, pixelRect: CGRect) -> SKTexture {
        let key = "\(imageName)_x\(Int(pixelRect.origin.x))_y\(Int(pixelRect.origin.y))_w\(Int(pixelRect.width))_h\(Int(pixelRect.height))"
        
        lock.lock()
        if let cached = subTextures[key] {
            lock.unlock()
            return cached
        }
        let image = baseImageUnlocked(named: imageName)
        lock.unlock()
        
        guard let cgImage = image.cgImage else {
            let base = baseTexture(named: imageName)
            return base
        }
        
        let imageWidth = CGFloat(cgImage.width)
        let imageHeight = CGFloat(cgImage.height)
        
        let cropX = max(0, min(imageWidth - 1, pixelRect.origin.x))
        let cropY = max(0, min(imageHeight - 1, pixelRect.origin.y))
        let cropW = max(1, min(imageWidth - cropX, pixelRect.width))
        let cropH = max(1, min(imageHeight - cropY, pixelRect.height))
        
        let safeCropRect = CGRect(x: cropX, y: cropY, width: cropW, height: cropH)
        
        let finalTexture: SKTexture
        if let croppedCG = cgImage.cropping(to: safeCropRect) {
            finalTexture = SKTexture(cgImage: croppedCG)
        } else {
            finalTexture = baseTexture(named: imageName)
        }
        
        finalTexture.filteringMode = .nearest
        
        lock.lock()
        subTextures[key] = finalTexture
        lock.unlock()
        
        return finalTexture
    }
    
    /// Internal unlock helper for baseImage when lock is already acquired.
    private func baseImageUnlocked(named imageName: String) -> UIImage {
        if let cached = baseImages[imageName] {
            return cached
        }
        
        let base = (imageName as NSString).deletingPathExtension
        let ext = (imageName as NSString).pathExtension.isEmpty ? "png" : (imageName as NSString).pathExtension
        
        var foundImage: UIImage? = nil
        if let path = Bundle.main.path(forResource: base, ofType: ext, inDirectory: "Assets") {
            foundImage = UIImage(contentsOfFile: path)
        } else if let path = Bundle.main.path(forResource: base, ofType: ext) {
            foundImage = UIImage(contentsOfFile: path)
        } else if let path = Bundle.main.path(forResource: imageName, ofType: nil, inDirectory: "Assets") {
            foundImage = UIImage(contentsOfFile: path)
        } else if let path = Bundle.main.path(forResource: imageName, ofType: nil) {
            foundImage = UIImage(contentsOfFile: path)
        } else {
            foundImage = UIImage(named: imageName) ?? UIImage(named: base)
        }
        
        let image = foundImage ?? {
            let renderer = UIGraphicsImageRenderer(size: CGSize(width: 64, height: 64))
            return renderer.image { ctx in
                UIColor(red: 0.2, green: 0.2, blue: 0.25, alpha: 1.0).setFill()
                ctx.fill(CGRect(x: 0, y: 0, width: 64, height: 64))
            }
        }()
        
        baseImages[imageName] = image
        return image
    }
    
    /// Clears cached textures (useful on memory warnings or level transitions).
    public func clear() {
        lock.lock()
        defer { lock.unlock() }
        baseImages.removeAll()
        baseTextures.removeAll()
        subTextures.removeAll()
    }
}
