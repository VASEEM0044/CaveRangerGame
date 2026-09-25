import SpriteKit
import UIKit

/// On-screen touch control interface for iPhone and iPad gameplay.
///
/// Features:
/// - Virtual analog joystick on bottom-left with normalized horizontal output (-1.0 ... +1.0).
/// - Dedicated action buttons on bottom-right: Jump, Whip, Shoot (Revolver), and Reload.
/// - Full multi-touch support allowing concurrent joystick steering and button presses.
/// - Dynamic responsive positioning with iOS safe-area inset adaptation.
/// - Visual press feedback with subtle scale and alpha animations.
/// - Attached directly to the camera node to remain fixed on screen during world scrolling.
public final class TouchControls: SKNode {
    
    // MARK: - Sub-Node Elements
    
    /// Outer boundary circle for the virtual joystick.
    private let joystickBase: SKShapeNode
    
    /// Inner movable thumb knob for the virtual joystick.
    private let joystickThumb: SKShapeNode
    
    /// Circular center indicator dot for the joystick base.
    private let joystickCenterDot: SKShapeNode
    
    /// Action button nodes.
    private let jumpButton: TouchActionButton
    private let whipButton: TouchActionButton
    private let shootButton: TouchActionButton
    private let reloadButton: TouchActionButton
    
    /// Optional debug readout label.
    private let debugLabel: SKLabelNode
    
    // MARK: - Touch Tracking State
    
    /// Active touch driving the virtual joystick.
    private weak var joystickTouch: UITouch?
    
    /// Current normalized horizontal joystick axis: -1.0 (left), 0.0 (neutral), +1.0 (right).
    public private(set) var horizontalAxis: CGFloat = 0.0
    
    /// Base center position of the joystick in local coordinates.
    private var joystickCenter: CGPoint = .zero
    
    /// Maximum radial distance the joystick thumb can travel.
    private let joystickMaxRadius: CGFloat = 38.0
    
    /// Deadzone threshold below which input axis is treated as 0.0.
    private let joystickDeadzone: CGFloat = 4.0
    
    /// Maximum touch pickup distance from joystick center.
    private let joystickActivationRadius: CGFloat = 65.0
    
    /// Weak reference to the scene's PlayerController to dispatch input events.
    private weak var playerController: PlayerController?
    
    /// Current logical viewport dimensions.
    private var currentViewportSize: CGSize = GameConfig.Display.logicalSize
    
    // MARK: - Initialization
    
    public init(controller: PlayerController) {
        self.playerController = controller
        
        // 1. Joystick Base (Outer ring)
        joystickBase = SKShapeNode(circleOfRadius: 38.0)
        joystickBase.fillColor = SKColor(red: 0.10, green: 0.08, blue: 0.14, alpha: 0.35)
        joystickBase.strokeColor = SKColor(white: 0.90, alpha: 0.45)
        joystickBase.lineWidth = 2.0
        joystickBase.zPosition = 100
        
        // Joystick center dot
        joystickCenterDot = SKShapeNode(circleOfRadius: 4.0)
        joystickCenterDot.fillColor = SKColor(white: 0.85, alpha: 0.40)
        joystickCenterDot.strokeColor = .clear
        joystickCenterDot.zPosition = 101
        
        // 2. Joystick Thumb Knob
        joystickThumb = SKShapeNode(circleOfRadius: 18.0)
        joystickThumb.fillColor = SKColor(white: 0.92, alpha: 0.60)
        joystickThumb.strokeColor = SKColor(white: 1.0, alpha: 0.85)
        joystickThumb.lineWidth = 2.0
        joystickThumb.zPosition = 102
        
        // 3. Action Buttons (Retro pixel-art styled circular buttons)
        jumpButton = TouchActionButton(
            label: "JUMP",
            radius: 27.0,
            fillColor: SKColor(red: 0.95, green: 0.72, blue: 0.20, alpha: 0.35),
            strokeColor: SKColor(red: 1.00, green: 0.85, blue: 0.40, alpha: 0.75),
            fontSize: 10.0
        )
        
        whipButton = TouchActionButton(
            label: "WHIP",
            radius: 23.0,
            fillColor: SKColor(red: 0.85, green: 0.48, blue: 0.20, alpha: 0.35),
            strokeColor: SKColor(red: 0.95, green: 0.65, blue: 0.35, alpha: 0.75),
            fontSize: 9.0
        )
        
        shootButton = TouchActionButton(
            label: "SHOOT",
            radius: 23.0,
            fillColor: SKColor(red: 0.90, green: 0.25, blue: 0.25, alpha: 0.35),
            strokeColor: SKColor(red: 1.00, green: 0.45, blue: 0.45, alpha: 0.75),
            fontSize: 9.0
        )
        
        reloadButton = TouchActionButton(
            label: "RELOAD",
            radius: 17.0,
            fillColor: SKColor(red: 0.25, green: 0.65, blue: 0.85, alpha: 0.35),
            strokeColor: SKColor(red: 0.45, green: 0.80, blue: 0.95, alpha: 0.70),
            fontSize: 7.0
        )
        
        // 4. Debug Label
        debugLabel = SKLabelNode(fontNamed: "Courier-Bold")
        debugLabel.fontSize = 9.0
        debugLabel.fontColor = SKColor(red: 0.4, green: 1.0, blue: 0.4, alpha: 0.9)
        debugLabel.horizontalAlignmentMode = .left
        debugLabel.verticalAlignmentMode = .top
        debugLabel.zPosition = 200
        debugLabel.isHidden = !GameConfig.Debug.showPlayerDebug
        
        super.init()
        self.name = "touch_controls_layer"
        self.zPosition = 1000
        
        // Add children
        addChild(joystickBase)
        joystickBase.addChild(joystickCenterDot)
        addChild(joystickThumb)
        addChild(jumpButton)
        addChild(whipButton)
        addChild(shootButton)
        addChild(reloadButton)
        addChild(debugLabel)
        
        // Initial layout pass
        updateLayout(viewportSize: currentViewportSize, safeAreaInsets: .zero)
    }
    
