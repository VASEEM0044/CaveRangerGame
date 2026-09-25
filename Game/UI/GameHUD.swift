import SpriteKit
import UIKit

/// High-level HUD overlay and modal menu interface for Cave Ranger.
///
/// Features:
/// - Top-Left: Player Health (Heart icons/HP readout), Collected Coins count.
/// - Top-Center: Level elapsed time readout.
/// - Top-Right: Revolver ammunition count / Reload indicator, Pause button.
/// - Modal Overlays:
///   - Pause Menu (`RESUME`, `RESTART`)
///   - Level Complete Panel (Coins collected, final clear time, `CONTINUE` / `RESTART`)
///   - Game Over Panel (`RETRY`)
/// - Safe-area inset adaptation for notch, Dynamic Island, and Home Indicator.
/// - Fixed to screen via `GameCamera` node hierarchy.
public final class GameHUD: SKNode, UIOverlay {
    
    // MARK: - UIOverlay Conformance
    
    public var containerNode: SKNode { self }
    
    // MARK: - Top Bar Nodes
    
    private let topBarContainer: SKNode
    
    // Health display
    private let healthCard: SKShapeNode
    private let healthLabel: SKLabelNode
    
    // Coin display
    private let coinCard: SKShapeNode
    private let coinLabel: SKLabelNode
    
    // Timer display
    private let timerCard: SKShapeNode
    private let timerLabel: SKLabelNode
    
    // Ammo display
    private let ammoCard: SKShapeNode
    private let ammoLabel: SKLabelNode
    
    // Pause button
    private let pauseButton: HUDButton
    
    // MARK: - Modal Overlay Containers
    
    private let pauseOverlay: ModalOverlay
    private let levelCompleteOverlay: LevelCompleteModalOverlay
    private let gameOverOverlay: GameOverModalOverlay
    
    // MARK: - Callbacks
    
    public var onResumePressed: (() -> Void)?
    public var onRestartPressed: (() -> Void)?
    public var onPausePressed: (() -> Void)?
    
    // MARK: - Layout State
    
    private var currentViewportSize: CGSize = GameConfig.Display.logicalSize
    
    // MARK: - Initialization
    
