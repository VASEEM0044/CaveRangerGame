import SpriteKit

/// Builds and manages the underground mine level environment, multi-tier rocky visuals,
/// depth/background, ladders, interactive props, enemies, and collision geometry.
public final class MineLevel {
    
    // MARK: - Level Dimensions
    
    /// Total world width of the mine level.
    public static let worldWidth: CGFloat = 2600.0
    
    /// Total world height of the multi-tier cave (supporting 3 vertical tiers).
    public static let worldHeight: CGFloat = 800.0
    
    /// Death fall threshold Y coordinate.
    public static let deathY: CGFloat = -100.0
    
    /// Player starting spawn position on Floor 1 (bottom left).
    public static let spawnPosition = CGPoint(x: 100.0, y: 160.0)
    
    // MARK: - Nodes & Containers
    
    public let levelNode: SKNode
    public let collision: LevelCollision
    
    // MARK: - Entities
    
    public private(set) var snakes: [SnakeEnemy] = []
    public private(set) var scorpions: [ScorpionEnemy] = []
    public private(set) var bats: [BatEnemy] = []
    public private(set) var coins: [Coin] = []
    public private(set) var ladders: [Ladder] = []
    public private(set) var props: [CaveProp] = []
    public private(set) var mineExit: MineExit!
    
    // MARK: - Initialization
    
    public init() {
        CrashLogger.shared.logSync("MineLevel init started (Multi-Tier 2D Rocky Cave)")
        levelNode = SKNode()
        levelNode.name = "mine_level"
        collision = LevelCollision()
        
        buildBackground()
        buildMultiTierRockyGeometry()
        spawnLadders()
        spawnProps()
        spawnEnemies()
        spawnCoins()
        spawnMineExit()
        
        levelNode.addChild(collision.collisionNode)
        levelNode.addChild(collision.boundaryNode)
        CrashLogger.shared.logSync("MineLevel multi-tier init finished successfully")
    }
    
    // MARK: - Background & Atmosphere
    
    private func buildBackground() {
        let bgGroup = SKNode()
        bgGroup.zPosition = -20
        bgGroup.name = "background_layer"
        
        let panelWidth: CGFloat = 600.0
        let panelHeight: CGFloat = MineLevel.worldHeight
        let numPanels = Int(ceil(MineLevel.worldWidth / panelWidth))
        
        for i in 0..<numPanels {
            let panel = SKSpriteNode(color: MineTileset.caveDark, size: CGSize(width: panelWidth + 2.0, height: panelHeight))
            panel.position = CGPoint(x: CGFloat(i) * panelWidth + panelWidth / 2.0, y: panelHeight / 2.0)
            bgGroup.addChild(panel)
            
            // Decorative cave wall details
            let entranceIndex = i % 4
            let entranceTex = MineTileset.entranceTexture(row: entranceIndex / 2, column: entranceIndex % 2)
            let entranceNode = SKSpriteNode(texture: entranceTex, size: CGSize(width: 340, height: 340))
            entranceNode.position = CGPoint(x: CGFloat(i) * panelWidth + panelWidth / 2.0, y: 380.0)
            entranceNode.alpha = 0.25
            bgGroup.addChild(entranceNode)
        }
        
        levelNode.addChild(bgGroup)
    }
    
    // MARK: - Multi-Tier Rocky Geometry
    
