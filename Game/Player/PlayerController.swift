import SpriteKit
import GameController

/// Processes keyboard input and translates it into movement commands for the Player.
///
/// Uses GCKeyboard (Game Controller framework) for hardware keyboard detection on iOS,
/// with an SKScene key-press fallback for macOS Catalyst / simulator testing.
public final class PlayerController {
    
    // MARK: - Input State
    
    /// Tracks which movement keys are currently held down.
    private var leftPressed: Bool = false
    private var rightPressed: Bool = false
    private var upPressed: Bool = false
    private var downPressed: Bool = false
    private var jumpPressed: Bool = false
    private var attackPressed: Bool = false
    private var firePressed: Bool = false
    private var reloadPressed: Bool = false
    public private(set) var isAiming: Bool = false
    
    /// Consumed flags prevent holding keys from re-triggering actions every frame.
    private var jumpConsumed: Bool = false
    private var attackConsumed: Bool = false
    private var fireConsumed: Bool = false
    private var reloadConsumed: Bool = false
    
    // MARK: - Touch Input State
    
    /// On-screen virtual joystick horizontal axis (-1.0 to +1.0).
    public var touchInputDirection: CGFloat = 0.0
    
    /// On-screen virtual joystick vertical axis (-1.0 to +1.0).
    public var touchVerticalDirection: CGFloat = 0.0
    
    /// Edge-triggered touch action flags.
    public var touchJumpRequested: Bool = false
    public var touchAttackRequested: Bool = false
    public var touchFireRequested: Bool = false
    public var touchReloadRequested: Bool = false
    
    // MARK: - Computed Input
    
    /// Horizontal input direction: −1.0 (left), 0.0 (idle), +1.0 (right).
    public var inputDirection: CGFloat {
        var dir: CGFloat = 0.0
        if leftPressed  { dir -= 1.0 }
        if rightPressed { dir += 1.0 }
        if abs(touchInputDirection) > 0.01 {
            dir += touchInputDirection
        }
        return max(-1.0, min(1.0, dir))
    }
    
    /// Vertical input direction: -1.0 (down), 0.0 (neutral), +1.0 (up).
    public var verticalDirection: CGFloat {
        var dir: CGFloat = 0.0
        if downPressed { dir -= 1.0 }
        if upPressed   { dir += 1.0 }
        if abs(touchVerticalDirection) > 0.01 {
            dir += touchVerticalDirection
        }
        return max(-1.0, min(1.0, dir))
    }
    
    /// Returns true exactly once per jump press (edge-triggered).
    public var jumpRequested: Bool {
        if (jumpPressed && !jumpConsumed) || touchJumpRequested {
            jumpConsumed = true
            touchJumpRequested = false
            return true
        }
        return false
    }
    
    /// Returns true exactly once per whip attack press (edge-triggered via J or X).
    public var attackRequested: Bool {
        if (attackPressed && !attackConsumed) || touchAttackRequested {
            attackConsumed = true
            touchAttackRequested = false
            return true
        }
        return false
    }
    
    /// Returns true exactly once per revolver fire press (edge-triggered via K).
    public var fireRequested: Bool {
        if (firePressed && !fireConsumed) || touchFireRequested {
            fireConsumed = true
            touchFireRequested = false
            return true
        }
        return false
    }
    
    /// Returns true exactly once per reload press (edge-triggered via R).
    public var reloadRequested: Bool {
        if (reloadPressed && !reloadConsumed) || touchReloadRequested {
            reloadConsumed = true
            touchReloadRequested = false
            return true
        }
        return false
    }
    
    // MARK: - Initialization
    
    public init() {
        setupKeyboardObserver()
    }
    
    // MARK: - GCKeyboard Observer (iOS hardware keyboard)
    
    private func setupKeyboardObserver() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(keyboardDidConnect(_:)),
            name: .GCKeyboardDidConnect,
            object: nil
        )
        // If a keyboard is already connected at launch
        if let keyboard = GCKeyboard.coalesced {
            observeKeyboard(keyboard)
        }
    }
    
    @objc private func keyboardDidConnect(_ notification: Notification) {
        guard let keyboard = notification.object as? GCKeyboard else { return }
        observeKeyboard(keyboard)
    }
    
    private func observeKeyboard(_ keyboard: GCKeyboard) {
        guard let input = keyboard.keyboardInput else { return }
        
        input.keyChangedHandler = { [weak self] _, _, keyCode, pressed in
            self?.handleKeyChange(keyCode: keyCode, pressed: pressed)
        }
    }
    
    // MARK: - SKScene Key Events (macOS Catalyst / Simulator)
    
    #if targetEnvironment(macCatalyst) || os(macOS)
    /// Forward key-down events from GameScene.
    public func keyDown(keyCode: UInt16) {
        mapSceneKey(keyCode: keyCode, pressed: true)
    }
    
    /// Forward key-up events from GameScene.
    public func keyUp(keyCode: UInt16) {
        mapSceneKey(keyCode: keyCode, pressed: false)
    }
    
    private func mapSceneKey(keyCode: UInt16, pressed: Bool) {
        // macOS virtual key codes
        switch keyCode {
        case 0:   handleKeyChange(keyCode: .keyA, pressed: pressed)          // A
        case 2:   handleKeyChange(keyCode: .keyD, pressed: pressed)          // D
        case 7:   handleKeyChange(keyCode: .keyX, pressed: pressed)          // X (Whip)
        case 15:  handleKeyChange(keyCode: .keyR, pressed: pressed)          // R (Reload)
        case 37:  handleKeyChange(keyCode: .keyL, pressed: pressed)          // L (Aim)
        case 38:  handleKeyChange(keyCode: .keyJ, pressed: pressed)          // J (Whip)
        case 40:  handleKeyChange(keyCode: .keyK, pressed: pressed)          // K (Fire Revolver)
        case 49:  handleKeyChange(keyCode: .spacebar, pressed: pressed)      // Space
        case 123: handleKeyChange(keyCode: .leftArrow, pressed: pressed)     // Left Arrow
        case 124: handleKeyChange(keyCode: .rightArrow, pressed: pressed)    // Right Arrow
        default: break
        }
    }
    #endif
    
    // MARK: - Unified Key Handler
    
    private func handleKeyChange(keyCode: GCKeyCode, pressed: Bool) {
        switch keyCode {
        case .keyA, .leftArrow:
            leftPressed = pressed
            
        case .keyD, .rightArrow:
            rightPressed = pressed
            
        case .keyW, .upArrow:
            upPressed = pressed
            
        case .keyS, .downArrow:
            downPressed = pressed
            
        case .spacebar:
            jumpPressed = pressed
            if !pressed {
                jumpConsumed = false   // Reset consumed flag on key release
            }
            
        case .keyJ, .keyX:
            attackPressed = pressed
            if !pressed {
                attackConsumed = false // Reset consumed flag on key release
            }
            
        case .keyK:
            firePressed = pressed
            if !pressed {
                fireConsumed = false   // Reset consumed flag on key release
            }
            
        case .keyR:
            reloadPressed = pressed
            if !pressed {
                reloadConsumed = false // Reset consumed flag on key release
            }
            
        case .keyL:
            isAiming = pressed
            
        default:
            break
        }
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
}