    public init(viewportSize: CGSize = GameConfig.Display.logicalSize) {
        self.currentViewportSize = viewportSize
        
        // Containers
        topBarContainer = SKNode()
        topBarContainer.name = "hud_top_bar"
        topBarContainer.zPosition = 100
        
        // 1. Health Card (Top-Left)
        healthCard = SKShapeNode(rectOf: CGSize(width: 68.0, height: 18.0), cornerRadius: 4.0)
        healthCard.fillColor = SKColor(red: 0.10, green: 0.08, blue: 0.14, alpha: 0.70)
        healthCard.strokeColor = SKColor(red: 0.85, green: 0.25, blue: 0.30, alpha: 0.85)
        healthCard.lineWidth = 1.5
        
        healthLabel = SKLabelNode(fontNamed: "Menlo-Bold")
        healthLabel.text = "HP ♥ ♥ ♥"
        healthLabel.fontSize = 9.0
        healthLabel.fontColor = SKColor(red: 1.0, green: 0.40, blue: 0.45, alpha: 1.0)
        healthLabel.verticalAlignmentMode = .center
        healthLabel.horizontalAlignmentMode = .center
        healthCard.addChild(healthLabel)
        
        // 2. Coin Card (Top-Left, below health)
        coinCard = SKShapeNode(rectOf: CGSize(width: 78.0, height: 18.0), cornerRadius: 4.0)
        coinCard.fillColor = SKColor(red: 0.10, green: 0.08, blue: 0.14, alpha: 0.70)
        coinCard.strokeColor = SKColor(red: 0.90, green: 0.75, blue: 0.20, alpha: 0.85)
        coinCard.lineWidth = 1.5
        
        coinLabel = SKLabelNode(fontNamed: "Menlo-Bold")
        coinLabel.text = "COINS 0/20"
        coinLabel.fontSize = 8.5
        coinLabel.fontColor = SKColor(red: 1.0, green: 0.85, blue: 0.30, alpha: 1.0)
        coinLabel.verticalAlignmentMode = .center
        coinLabel.horizontalAlignmentMode = .center
        coinCard.addChild(coinLabel)
        
        // 3. Timer Card (Top-Center)
        timerCard = SKShapeNode(rectOf: CGSize(width: 62.0, height: 16.0), cornerRadius: 3.0)
        timerCard.fillColor = SKColor(red: 0.08, green: 0.06, blue: 0.10, alpha: 0.65)
        timerCard.strokeColor = SKColor(white: 0.60, alpha: 0.60)
        timerCard.lineWidth = 1.0
        
        timerLabel = SKLabelNode(fontNamed: "Courier-Bold")
        timerLabel.text = "00:00"
        timerLabel.fontSize = 9.0
        timerLabel.fontColor = SKColor(white: 0.90, alpha: 0.95)
        timerLabel.verticalAlignmentMode = .center
        timerLabel.horizontalAlignmentMode = .center
        timerCard.addChild(timerLabel)
        
        // 4. Ammo Card (Top-Right)
        ammoCard = SKShapeNode(rectOf: CGSize(width: 68.0, height: 18.0), cornerRadius: 4.0)
        ammoCard.fillColor = SKColor(red: 0.10, green: 0.08, blue: 0.14, alpha: 0.70)
        ammoCard.strokeColor = SKColor(red: 0.30, green: 0.70, blue: 0.90, alpha: 0.85)
        ammoCard.lineWidth = 1.5
        
        ammoLabel = SKLabelNode(fontNamed: "Menlo-Bold")
        ammoLabel.text = "REV 6/6"
        ammoLabel.fontSize = 8.5
        ammoLabel.fontColor = SKColor(red: 0.40, green: 0.85, blue: 1.0, alpha: 1.0)
        ammoLabel.verticalAlignmentMode = .center
        ammoLabel.horizontalAlignmentMode = .center
        ammoCard.addChild(ammoLabel)
        
        // 5. Pause Button (Top-Right)
        pauseButton = HUDButton(
            label: "II",
            size: CGSize(width: 24.0, height: 20.0),
            fillColor: SKColor(red: 0.15, green: 0.12, blue: 0.18, alpha: 0.75),
            strokeColor: SKColor(white: 0.85, alpha: 0.85),
            fontSize: 10.0
        )
        
        // 6. Overlays
        pauseOverlay = ModalOverlay(title: "PAUSED")
        levelCompleteOverlay = LevelCompleteModalOverlay()
        gameOverOverlay = GameOverModalOverlay()
        
        super.init()
        self.name = "game_hud"
        self.zPosition = 2000
        
        // Assemble Top Bar
        topBarContainer.addChild(healthCard)
        topBarContainer.addChild(coinCard)
        topBarContainer.addChild(timerCard)
        topBarContainer.addChild(ammoCard)
        topBarContainer.addChild(pauseButton)
        addChild(topBarContainer)
        
        // Assemble Overlays (Hidden by default)
        addChild(pauseOverlay)
        addChild(levelCompleteOverlay)
        addChild(gameOverOverlay)
        
        pauseOverlay.isHidden = true
        levelCompleteOverlay.isHidden = true
        gameOverOverlay.isHidden = true
        
        // Wire Button Callbacks
        setupButtonActions()
        
        // Initial Layout
        updateLayout(viewportSize: viewportSize, safeAreaInsets: .zero)
    }
    
    public required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Button Wiring
    
    private func setupButtonActions() {
        pauseButton.onTapped = { [weak self] in
            self?.onPausePressed?()
        }
        
        pauseOverlay.onResumeTapped = { [weak self] in
            self?.onResumePressed?()
        }
        
        pauseOverlay.onRestartTapped = { [weak self] in
            self?.onRestartPressed?()
        }
        
        levelCompleteOverlay.onContinueTapped = { [weak self] in
            self?.onRestartPressed?()
        }
        
        gameOverOverlay.onRetryTapped = { [weak self] in
            self?.onRestartPressed?()
        }
    }
    
