import Foundation

/// Primary game states for session management and scene state machine transitions.
public enum GameState: String, CaseIterable, Sendable {
    case playing = "PLAYING"
    case paused = "PAUSED"
    case levelComplete = "LEVEL_COMPLETE"
    case playerDead = "PLAYER_DEAD"
}

/// Observer protocol for receiving state transition callbacks.
public protocol GameStateDelegate: AnyObject {
    func gameStateDidChange(from oldState: GameState, to newState: GameState)
}

/// Central state manager controlling transitions between GameState values.
public final class GameStateManager {
    
    /// The current state of the game.
    public private(set) var currentState: GameState
    
    /// Delegate to be notified of valid state changes.
    public weak var delegate: GameStateDelegate?
    
    public init(initialState: GameState = .playing) {
        self.currentState = initialState
    }
    
    /// Validates whether a proposed transition from the current state to targetState is allowed.
    public func canTransition(to targetState: GameState) -> Bool {
        guard currentState != targetState else { return false }
        
        switch (currentState, targetState) {
        case (.playing, .paused),
             (.playing, .levelComplete),
             (.playing, .playerDead):
            return true
            
        case (.paused, .playing):
            return true
            
        case (.levelComplete, .playing),
             (.playerDead, .playing):
            // Allows restarting or progressing to the next level
            return true
            
        default:
            return false
        }
    }
    
    /// Transitions to the target state if valid, notifying the delegate.
    @discardableResult
    public func transition(to targetState: GameState) -> Bool {
        guard canTransition(to: targetState) else { return false }
        
        let previousState = currentState
        currentState = targetState
        delegate?.gameStateDidChange(from: previousState, to: targetState)
        return true
    }
}
