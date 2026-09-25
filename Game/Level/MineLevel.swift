import SpriteKit

/// Builds and manages the underground mine level environment, visuals, depth/background, and collision geometry.
public final class MineLevel {
    
    // MARK: - Level Dimensions
    
    /// Total world width of the mine level.
    public static let worldWidth: CGFloat = 2400.0
    
    /// Total world height of the mine level.
    public static let worldHeight: CGFloat = 720.0
    
    /// Death fall threshold Y coordinate (if player falls below this, reset position).
    public static let deathY: CGFloat = -100.0
    
    /// Player starting spawn position in the mine.
    public static let spawnPosition = CGPoint(x: 100.0, y: 180.0)
    
    // MARK: - Nodes
    
    /// Root node containing all level visual elements and background.
    public let levelNode: SKNode
    
    /// Collision system handling static ground/walls/platforms.
    public let collision: LevelCollision
    
    /// Active snake enemies in the level.
    public private(set) var snakes: [SnakeEnemy] = []
    
    // MARK: - Initialization
    
    public init() {
        levelNode = SKNode()
        levelNode.name = "mine_level"
        collision = LevelCollision()
        
        buildBackground()
        buildLevelGeometryAndVisuals()
        spawnSnakes()
        
        levelNode.addChild(collision.collisionNode)
        levelNode.addChild(collision.boundaryNode)
    }
    
    // MARK: - Enemy Spawning
    
    private func spawnSnakes() {
        // Place 3 test snakes at reachable ground locations
        let spawnPoints: [CGPoint] = [
            CGPoint(x: 380.0, y: 150.0),  // 1. Starting corridor
            CGPoint(x: 1180.0, y: 190.0), // 2. Lower cave section
            CGPoint(x: 1900.0, y: 170.0)  // 3. Open cave section
        ]
        
        for pos in spawnPoints {
            let snake = SnakeEnemy(spawnPosition: pos)
            snakes.append(snake)
            levelNode.addChild(snake)
        }
    }
    
    // MARK: - Background & Atmosphere
    
    private func buildBackground() {
        // Deep background layer
        let bgGroup = SKNode()
        bgGroup.zPosition = -20
        bgGroup.name = "background_layer"
        
        // Dark cave backdrop panels spanning the level width
        let panelWidth: CGFloat = 600.0
        let panelHeight: CGFloat = MineLevel.worldHeight
        let numPanels = Int(ceil(MineLevel.worldWidth / panelWidth))
        
        for i in 0..<numPanels {
            let panel = SKSpriteNode(color: MineTileset.caveDark, size: CGSize(width: panelWidth + 2.0, height: panelHeight))
            panel.position = CGPoint(x: CGFloat(i) * panelWidth + panelWidth / 2.0, y: panelHeight / 2.0)
            bgGroup.addChild(panel)
            
            // Add decorative mine entrance frames in the background for cave depth
            let entranceIndex = i % 4
            let entranceTex = MineTileset.entranceTexture(row: entranceIndex / 2, column: entranceIndex % 2)
            let entranceNode = SKSpriteNode(texture: entranceTex, size: CGSize(width: 320, height: 320))
            entranceNode.position = CGPoint(x: CGFloat(i) * panelWidth + panelWidth / 2.0, y: 220.0)
            entranceNode.alpha = 0.35 // Dimmed for depth feel
            bgGroup.addChild(entranceNode)
        }
        
        levelNode.addChild(bgGroup)
    }
    
    // MARK: - Level Geometry & Visual Building
    