    // MARK: - Layout & Safe Area
    
    public func updateLayout(viewportSize: CGSize, safeAreaInsets: UIEdgeInsets = .zero) {
        self.currentViewportSize = viewportSize
        
        let halfW = viewportSize.width / 2.0
        let halfH = viewportSize.height / 2.0
        
        let safeLeft = min(50.0, max(0.0, safeAreaInsets.left * 0.75))
        let safeRight = min(50.0, max(0.0, safeAreaInsets.right * 0.75))
        let safeTop = min(30.0, max(0.0, safeAreaInsets.top * 0.75))
        
        let topY = halfH - 18.0 - safeTop
        
        // Top-Left: Health & Coins
        healthCard.position = CGPoint(x: -halfW + 46.0 + safeLeft, y: topY)
        coinCard.position = CGPoint(x: -halfW + 51.0 + safeLeft, y: topY - 22.0)
        
        // Top-Center: Level Timer
        timerCard.position = CGPoint(x: 0.0, y: topY)
        
        // Top-Right: Ammo & Pause Button
        pauseButton.position = CGPoint(x: halfW - 20.0 - safeRight, y: topY)
        ammoCard.position = CGPoint(x: halfW - 74.0 - safeRight, y: topY)
        
        // Center Overlays
        pauseOverlay.updateLayout(viewportSize: viewportSize)
        levelCompleteOverlay.updateLayout(viewportSize: viewportSize)
        gameOverOverlay.updateLayout(viewportSize: viewportSize)
    }
    
    // MARK: - Dynamic State Updates
    
    /// Updates player health display (Heart icons).
    public func updateHealth(current: Int, max: Int) {
        let clampedCur = Swift.max(0, Swift.min(max, current))
        var heartsStr = "HP "
        for i in 0..<max {
            heartsStr += (i < clampedCur) ? "♥ " : "♡ "
        }
        healthLabel.text = heartsStr.trimmingCharacters(in: .whitespaces)
    }
    
    /// Updates collected coins display.
    public func updateCoins(count: Int) {
        coinLabel.text = "COINS \(count)"
    }
    
    /// Updates collected coins with total.
    public func updateCoins(collected: Int, total: Int) {
        coinLabel.text = "COINS \(collected)/\(total)"
    }
    
    /// Updates current revolver ammo display.
    public func updateAmmo(current: Int, max: Int, isReloading: Bool) {
        if isReloading {
            ammoLabel.text = "RELOAD..."
            ammoLabel.fontColor = SKColor(red: 1.0, green: 0.70, blue: 0.30, alpha: 1.0)
        } else if current == 0 {
            ammoLabel.text = "EMPTY!"
            ammoLabel.fontColor = SKColor(red: 1.0, green: 0.35, blue: 0.35, alpha: 1.0)
        } else {
            ammoLabel.text = "REV \(current)/\(max)"
            ammoLabel.fontColor = SKColor(red: 0.40, green: 0.85, blue: 1.0, alpha: 1.0)
        }
    }
    
    /// Formats and updates the elapsed level timer.
    public func updateTimer(elapsedTime: TimeInterval) {
        let totalSeconds = Int(elapsedTime)
        let minutes = totalSeconds / 60
        let seconds = totalSeconds % 60
        timerLabel.text = String(format: "%02d:%02d", minutes, seconds)
    }
    
    // MARK: - Modal Overlay Management
    
    public func setPauseOverlay(visible: Bool) {
        pauseOverlay.isHidden = !visible
        if visible {
            levelCompleteOverlay.isHidden = true
            gameOverOverlay.isHidden = true
        }
    }
    