    private func buildMultiTierRockyGeometry() {
        var collisionRects: [CollisionRect] = []
        
        // =========================================================================
        // TIER 1: LOWER CAVE FLOOR (Y: 0 .. 120)
        // =========================================================================
        // Section 1A: Spawn floor (x: 0 .. 700, y: 0 .. 120)
        addRockyLedge(x: 0, y: 0, w: 700, h: 120, rects: &collisionRects)
        
        // Left boundary starting rock wall (x: 0..40, y: 120..800)
        addRockWall(x: 0, y: 120, w: 40, h: 680, rects: &collisionRects)
        
        // Section 1B: Stepping stones over dark pit (x: 700 .. 1100)
        // Pit gap: x: 700 .. 800 (Deadly gap or drop zone)
        addRockyLedge(x: 820, y: 0, w: 220, h: 80, rects: &collisionRects)
        
        // Section 1C: Ground floor continuation (x: 1100 .. 2600, y: 0 .. 120)
        addRockyLedge(x: 1100, y: 0, w: 1500, h: 120, rects: &collisionRects)
        
        // =========================================================================
        // TIER 2: MID CAVERN PLATFORMS & ROCKY LEDGES (Y: 280 .. 340)
        // =========================================================================
        // Ledge 2A (x: 200 .. 650, y: 300, h: 28)
        addRockyLedge(x: 200, y: 300, w: 450, h: 28, isOneWay: true, rects: &collisionRects)
        
        // Ledge 2B (x: 800 .. 1400, y: 320, h: 32)
        addRockyLedge(x: 800, y: 320, w: 600, h: 32, isOneWay: true, rects: &collisionRects)
        
        // Ledge 2C: Wooden Trestle Bridge (x: 1550 .. 2000, y: 300, h: 24)
        addWoodenPlatform(x: 1550, y: 300, w: 450, h: 24, isOneWay: true, rects: &collisionRects)
        
        // Ledge 2D (x: 2150 .. 2550, y: 320, h: 32)
        addRockyLedge(x: 2150, y: 320, w: 400, h: 32, isOneWay: true, rects: &collisionRects)
        
        // =========================================================================
        // TIER 3: UPPER CAVERN & EXIT VAULT (Y: 520 .. 580)
        // =========================================================================
        // Upper Ledge 3A (x: 120 .. 500, y: 540, h: 32) - High secret treasure room
        addRockyLedge(x: 120, y: 540, w: 380, h: 32, isOneWay: true, rects: &collisionRects)
        
        // Upper Ledge 3B (x: 750 .. 1300, y: 540, h: 32) - Bat cavern
        addRockyLedge(x: 750, y: 540, w: 550, h: 32, isOneWay: true, rects: &collisionRects)
        
        // Upper Ledge 3C (x: 1500 .. 2550, y: 520, h: 36) - Grand Exit Platform
        addRockyLedge(x: 1500, y: 520, w: 1050, h: 36, isOneWay: false, rects: &collisionRects)
        
        // =========================================================================
        // CAVE CEILINGS & BOUNDARIES (Y: 740 .. 800)
        // =========================================================================
        addRockWall(x: 0, y: 760, w: 2600, h: 40, rects: &collisionRects) // Top ceiling
        addRockWall(x: 2560, y: 120, w: 40, h: 680, rects: &collisionRects) // Right wall
        
        // Add Wall Torches with warm glow
        addWallTorch(at: CGPoint(x: 160, y: 220))
        addWallTorch(at: CGPoint(x: 580, y: 380))
        addWallTorch(at: CGPoint(x: 1100, y: 400))
        addWallTorch(at: CGPoint(x: 1650, y: 380))
        addWallTorch(at: CGPoint(x: 2100, y: 600))
        
        // Build Collision Bodies
        collision.buildCollision(from: collisionRects)
        collision.buildBoundaries(worldSize: CGSize(width: MineLevel.worldWidth, height: MineLevel.worldHeight), deathY: MineLevel.deathY)
    }
    
    // MARK: - Spawning Ladders
    
    private func spawnLadders() {
        // Ladder 1: Floor 1 to Tier 2 (x: 350, y: 120 .. 300)
        let lad1 = Ladder(position: CGPoint(x: 350.0, y: 210.0), height: 180.0)
        ladders.append(lad1)
        levelNode.addChild(lad1)
        
        // Ladder 2: Tier 2 to Tier 3 (x: 260, y: 328 .. 540)
        let lad2 = Ladder(position: CGPoint(x: 260.0, y: 434.0), height: 212.0)
        ladders.append(lad2)
        levelNode.addChild(lad2)
        
        // Ladder 3: Floor 1 to Tier 2 (x: 1050, y: 120 .. 320)
        let lad3 = Ladder(position: CGPoint(x: 1050.0, y: 220.0), height: 200.0)
        ladders.append(lad3)
        levelNode.addChild(lad3)
        
        // Ladder 4: Tier 2 to Tier 3 (x: 1200, y: 352 .. 540)
        let lad4 = Ladder(position: CGPoint(x: 1200.0, y: 446.0), height: 188.0)
        ladders.append(lad4)
        levelNode.addChild(lad4)
        
        // Ladder 5: Tier 2 to Tier 3 Exit Ledge (x: 1850, y: 324 .. 520)
        let lad5 = Ladder(position: CGPoint(x: 1850.0, y: 422.0), height: 196.0)
        ladders.append(lad5)
        levelNode.addChild(lad5)
    }
    
