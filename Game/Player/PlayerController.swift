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
    private var jumpPressed: Bool = false
    
    /// Consumed flag prevents holding space from re-triggering jump every frame.
    private var jumpConsumed: Bool = false
    
    // MARK: - Computed Input
    
    /// Horizontal input direction: −1.0 (left), 0.0 (idle), +1.0 (right).
    public var inputDirection: CGFloat {
        var dir: CGFloat = 0.0
        if leftPressed  { dir -= 1.0 }
        if rightPressed { dir += 1.0 }
        return dir
    }
    
    /// Returns true exactly once per jump press (edge-triggered).
    public var jumpRequested: Bool {
        if jumpPressed && !jumpConsumed {
            jumpConsumed = true
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
        
        input.keyChangedHandler = { [weak self] _, key, _, pressed in
            self?.handleKeyChange(keyCode: key.keyCode, pressed: pressed)
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
            
        case .spacebar:
            jumpPressed = pressed
            if !pressed {
                jumpConsumed = false   // Reset consumed flag on key release
            }
            
        default:
            break
        }
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
}