    public func showLevelCompleteOverlay(coinsCollected: Int, totalCoins: Int, elapsedTime: TimeInterval) {
        levelCompleteOverlay.displayStats(coins: coinsCollected, total: totalCoins, time: elapsedTime)
        levelCompleteOverlay.isHidden = false
        pauseOverlay.isHidden = true
        gameOverOverlay.isHidden = true
    }
    
    public func showGameOverOverlay() {
        gameOverOverlay.isHidden = false
        pauseOverlay.isHidden = true
        levelCompleteOverlay.isHidden = true
    }
    
    public func hideAllOverlays() {
        pauseOverlay.isHidden = true
        levelCompleteOverlay.isHidden = true
        gameOverOverlay.isHidden = true
    }
    
    // MARK: - Touch Dispatch & Consumption
    
    /// Checks and consumes HUD touch events, returning true if consumed to prevent world pass-through.
    public func handleTouchesBegan(_ touches: Set<UITouch>, in scene: SKScene) -> Bool {
        for touch in touches {
            let localPoint = touch.location(in: self)
            
            // 1. Check Active Modal Overlays first
            if !pauseOverlay.isHidden {
                if pauseOverlay.handleTouchBegan(localPoint) { return true }
                return true // Scrim blocks clicks
            }
            if !levelCompleteOverlay.isHidden {
                if levelCompleteOverlay.handleTouchBegan(localPoint) { return true }
                return true
            }
            if !gameOverOverlay.isHidden {
                if gameOverOverlay.handleTouchBegan(localPoint) { return true }
                return true
            }
            
            // 2. Check Top-Right Pause Button
            let pausePoint = touch.location(in: topBarContainer)
            if pauseButton.contains(pausePoint) {
                pauseButton.touchBegan()
                return true
            }
        }
        return false
    }
    
    public func handleTouchesEnded(_ touches: Set<UITouch>, in scene: SKScene) -> Bool {
        for touch in touches {
            let localPoint = touch.location(in: self)
            
            if !pauseOverlay.isHidden {
                if pauseOverlay.handleTouchEnded(localPoint) { return true }
                return true
            }
            if !levelCompleteOverlay.isHidden {
                if levelCompleteOverlay.handleTouchEnded(localPoint) { return true }
                return true
            }
            if !gameOverOverlay.isHidden {
                if gameOverOverlay.handleTouchEnded(localPoint) { return true }
                return true
            }
            
            let pausePoint = touch.location(in: topBarContainer)
            if pauseButton.isPressed {
                pauseButton.touchEnded(triggered: pauseButton.contains(pausePoint))
                return true
            }
        }
        return false
    }
}

// MARK: - HUD Button Component

private final class HUDButton: SKNode {
    let size: CGSize
    let shapeNode: SKShapeNode
    let labelNode: SKLabelNode
    
    private let baseFillColor: SKColor
    private let baseStrokeColor: SKColor
    private let pressedFillColor: SKColor
    
    public private(set) var isPressed: Bool = false
    public var onTapped: (() -> Void)?
    
    init(label: String,
         size: CGSize,
         fillColor: SKColor,
         strokeColor: SKColor,
         fontSize: CGFloat,
         cornerRadius: CGFloat = 4.0) {
        
        self.size = size
        self.baseFillColor = fillColor
        self.baseStrokeColor = strokeColor
        self.pressedFillColor = fillColor.withAlphaComponent(Swift.min(1.0, 0.90))
        
        shapeNode = SKShapeNode(rectOf: size, cornerRadius: cornerRadius)
        shapeNode.fillColor = fillColor
        shapeNode.strokeColor = strokeColor
        shapeNode.lineWidth = 1.5
        shapeNode.zPosition = 100
        
        labelNode = SKLabelNode(fontNamed: "Menlo-Bold")
        labelNode.text = label
        labelNode.fontSize = fontSize
        labelNode.fontColor = SKColor.white
        labelNode.horizontalAlignmentMode = .center
        labelNode.verticalAlignmentMode = .center
        labelNode.zPosition = 101
        
        super.init()
        addChild(shapeNode)
        addChild(labelNode)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func contains(_ point: CGPoint) -> Bool {
        let halfW = size.width / 2.0 + 6.0
        let halfH = size.height / 2.0 + 6.0
        return point.x >= position.x - halfW && point.x <= position.x + halfW &&
               point.y >= position.y - halfH && point.y <= position.y + halfH
    }
    
    func touchBegan() {
        isPressed = true
        shapeNode.fillColor = pressedFillColor
        self.setScale(0.92)
    }
    
    func touchEnded(triggered: Bool) {
        isPressed = false
        shapeNode.fillColor = baseFillColor
        self.setScale(1.0)
        if triggered {
            onTapped?()
        }
    }
}

// MARK: - Pause Modal Overlay

private final class ModalOverlay: SKNode {
    private let scrim: SKShapeNode
    private let panel: SKShapeNode
    private let titleLabel: SKLabelNode
    private let resumeButton: HUDButton
    private let restartButton: HUDButton
    