    public required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Layout & Safe Area Adaptation
    
    /// Updates positions of on-screen controls relative to viewport size and iOS device safe-area insets.
    public func updateLayout(viewportSize: CGSize, safeAreaInsets: UIEdgeInsets = .zero) {
        self.currentViewportSize = viewportSize
        
        let halfW = viewportSize.width / 2.0
        let halfH = viewportSize.height / 2.0
        
        // Calculate safe inset scale in logical coordinates
        // Assuming logical width 640 and typical screen width ~844-932 pt
        let safeLeftInset = min(50.0, max(0.0, safeAreaInsets.left * 0.75))
        let safeRightInset = min(50.0, max(0.0, safeAreaInsets.right * 0.75))
        let safeBottomInset = min(30.0, max(0.0, safeAreaInsets.bottom * 0.75))
        
        // 1. Position Joystick (Bottom-Left)
        let joyX = -halfW + 58.0 + safeLeftInset
        let joyY = -halfH + 58.0 + safeBottomInset
        joystickCenter = CGPoint(x: joyX, y: joyY)
        joystickBase.position = joystickCenter
        if joystickTouch == nil {
            joystickThumb.position = joystickCenter
        }
        
        // 2. Position Action Buttons (Bottom-Right Cluster)
        // Cluster layout:
        //                      JUMP (top-right)
        //        WHIP (mid-left)     SHOOT (bottom-right)
        //   RELOAD (inner-left)
        let rightEdge = halfW - 48.0 - safeRightInset
        let bottomEdge = -halfH + 48.0 + safeBottomInset
        
        jumpButton.position = CGPoint(x: rightEdge - 8.0, y: bottomEdge + 62.0)
        shootButton.position = CGPoint(x: rightEdge, y: bottomEdge)
        whipButton.position = CGPoint(x: rightEdge - 58.0, y: bottomEdge + 20.0)
        reloadButton.position = CGPoint(x: rightEdge - 105.0, y: bottomEdge - 5.0)
        
        // 3. Position Debug Label (Top-Left)
        debugLabel.position = CGPoint(x: -halfW + 10.0 + safeLeftInset, y: halfH - 10.0)
    }
    
    // MARK: - Multi-Touch Event Handling
    
    /// Processes began touch events forwarded from GameScene.
    public func handleTouchesBegan(_ touches: Set<UITouch>, in scene: SKScene) {
        for touch in touches {
            let localPoint = touch.location(in: self)
            
            // 1. Check Virtual Joystick
            let distToJoy = hypot(localPoint.x - joystickCenter.x, localPoint.y - joystickCenter.y)
            if distToJoy <= joystickActivationRadius && joystickTouch == nil {
                joystickTouch = touch
                updateJoystickThumb(with: localPoint)
                continue
            }
            
            // 2. Check Action Buttons
            if jumpButton.contains(point: localPoint) && jumpButton.activeTouch == nil {
                jumpButton.touchBegan(touch: touch)
                playerController?.touchJumpRequested = true
                continue
            }
            
            if whipButton.contains(point: localPoint) && whipButton.activeTouch == nil {
                whipButton.touchBegan(touch: touch)
                playerController?.touchAttackRequested = true
                continue
            }
            
            if shootButton.contains(point: localPoint) && shootButton.activeTouch == nil {
                shootButton.touchBegan(touch: touch)
                playerController?.touchFireRequested = true
                continue
            }
            
            if reloadButton.contains(point: localPoint) && reloadButton.activeTouch == nil {
                reloadButton.touchBegan(touch: touch)
                playerController?.touchReloadRequested = true
                continue
            }
        }
        
        updateDebugDisplay(activeTouchCount: touches.count)
    }
    