    private func buildLevelGeometryAndVisuals() {
        var collisionRects: [CollisionRect] = []
        
        // ----------------------------------------------------
        // SECTION 1: STARTING CAVE CORRIDOR (x: 0 .. 600)
        // ----------------------------------------------------
        // Ground floor: y=0 to y=100 (height 100)
        addGroundBlock(x: 0, y: 0, w: 600, h: 120, color: MineTileset.groundDirt, rects: &collisionRects)
        
        // Left starting wall (x: 0..40, y: 120..720)
        addWallBlock(x: 0, y: 120, w: 40, h: 600, rects: &collisionRects)
        
        // Ceiling over starting corridor (x: 0..600, y: 360..720)
        addWallBlock(x: 0, y: 360, w: 600, h: 360, rects: &collisionRects)
        
        // Decorative support beam at starting corridor
        addWoodSupport(x: 200, y: 120, height: 180)
        addWoodSupport(x: 450, y: 120, height: 180)
        
        // ----------------------------------------------------
        // SECTION 2: SMALL PLATFORM & GAP (x: 600 .. 1000)
        // ----------------------------------------------------
        // Lower pit floor (x: 600..1000, y: 0..40) - hazard/deep cave floor
        addGroundBlock(x: 600, y: 0, w: 400, h: 40, color: MineTileset.rockDark, rects: &collisionRects)
        
        // Raised stepping platform 1 (x: 680..800, y: 140, h: 20) - One-way platform
        addPlatform(x: 680, y: 140, w: 120, h: 16, isOneWay: true, rects: &collisionRects)
        
        // Stepping platform 2 (x: 860..980, y: 190, h: 20) - One-way platform
        addPlatform(x: 860, y: 190, w: 120, h: 16, isOneWay: true, rects: &collisionRects)
        
        // ----------------------------------------------------
        // SECTION 3: LOWER CAVE SECTION (x: 1000 .. 1400)
        // ----------------------------------------------------
        // Ground floor at y=0..160
        addGroundBlock(x: 1000, y: 0, w: 400, h: 160, color: MineTileset.groundDirt, rects: &collisionRects)
        
        // Ceiling (x: 1000..1400, y: 440..720)
        addWallBlock(x: 1000, y: 440, w: 400, h: 280, rects: &collisionRects)
        
        // Decorative mine entrance in background of lower cave
        let entranceBg = SKSpriteNode(texture: MineTileset.entranceTexture(row: 1, column: 2), size: CGSize(width: 250, height: 250))
        entranceBg.position = CGPoint(x: 1200, y: 280)
        entranceBg.zPosition = -10
        entranceBg.alpha = 0.6
        levelNode.addChild(entranceBg)
        
        // ----------------------------------------------------
        // SECTION 4: RAISED WOODEN PLATFORM & STAIRS (x: 1400 .. 1800)
        // ----------------------------------------------------
        // Step 1: Rock ledge (x: 1400..1520, y: 0..220)
        addGroundBlock(x: 1400, y: 0, w: 120, h: 220, color: MineTileset.rockMedium, rects: &collisionRects)
        
        // Raised wooden platform trestle (x: 1540..1760, y: 280)
        addWoodenTrestle(x: 1540, y: 280, w: 220, h: 20, rects: &collisionRects)
        
        // ----------------------------------------------------
        // SECTION 5: SMALL VERTICAL SECTION & OPEN CAVE AREA (x: 1800 .. 2400)
        // ----------------------------------------------------
        // High ledge ground (x: 1800..2360, y: 0..140)
        addGroundBlock(x: 1800, y: 0, w: 560, h: 140, color: MineTileset.groundDirt, rects: &collisionRects)
        
        // Upper platform in open area (x: 1950..2150, y: 260)
        addPlatform(x: 1950, y: 260, w: 200, h: 18, isOneWay: true, rects: &collisionRects)
        
        // Right boundary wall (x: 2360..2400, y: 140..720)
        addWallBlock(x: 2360, y: 140, w: 40, h: 580, rects: &collisionRects)
        
        // Decorative mine exit frame at the end of the cave
        let exitFrame = SKSpriteNode(texture: MineTileset.entranceTexture(row: 0, column: 0), size: CGSize(width: 280, height: 280))
        exitFrame.position = CGPoint(x: 2220, y: 280)
        exitFrame.zPosition = -5
        levelNode.addChild(exitFrame)
        
        // Build merged collision geometry
        collision.buildCollision(from: collisionRects)
        collision.buildBoundaries(worldSize: CGSize(width: MineLevel.worldWidth, height: MineLevel.worldHeight), deathY: MineLevel.deathY)
    }
    