    public var onResumeTapped: (() -> Void)?
    public var onRestartTapped: (() -> Void)?
    
    init(title: String) {
        scrim = SKShapeNode(rectOf: CGSize(width: 800, height: 500))
        scrim.fillColor = SKColor(white: 0.0, alpha: 0.60)
        scrim.strokeColor = .clear
        scrim.zPosition = 100
        
        panel = SKShapeNode(rectOf: CGSize(width: 170, height: 115), cornerRadius: 8.0)
        panel.fillColor = SKColor(red: 0.12, green: 0.10, blue: 0.16, alpha: 0.95)
        panel.strokeColor = SKColor(red: 0.85, green: 0.70, blue: 0.30, alpha: 0.85)
        panel.lineWidth = 2.0
        panel.zPosition = 101
        
        titleLabel = SKLabelNode(fontNamed: "Menlo-Bold")
        titleLabel.text = title
        titleLabel.fontSize = 15.0
        titleLabel.fontColor = SKColor(red: 1.0, green: 0.85, blue: 0.40, alpha: 1.0)
        titleLabel.position = CGPoint(x: 0, y: 28.0)
        titleLabel.zPosition = 102
        
        resumeButton = HUDButton(
            label: "RESUME",
            size: CGSize(width: 120, height: 24),
            fillColor: SKColor(red: 0.20, green: 0.50, blue: 0.30, alpha: 0.85),
            strokeColor: SKColor(red: 0.40, green: 0.85, blue: 0.50, alpha: 0.90),
            fontSize: 10.0
        )
        resumeButton.position = CGPoint(x: 0, y: -2.0)
        resumeButton.zPosition = 102
        
        restartButton = HUDButton(
            label: "RESTART",
            size: CGSize(width: 120, height: 24),
            fillColor: SKColor(red: 0.45, green: 0.25, blue: 0.20, alpha: 0.85),
            strokeColor: SKColor(red: 0.85, green: 0.55, blue: 0.40, alpha: 0.90),
            fontSize: 10.0
        )
        restartButton.position = CGPoint(x: 0, y: -32.0)
        restartButton.zPosition = 102
        
        super.init()
        self.zPosition = 500
        
        addChild(scrim)
        addChild(panel)
        panel.addChild(titleLabel)
        panel.addChild(resumeButton)
        panel.addChild(restartButton)
        
        resumeButton.onTapped = { [weak self] in self?.onResumeTapped?() }
        restartButton.onTapped = { [weak self] in self?.onRestartTapped?() }
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func updateLayout(viewportSize: CGSize) {
        scrim.path = CGPath(rect: CGRect(x: -viewportSize.width/2 - 50, y: -viewportSize.height/2 - 50, width: viewportSize.width + 100, height: viewportSize.height + 100), transform: nil)
    }
    
    func handleTouchBegan(_ point: CGPoint) -> Bool {
        let p = convert(point, to: panel)
        if resumeButton.contains(p) {
            resumeButton.touchBegan()
            return true
        }
        if restartButton.contains(p) {
            restartButton.touchBegan()
            return true
        }
        return true
    }
    
    func handleTouchEnded(_ point: CGPoint) -> Bool {
        let p = convert(point, to: panel)
        if resumeButton.isPressed {
            resumeButton.touchEnded(triggered: resumeButton.contains(p))
            return true
        }
        if restartButton.isPressed {
            restartButton.touchEnded(triggered: restartButton.contains(p))
            return true
        }
        return true
    }
}

// MARK: - Level Complete Modal Overlay

private final class LevelCompleteModalOverlay: SKNode {
    private let scrim: SKShapeNode
    private let panel: SKShapeNode
    private let titleLabel: SKLabelNode
    private let coinsLabel: SKLabelNode
    private let timeLabel: SKLabelNode
    private let continueButton: HUDButton
    
