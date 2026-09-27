import SpriteKit

/// Type of cave prop.
public enum CavePropType: String, Sendable {
    case barrel
    case crate
    case moneyBag
}

/// Interactive and destructible props found throughout the rocky cave.
/// Extracted directly from `cave_props_and_enemies.png`.
public final class CaveProp: SKSpriteNode {
    
    public let propType: CavePropType
    public private(set) var isDestroyed: Bool = false
    
    // MARK: - Textures
    
    public static var barrelTexture: SKTexture {
        // Barrel bbox: (1460, 37, 276, 332)
        let rect = CGRect(x: 1460, y: 37, width: 276, height: 332)
        return TextureCache.shared.croppedTexture(from: "cave_props_and_enemies.png", pixelRect: rect)
    }
    
    public static var crateTexture: SKTexture {
        // Crate bbox: (390, 384, 312, 351)
        let rect = CGRect(x: 390, y: 384, width: 312, height: 351)
        return TextureCache.shared.croppedTexture(from: "cave_props_and_enemies.png", pixelRect: rect)
    }
    
    public static var moneyBagTexture: SKTexture {
        // MoneyBag bbox: (1550, 430, 248, 305)
        let rect = CGRect(x: 1550, y: 430, width: 248, height: 305)
        return TextureCache.shared.croppedTexture(from: "cave_props_and_enemies.png", pixelRect: rect)
    }
    
    // MARK: - Initialization
    
    public init(type: CavePropType, position: CGPoint) {
        self.propType = type
        
        let texture: SKTexture
        let displaySize: CGSize
        
        switch type {
        case .barrel:
            texture = CaveProp.barrelTexture
            displaySize = CGSize(width: 32.0, height: 38.0)
        case .crate:
            texture = CaveProp.crateTexture
            displaySize = CGSize(width: 36.0, height: 38.0)
        case .moneyBag:
            texture = CaveProp.moneyBagTexture
            displaySize = CGSize(width: 28.0, height: 34.0)
        }
        
        super.init(texture: texture, color: .clear, size: displaySize)
        
        self.name = "prop_\(type.rawValue)"
        self.position = position
        self.zPosition = 5
        
        setupPhysicsBody()
    }
    
    public required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) is not supported for CaveProp")
    }
    
    private func setupPhysicsBody() {
        if propType == .moneyBag {
            let body = SKPhysicsBody(circleOfRadius: 14.0)
            body.categoryBitMask = PhysicsCategory.collectible.rawValue
            body.collisionBitMask = PhysicsCategory.CollisionMasks.nonSolid
            body.contactTestBitMask = PhysicsCategory.player.rawValue
            body.isDynamic = false
            self.physicsBody = body
        } else {
            let body = SKPhysicsBody(rectangleOf: size)
            body.categoryBitMask = PhysicsCategory.ground.rawValue
            body.collisionBitMask = PhysicsCategory.player.rawValue | PhysicsCategory.enemy.rawValue
            body.contactTestBitMask = PhysicsCategory.weapon.rawValue | PhysicsCategory.projectile.rawValue
            body.isDynamic = false
            self.physicsBody = body
        }
    }
    
    /// Called when hit by whip or bullet.
    public func smash(in scene: SKScene, onCoinSpawn: ((Coin) -> Void)? = nil) {
        guard !isDestroyed && propType != .moneyBag else { return }
        isDestroyed = true
        
        AudioManager.shared.playSFX(.whipImpact)
        VFXManager.createDustPuff(at: position, in: scene, particleCount: 8)
        
        // Spawn reward coin
        let coin = Coin(position: position, value: 2)
        scene.addChild(coin)
        onCoinSpawn?(coin)
        
        self.removeFromParent()
    }
}