    /// Processes moved touch events forwarded from GameScene.
    public func handleTouchesMoved(_ touches: Set<UITouch>, in scene: SKScene) {
        for touch in touches {
            let localPoint = touch.location(in: self)
            
            // 1. Update Joystick if active
            if touch === joystickTouch {
                updateJoystickThumb(with: localPoint)
            }
            
            // 2. Update Buttons (cancel if dragged far outside)
            if touch === jumpButton.activeTouch {
                if !jumpButton.isWithinCancelDistance(point: localPoint) {
                    jumpButton.touchEnded()
                }
            }
            if touch === whipButton.activeTouch {
                if !whipButton.isWithinCancelDistance(point: localPoint) {
                    whipButton.touchEnded()
                }
            }
            if touch === shootButton.activeTouch {
                if !shootButton.isWithinCancelDistance(point: localPoint) {
                    shootButton.touchEnded()
                }
            }
            if touch === reloadButton.activeTouch {
                if !reloadButton.isWithinCancelDistance(point: localPoint) {
                    reloadButton.touchEnded()
                }
            }
        }
        
        updateDebugDisplay(activeTouchCount: touches.count)
    }
    
    /// Processes ended touch events forwarded from GameScene.
    public func handleTouchesEnded(_ touches: Set<UITouch>, in scene: SKScene) {
        for touch in touches {
            // 1. Release Joystick
            if touch === joystickTouch {
                releaseJoystick()
            }
            
            // 2. Release Buttons
            if touch === jumpButton.activeTouch {
                jumpButton.touchEnded()
            }
            if touch === whipButton.activeTouch {
                whipButton.touchEnded()
            }
            if touch === shootButton.activeTouch {
                shootButton.touchEnded()
            }
            if touch === reloadButton.activeTouch {
                reloadButton.touchEnded()
            }
        }
        
        updateDebugDisplay(activeTouchCount: touches.count)
    }
    
    /// Processes cancelled touch events (e.g. system gesture interruption).
    public func handleTouchesCancelled(_ touches: Set<UITouch>, in scene: SKScene) {
        handleTouchesEnded(touches, in: scene)
    }
    
    // MARK: - Joystick Math & Updates
    
    /// Updates the joystick thumb knob position and outputs normalized horizontal axis (-1.0 ... +1.0).
    private func updateJoystickThumb(with touchPoint: CGPoint) {
        let dx = touchPoint.x - joystickCenter.x
        let dy = touchPoint.y - joystickCenter.y
        let distance = hypot(dx, dy)
        
        if distance > 0.001 {
            let clampedDistance = min(distance, joystickMaxRadius)
            let angle = atan2(dy, dx)
            
            joystickThumb.position = CGPoint(
                x: joystickCenter.x + cos(angle) * clampedDistance,
                y: joystickCenter.y + sin(angle) * clampedDistance
            )
            
            // Calculate horizontal axis
            if abs(dx) > joystickDeadzone {
                let rawAxis = dx / joystickMaxRadius
                horizontalAxis = max(-1.0, min(1.0, rawAxis))
            } else {
                horizontalAxis = 0.0
            }
        } else {
            joystickThumb.position = joystickCenter
            horizontalAxis = 0.0
        }
        
        // Pass to PlayerController
        playerController?.touchInputDirection = horizontalAxis
    }
    
    /// Snaps the joystick thumb back to center and zeroes out input axis.
    private func releaseJoystick() {
        joystickTouch = nil
        horizontalAxis = 0.0
        playerController?.touchInputDirection = 0.0
        
        joystickThumb.removeAction(forKey: "recenter")
        let recenterAction = SKAction.move(to: joystickCenter, duration: 0.06)
        recenterAction.timingMode = .easeOut
        joystickThumb.run(recenterAction, withKey: "recenter")
    }
    
    // MARK: - State Management
    