    public var onContinueTapped: (() -> Void)?
    
    override init() {
        scrim = SKShapeNode(rectOf: CGSize(width: 800, height: 500))
        scrim.fillColor = SKColor(white: 0.0, alpha: 0.70)
        scrim.strokeColor = .clear
        scrim.zPosition = 100
        
        panel = SKShapeNode(rectOf: CGSize(width: 200, height: 140), cornerRadius: 8.0)
        panel.fillColor = SKColor(red: 0.10, green: 0.08, blue: 0.16, alpha: 0.95)
        panel.strokeColor = SKColor(red: 1.0, green: 0.85, blue: 0.30, alpha: 0.90)
        panel.lineWidth = 2.0
        panel.zPosition = 101
        
        titleLabel = SKLabelNode(fontNamed: "Menlo-Bold")
        titleLabel.text = "MINE CLEARED!"
        titleLabel.fontSize = 15.0
        titleLabel.fontColor = SKColor(red: 1.0, green: 0.85, blue: 0.30, alpha: 1.0)
        titleLabel.position = CGPoint(x: 0, y: 40.0)
        titleLabel.zPosition = 102
        
        coinsLabel = SKLabelNode(fontNamed: "Menlo-Bold")
        coinsLabel.text = "COINS: 0 / 20"
        coinsLabel.fontSize = 10.5
        coinsLabel.fontColor = SKColor(red: 0.95, green: 0.80, blue: 0.35, alpha: 1.0)
        coinsLabel.position = CGPoint(x: 0, y: 16.0)
        coinsLabel.zPosition = 102
        
        timeLabel = SKLabelNode(fontNamed: "Courier-Bold")
        timeLabel.text = "TIME: 00:00"
        timeLabel.fontSize = 10.5
        timeLabel.fontColor = SKColor(white: 0.90, alpha: 1.0)
        timeLabel.position = CGPoint(x: 0, y: -4.0)
        timeLabel.zPosition = 102
        
        continueButton = HUDButton(
            label: "CONTINUE",
            size: CGSize(width: 130, height: 26),
            fillColor: SKColor(red: 0.20, green: 0.55, blue: 0.35, alpha: 0.90),
            strokeColor: SKColor(red: 0.45, green: 0.90, blue: 0.55, alpha: 0.95),
            fontSize: 10.5
        )
        continueButton.position = CGPoint(x: 0, y: -38.0)
        continueButton.zPosition = 102
        
        super.init()
        self.zPosition = 500
        
        addChild(scrim)
        addChild(panel)
        panel.addChild(titleLabel)
        panel.addChild(coinsLabel)
        panel.addChild(timeLabel)
        panel.addChild(continueButton)
        
        continueButton.onTapped = { [weak self] in self?.onContinueTapped?() }
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func updateLayout(viewportSize: CGSize) {
        scrim.path = CGPath(rect: CGRect(x: -viewportSize.width/2 - 50, y: -viewportSize.height/2 - 50, width: viewportSize.width + 100, height: viewportSize.height + 100), transform: nil)
    }
    
    func displayStats(coins: Int, total: Int, time: TimeInterval) {
        coinsLabel.text = "COINS: \(coins) / \(total)"
        let totalSeconds = Int(time)
        let min = totalSeconds / 60
        let sec = totalSeconds % 60
        timeLabel.text = String(format: "TIME: %02d:%02d", min, sec)
    }
    
    func handleTouchBegan(_ point: CGPoint) -> Bool {
        let p = convert(point, to: panel)
        if continueButton.contains(p) {
            continueButton.touchBegan()
            return true
        }
        return true
    }
    
    func handleTouchEnded(_ point: CGPoint) -> Bool {
        let p = convert(point, to: panel)
        if continueButton.isPressed {
            continueButton.touchEnded(triggered: continueButton.contains(p))
            return true
        }
        return true
    }
}

// MARK: - Game Over Modal Overlay

private final class GameOverModalOverlay: SKNode {
    private let scrim: SKShapeNode
    private let panel: SKShapeNode
    private let titleLabel: SKLabelNode
    private let subtitleLabel: SKLabelNode
    private let retryButton: HUDButton
    