    // MARK: - Helper Builders
    
    private func addGroundBlock(x: CGFloat, y: CGFloat, w: CGFloat, h: CGFloat, color: SKColor, rects: inout [CollisionRect]) {
        let block = SKSpriteNode(color: color, size: CGSize(width: w, height: h))
        block.position = CGPoint(x: x + w / 2.0, y: y + h / 2.0)
        block.zPosition = 1
        levelNode.addChild(block)
        
        // Top surface trim highlight for rocky ground feel
        let trim = SKSpriteNode(color: MineTileset.rockLight, size: CGSize(width: w, height: 4.0))
        trim.position = CGPoint(x: x + w / 2.0, y: y + h - 2.0)
        trim.zPosition = 2
        levelNode.addChild(trim)
        
        rects.append(CollisionRect(position: block.position, size: CGSize(width: w, height: h)))
    }
    
    private func addWallBlock(x: CGFloat, y: CGFloat, w: CGFloat, h: CGFloat, rects: inout [CollisionRect]) {
        let block = SKSpriteNode(color: MineTileset.rockDark, size: CGSize(width: w, height: h))
        block.position = CGPoint(x: x + w / 2.0, y: y + h / 2.0)
        block.zPosition = 1
        levelNode.addChild(block)
        
        rects.append(CollisionRect(position: block.position, size: CGSize(width: w, height: h)))
    }
    
    private func addPlatform(x: CGFloat, y: CGFloat, w: CGFloat, h: CGFloat, isOneWay: Bool, rects: inout [CollisionRect]) {
        let plat = SKSpriteNode(color: MineTileset.woodBrown, size: CGSize(width: w, height: h))
        plat.position = CGPoint(x: x + w / 2.0, y: y - h / 2.0)
        plat.zPosition = 3
        levelNode.addChild(plat)
        
        // Top edge plank highlight
        let highlight = SKSpriteNode(color: MineTileset.woodDark, size: CGSize(width: w, height: 3.0))
        highlight.position = CGPoint(x: x + w / 2.0, y: y - 1.5)
        highlight.zPosition = 4
        levelNode.addChild(highlight)
        
        rects.append(CollisionRect(position: plat.position, size: CGSize(width: w, height: h), isOneWay: isOneWay))
    }
    
    private func addWoodenTrestle(x: CGFloat, y: CGFloat, w: CGFloat, h: CGFloat, rects: inout [CollisionRect]) {
        // Platform top
        addPlatform(x: x, y: y, w: w, h: h, isOneWay: true, rects: &rects)
        
        // Vertical support legs
        let leg1 = SKSpriteNode(color: MineTileset.woodDark, size: CGSize(width: 12, height: y - 140))
        leg1.position = CGPoint(x: x + 20, y: 140 + (y - 140) / 2.0)
        leg1.zPosition = 2
        levelNode.addChild(leg1)
        
        let leg2 = SKSpriteNode(color: MineTileset.woodDark, size: CGSize(width: 12, height: y - 140))
        leg2.position = CGPoint(x: x + w - 20, y: 140 + (y - 140) / 2.0)
        leg2.zPosition = 2
        levelNode.addChild(leg2)
    }
    
    private func addWoodSupport(x: CGFloat, y: CGFloat, height: CGFloat) {
        let beam = SKSpriteNode(color: MineTileset.woodDark, size: CGSize(width: 14, height: height))
        beam.position = CGPoint(x: x, y: y + height / 2.0)
        beam.zPosition = 2
        levelNode.addChild(beam)
        
        let cap = SKSpriteNode(color: MineTileset.woodBrown, size: CGSize(width: 36, height: 12))
        cap.position = CGPoint(x: x, y: y + height - 6)
        cap.zPosition = 3
        levelNode.addChild(cap)
    }
}