    /// Resets all touch tracking states (e.g. on pause, level completion, player death).
    public func resetAllTouches() {
        releaseJoystick()
        jumpButton.touchEnded()
        whipButton.touchEnded()
        shootButton.touchEnded()
        reloadButton.touchEnded()
        
        playerController?.touchInputDirection = 0.0
        playerController?.touchJumpRequested = false
        playerController?.touchAttackRequested = false
        playerController?.touchFireRequested = false
        playerController?.touchReloadRequested = false
    }
    
    /// Sets whether touch controls are visually interactive.
    public func setControlsActive(_ active: Bool) {
        if !active {
            resetAllTouches()
            self.alpha = 0.25
        } else {
            self.alpha = 1.0
        }
    }
    
    // MARK: - Debug Display
    
    private func updateDebugDisplay(activeTouchCount: Int) {
        guard GameConfig.Debug.showPlayerDebug else { return }
        debugLabel.text = String(
            format: "Touch: Axis=%.2f | J:%@ W:%@ S:%@ R:%@",
            horizontalAxis,
            jumpButton.isPressed ? "ON" : "--",
            whipButton.isPressed ? "ON" : "--",
            shootButton.isPressed ? "ON" : "--",
            reloadButton.isPressed ? "ON" : "--"
        )
    }
}

// MARK: - TouchActionButton Sub-Node

/// Individual circular action button with retro styling and tactile press feedback.
private final class TouchActionButton: SKNode {
    
    let radius: CGFloat
    let shapeNode: SKShapeNode
    let labelNode: SKLabelNode
    
    private let baseFillColor: SKColor
    private let baseStrokeColor: SKColor
    private let pressedFillColor: SKColor
    private let pressedStrokeColor: SKColor
    
    public private(set) var isPressed: Bool = false
    public weak var activeTouch: UITouch?
    
    init(label: String,
         radius: CGFloat,
         fillColor: SKColor,
         strokeColor: SKColor,
         fontSize: CGFloat) {
        
        self.radius = radius
        self.baseFillColor = fillColor
        self.baseStrokeColor = strokeColor
        
        // Pressed colors (higher opacity highlight)
        self.pressedFillColor = fillColor.withAlphaComponent(min(1.0, 0.70))
        self.pressedStrokeColor = SKColor.white.withAlphaComponent(0.95)
        
        // Background Circle Shape
        shapeNode = SKShapeNode(circleOfRadius: radius)
        shapeNode.fillColor = fillColor
        shapeNode.strokeColor = strokeColor
        shapeNode.lineWidth = 2.0
        shapeNode.zPosition = 100
        
        // Text Label
        labelNode = SKLabelNode(fontNamed: "Menlo-Bold")
        labelNode.text = label
        labelNode.fontSize = fontSize
        labelNode.fontColor = SKColor(white: 0.95, alpha: 0.90)
        labelNode.horizontalAlignmentMode = .center
        labelNode.verticalAlignmentMode = .center
        labelNode.zPosition = 101
        
        super.init()
        self.zPosition = 100
        addChild(shapeNode)
        addChild(labelNode)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    /// Checks if a touch point falls within the comfortable touch activation radius.
    func contains(point: CGPoint) -> Bool {
        let dx = point.x - position.x
        let dy = point.y - position.y
        // Generous touch target (button radius + 10 pt padding)
        let touchRadius = radius + 10.0
        return (dx * dx + dy * dy) <= (touchRadius * touchRadius)
    }
    
    /// Checks if a moving touch is still reasonably close to the button.
    func isWithinCancelDistance(point: CGPoint) -> Bool {
        let dx = point.x - position.x
        let dy = point.y - position.y
        let cancelRadius = radius * 2.0
        return (dx * dx + dy * dy) <= (cancelRadius * cancelRadius)
    }
    
    /// Triggers visual button press feedback.
    func touchBegan(touch: UITouch) {
        self.activeTouch = touch
        self.isPressed = true
        
        shapeNode.fillColor = pressedFillColor
        shapeNode.strokeColor = pressedStrokeColor
        
        removeAction(forKey: "scale")
        let pressAction = SKAction.scale(to: 0.90, duration: 0.04)
        run(pressAction, withKey: "scale")
    }
    
    /// Restores visual appearance upon touch release or cancellation.
    func touchEnded() {
        self.activeTouch = nil
        self.isPressed = false
        
        shapeNode.fillColor = baseFillColor
        shapeNode.strokeColor = baseStrokeColor
        
        removeAction(forKey: "scale")
        let releaseAction = SKAction.scale(to: 1.0, duration: 0.06)
        run(releaseAction, withKey: "scale")
    }
}
