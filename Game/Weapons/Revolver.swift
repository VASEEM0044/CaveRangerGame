import SpriteKit

/// Revolver animation frame extraction using the centralized SpriteSheet utility.
public enum RevolverAnimations {
    private static let spriteSheet = SpriteSheet(definition: AssetConfig.revolver)
    
    public static let heldFrames        = spriteSheet.animationFrames(row: 0, startColumn: 0, count: 4)
    public static let aimFrames         = spriteSheet.animationFrames(row: 1, startColumn: 0, count: 4)
    public static let fireFrames        = spriteSheet.animationFrames(row: 2, startColumn: 0, count: 4)
    public static let recoilFrames      = spriteSheet.animationFrames(row: 3, startColumn: 0, count: 4)
    public static let reloadFrames      = spriteSheet.animationFrames(row: 4, startColumn: 0, count: 6)
    public static let muzzleFlashFrames = spriteSheet.animationFrames(row: 5, startColumn: 0, count: 4)
}

/// Player's Revolver firearm class managing ammunition, firing, muzzle flash, recoil, reload, and bullet instantiation.
public final class Revolver: Weapon {
    
    // MARK: - Properties
    
    public override var weaponType: WeaponType { .revolver }
    public override var baseDamage: Int { GameConfig.Weapons.revolverDamage }
    public override var attackCooldown: TimeInterval { GameConfig.Weapons.revolverFireCooldown }
    
    /// Maximum capacity of a magazine.
    public let magazineSize: Int = GameConfig.Weapons.revolverMagazineSize
    
    /// Current ammunition count in magazine.
    public private(set) var currentAmmo: Int = GameConfig.Weapons.revolverMagazineSize
    
    /// Whether the revolver is actively undergoing a reload sequence.
    public private(set) var isReloading: Bool = false
    
    /// Whether the player is currently aiming down sights.
    public private(set) var isAiming: Bool = false
    
    /// Timer tracking remaining reload time.
    private var reloadTimer: TimeInterval = 0
    
    /// Sprite node rendering the revolver artwork.
    private let spriteNode: SKSpriteNode
    
    /// Sprite node rendering muzzle flash effect when fired.
    private let muzzleFlashNode: SKSpriteNode
    
    // MARK: - Initialization
    
    public override init() {
        let initialTexture = RevolverAnimations.heldFrames.first ?? SKTexture()
        let displaySize = CGSize(width: 32.0, height: 32.0)
        self.spriteNode = SKSpriteNode(texture: initialTexture, color: .clear, size: displaySize)
        
        let flashTexture = RevolverAnimations.muzzleFlashFrames.first ?? SKTexture()
        self.muzzleFlashNode = SKSpriteNode(texture: flashTexture, color: .clear, size: CGSize(width: 24.0, height: 24.0))
        
        super.init()
        
        self.name = "revolver_weapon"
        self.zPosition = 11
        
        addChild(spriteNode)
        
        muzzleFlashNode.position = CGPoint(x: 18.0, y: 4.0)
        muzzleFlashNode.isHidden = true
        muzzleFlashNode.zPosition = 14
        addChild(muzzleFlashNode)
    }
    
    public required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) is not supported for Revolver")
    }
    
    // MARK: - Per-Frame Update
    
    public override func update(deltaTime: TimeInterval) {
        super.update(deltaTime: deltaTime)
        
        // Handle reload timer tick
        if isReloading {
            reloadTimer -= deltaTime
            if reloadTimer <= 0 {
                finishReload()
            }
        }
    }
    
    // MARK: - Position & Facing Update
    
    public func updatePosition(playerPosition: CGPoint, facing: FacingDirection) {
        let xOffset: CGFloat = facing == .right ? 12.0 : -12.0
        self.position = CGPoint(x: playerPosition.x + xOffset, y: playerPosition.y - 2.0)
        
        let targetScale: CGFloat = facing == .right ? 1.0 : -1.0
        spriteNode.xScale = targetScale
        muzzleFlashNode.xScale = targetScale
        muzzleFlashNode.position.x = facing == .right ? 18.0 : -18.0
    }
    
    // MARK: - Firing Action
    
    /// Fires a single bullet from the revolver if ammo is available and not on cooldown/reloading.
    public func fire(playerPosition: CGPoint, facing: FacingDirection, scene: SKScene) -> Bullet? {
        guard currentAmmo > 0 && cooldownTimer <= 0 && !isReloading else {
            if currentAmmo == 0 && !isReloading {
                reload()
            }
            return nil
        }
        
        currentAmmo -= 1
        startCooldown()
        
        // Update revolver sprite transforms
        updatePosition(playerPosition: playerPosition, facing: facing)
        
        // Play Fire + Recoil animation
        let fireAnim = SKAction.animate(with: RevolverAnimations.fireFrames, timePerFrame: 0.05, resize: false, restore: false)
        let recoilAnim = SKAction.animate(with: RevolverAnimations.recoilFrames, timePerFrame: 0.06, resize: false, restore: false)
        let resetAnim = SKAction.animate(with: RevolverAnimations.heldFrames, timePerFrame: 0.08, resize: false, restore: false)
        
        spriteNode.run(SKAction.sequence([fireAnim, recoilAnim, resetAnim]), withKey: "revolver_fire")
        
        // Trigger Muzzle Flash
        triggerMuzzleFlash()
        
        // Spawn Bullet Node
        let bulletSpawnX: CGFloat = playerPosition.x + (facing == .right ? 22.0 : -22.0)
        let bulletSpawnY: CGFloat = playerPosition.y + 2.0
        let bullet = Bullet(spawnPosition: CGPoint(x: bulletSpawnX, y: bulletSpawnY), direction: facing)
        scene.addChild(bullet)
        
        return bullet
    }
    
    // MARK: - Muzzle Flash Trigger
    
    private func triggerMuzzleFlash() {
        muzzleFlashNode.isHidden = false
        let flashAnim = SKAction.animate(with: RevolverAnimations.muzzleFlashFrames, timePerFrame: 0.04, resize: false, restore: false)
        let hideFlash = SKAction.run { [weak self] in
            self?.muzzleFlashNode.isHidden = true
        }
        muzzleFlashNode.run(SKAction.sequence([flashAnim, hideFlash]), withKey: "muzzle_flash")
    }
    
    // MARK: - Reload Action
    
    /// Starts ammunition reload sequence.
    public func reload() {
        guard !isReloading && currentAmmo < magazineSize else { return }
        
        isReloading = true
        reloadTimer = GameConfig.Weapons.revolverReloadTime
        
        let reloadAnim = SKAction.animate(with: RevolverAnimations.reloadFrames, timePerFrame: 0.12, resize: false, restore: false)
        spriteNode.run(SKAction.repeatForever(reloadAnim), withKey: "revolver_reload")
    }
    
    private func finishReload() {
        isReloading = false
        currentAmmo = magazineSize
        spriteNode.removeAction(forKey: "revolver_reload")
        
        let resetAnim = SKAction.animate(with: RevolverAnimations.heldFrames, timePerFrame: 0.08, resize: false, restore: false)
        spriteNode.run(resetAnim)
    }
    
    // MARK: - Aiming State
    
    public func setAiming(_ aiming: Bool) {
        guard isAiming != aiming && !isReloading else { return }
        isAiming = aiming
        
        let frames = aiming ? RevolverAnimations.aimFrames : RevolverAnimations.heldFrames
        let anim = SKAction.animate(with: frames, timePerFrame: 0.08, resize: false, restore: false)
        spriteNode.run(anim, withKey: "revolver_aim")
    }
}