    public var onRetryTapped: (() -> Void)?
    
    override init() {
        scrim = SKShapeNode(rectOf: CGSize(width: 800, height: 500))
        scrim.fillColor = SKColor(red: 0.15, green: 0.0, blue: 0.0, alpha: 0.70)
        scrim.strokeColor = .clear
        scrim.zPosition = 100
        
        panel = SKShapeNode(rectOf: CGSize(width: 170, height: 115), cornerRadius: 8.0)
        panel.fillColor = SKColor(red: 0.14, green: 0.08, blue: 0.08, alpha: 0.95)
        panel.strokeColor = SKColor(red: 0.90, green: 0.30, blue: 0.30, alpha: 0.85)
        panel.lineWidth = 2.0
        panel.zPosition = 101
        
        titleLabel = SKLabelNode(fontNamed: "Menlo-Bold")
        titleLabel.text = "GAME OVER"
        titleLabel.fontSize = 15.0
        titleLabel.fontColor = SKColor(red: 1.0, green: 0.35, blue: 0.35, alpha: 1.0)
        titleLabel.position = CGPoint(x: 0, y: 26.0)
        titleLabel.zPosition = 102
        
        subtitleLabel = SKLabelNode(fontNamed: "Menlo")
        subtitleLabel.text = "You fell in the mine."
        subtitleLabel.fontSize = 8.5
        subtitleLabel.fontColor = SKColor(white: 0.75, alpha: 0.90)
        subtitleLabel.position = CGPoint(x: 0, y: 6.0)
        subtitleLabel.zPosition = 102
        
        retryButton = HUDButton(
            label: "RETRY",
            size: CGSize(width: 110, height: 24),
            fillColor: SKColor(red: 0.60, green: 0.20, blue: 0.20, alpha: 0.85),
            strokeColor: SKColor(red: 0.95, green: 0.45, blue: 0.45, alpha: 0.90),
            fontSize: 10.0
        )
        retryButton.position = CGPoint(x: 0, y: -24.0)
        retryButton.zPosition = 102
        
        super.init()
        self.zPosition = 500
        
        addChild(scrim)
        addChild(panel)
        panel.addChild(titleLabel)
        panel.addChild(subtitleLabel)
        panel.addChild(retryButton)
        
        retryButton.onTapped = { [weak self] in self?.onRetryTapped?() }
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func updateLayout(viewportSize: CGSize) {
        scrim.path = CGPath(rect: CGRect(x: -viewportSize.width/2 - 50, y: -viewportSize.height/2 - 50, width: viewportSize.width + 100, height: viewportSize.height + 100), transform: nil)
    }
    
    func handleTouchBegan(_ point: CGPoint) -> Bool {
        let p = convert(point, to: panel)
        if retryButton.contains(p) {
            retryButton.touchBegan()
            return true
        }
        return true
    }
    
    func handleTouchEnded(_ point: CGPoint) -> Bool {
        let p = convert(point, to: panel)
        if retryButton.isPressed {
            retryButton.touchEnded(triggered: retryButton.contains(p))
            return true
        }
        return true
    }
}