    // MARK: - Spawning Props
    
    private func spawnProps() {
        let propDefs: [(CavePropType, CGPoint)] = [
            // Tier 1 Props
            (.crate, CGPoint(x: 480.0, y: 140.0)),
            (.barrel, CGPoint(x: 520.0, y: 140.0)),
            (.barrel, CGPoint(x: 1350.0, y: 140.0)),
            
            // Tier 2 Props
            (.crate, CGPoint(x: 420.0, y: 330.0)),
            (.barrel, CGPoint(x: 920.0, y: 355.0)),
            (.crate, CGPoint(x: 1680.0, y: 330.0)),
            (.barrel, CGPoint(x: 2300.0, y: 355.0)),
            
            // Tier 3 Treasure & Props
            (.moneyBag, CGPoint(x: 180.0, y: 575.0)),
            (.moneyBag, CGPoint(x: 1000.0, y: 575.0)),
            (.crate, CGPoint(x: 1720.0, y: 555.0)),
            (.barrel, CGPoint(x: 1760.0, y: 555.0)),
            (.moneyBag, CGPoint(x: 2450.0, y: 555.0))
        ]
        
        for (type, pos) in propDefs {
            let prop = CaveProp(type: type, position: pos)
            props.append(prop)
            levelNode.addChild(prop)
        }
    }
    
    // MARK: - Spawning Enemies
    
    private func spawnEnemies() {
        // 1. Cobra Snakes (Tier 1 Ground Patrol)
        let snakePoints: [CGPoint] = [
            CGPoint(x: 550.0, y: 145.0),
            CGPoint(x: 1450.0, y: 145.0),
            CGPoint(x: 2100.0, y: 145.0)
        ]
        for pos in snakePoints {
            let snake = SnakeEnemy(spawnPosition: pos)
            snakes.append(snake)
            levelNode.addChild(snake)
        }
        
        // 2. Scorpions (Tier 2 Ledge Patrol)
        let scorpionPoints: [CGPoint] = [
            CGPoint(x: 480.0, y: 332.0),
            CGPoint(x: 1100.0, y: 354.0),
            CGPoint(x: 2350.0, y: 354.0)
        ]
        for pos in scorpionPoints {
            let scorpion = ScorpionEnemy(spawnPosition: pos)
            scorpions.append(scorpion)
            levelNode.addChild(scorpion)
        }
        
        // 3. Bats (Tier 3 Ceiling Hanging / Roosting)
        let batPoints: [CGPoint] = [
            CGPoint(x: 880.0, y: 710.0),
            CGPoint(x: 1350.0, y: 710.0),
            CGPoint(x: 2150.0, y: 710.0)
        ]
        for pos in batPoints {
            let bat = BatEnemy(roostPosition: pos)
            bats.append(bat)
            levelNode.addChild(bat)
        }
    }
    
    // MARK: - Spawning Coins & Exit
    
    private func spawnCoins() {
        let coinPositions: [CGPoint] = [
            // Tier 1 Coins
            CGPoint(x: 220.0, y: 145.0),
            CGPoint(x: 300.0, y: 145.0),
            CGPoint(x: 880.0, y: 115.0),
            CGPoint(x: 960.0, y: 115.0),
            CGPoint(x: 1250.0, y: 145.0),
            CGPoint(x: 1800.0, y: 145.0),
            
            // Tier 2 Coins
            CGPoint(x: 300.0, y: 345.0),
            CGPoint(x: 580.0, y: 345.0),
            CGPoint(x: 860.0, y: 370.0),
            CGPoint(x: 1280.0, y: 370.0),
            CGPoint(x: 1600.0, y: 345.0),
            CGPoint(x: 1820.0, y: 345.0),
            CGPoint(x: 2220.0, y: 370.0),
            
            // Tier 3 Coins
            CGPoint(x: 220.0, y: 590.0),
            CGPoint(x: 380.0, y: 590.0),
            CGPoint(x: 820.0, y: 590.0),
            CGPoint(x: 1120.0, y: 590.0),
            CGPoint(x: 1600.0, y: 575.0),
            CGPoint(x: 1950.0, y: 575.0),
            CGPoint(x: 2150.0, y: 575.0)
        ]
        
        for pos in coinPositions {
            let coin = Coin(position: pos)
            coins.append(coin)
            levelNode.addChild(coin)
        }
    }
    
    private func spawnMineExit() {
        // Placed at the top right of Tier 3 (x: 2380, y: 585)
        let exitPosition = CGPoint(x: 2380.0, y: 585.0)
        mineExit = MineExit(position: exitPosition)
        levelNode.addChild(mineExit)
    }
    
    // MARK: - Helper Level Builders
    
    private func addRockyLedge(x: CGFloat, y: CGFloat, w: CGFloat, h: CGFloat, isOneWay: Bool = false, rects: inout [CollisionRect]) {
        // 1. Rocky Fill Background / Body (wavy brown cave stone texture)
        let fillBlock = SKSpriteNode(texture: MineTileset.rockFillTexture, size: CGSize(width: w, height: h))
        fillBlock.position = CGPoint(x: x + w / 2.0, y: y + h / 2.0)
        fillBlock.zPosition = 1
        levelNode.addChild(fillBlock)
        
        // 2. Top Walkable Surface Trim with grey interlocking stone border
        let trimHeight: CGFloat = min(24.0, h)
        let topTrim = SKSpriteNode(texture: MineTileset.topLedgeTexture, size: CGSize(width: w, height: trimHeight))
        topTrim.position = CGPoint(x: x + w / 2.0, y: y + h - trimHeight / 2.0)
        topTrim.zPosition = 2
        levelNode.addChild(topTrim)
        
        rects.append(CollisionRect(position: fillBlock.position, size: CGSize(width: w, height: h), isOneWay: isOneWay))
    }
    
    private func addRockWall(x: CGFloat, y: CGFloat, w: CGFloat, h: CGFloat, rects: inout [CollisionRect]) {
        let block = SKSpriteNode(texture: MineTileset.rockFillTexture, size: CGSize(width: w, height: h))
        block.position = CGPoint(x: x + w / 2.0, y: y + h / 2.0)
        block.zPosition = 1
        levelNode.addChild(block)
        
        rects.append(CollisionRect(position: block.position, size: CGSize(width: w, height: h)))
    }
    
    private func addWoodenPlatform(x: CGFloat, y: CGFloat, w: CGFloat, h: CGFloat, isOneWay: Bool, rects: inout [CollisionRect]) {
        let plat = SKSpriteNode(color: MineTileset.woodBrown, size: CGSize(width: w, height: h))
        plat.position = CGPoint(x: x + w / 2.0, y: y + h / 2.0)
        plat.zPosition = 3
        levelNode.addChild(plat)
        
        let highlight = SKSpriteNode(color: MineTileset.woodDark, size: CGSize(width: w, height: 3.0))
        highlight.position = CGPoint(x: x + w / 2.0, y: y + h - 1.5)
        highlight.zPosition = 4
        levelNode.addChild(highlight)
        
        rects.append(CollisionRect(position: plat.position, size: CGSize(width: w, height: h), isOneWay: isOneWay))
    }
    
    private func addWallTorch(at position: CGPoint) {
        // Torch mount base
        let mount = SKSpriteNode(color: MineTileset.woodDark, size: CGSize(width: 8.0, height: 16.0))
        mount.position = position
        mount.zPosition = 3
        levelNode.addChild(mount)
        
        // Torch head
        let head = SKSpriteNode(color: SKColor(red: 0.95, green: 0.60, blue: 0.10, alpha: 1.0), size: CGSize(width: 10.0, height: 10.0))
        head.position = CGPoint(x: position.x, y: position.y + 10.0)
        head.zPosition = 4
        levelNode.addChild(head)
        
        // Flickering warm ambient light halo
        let halo = SKShapeNode(circleOfRadius: 40.0)
        halo.fillColor = SKColor(red: 1.0, green: 0.75, blue: 0.3, alpha: 0.18)
        halo.strokeColor = .clear
        halo.position = CGPoint(x: position.x, y: position.y + 10.0)
        halo.zPosition = 2
        levelNode.addChild(halo)
        
        // Flicker animation
        let pulse1 = SKAction.scale(to: 1.15, duration: 0.18)
        let pulse2 = SKAction.scale(to: 0.88, duration: 0.14)
        let pulse3 = SKAction.scale(to: 1.0, duration: 0.16)
        halo.run(SKAction.repeatForever(SKAction.sequence([pulse1, pulse2, pulse3])))
    }
}

