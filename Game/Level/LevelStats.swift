import Foundation

/// Lightweight current-session/current-level statistics tracking.
/// Stores collected coin counts and total available coins without using persistent storage.
public final class LevelStats: Sendable {
    
    /// Total number of coins collected in the current level.
    public private(set) var coinsCollected: Int = 0
    
    /// Total number of coins available in the level.
    public private(set) var totalCoins: Int = 0
    
    public init() {}
    
    /// Registers available total coins at level generation.
    public func setTotalCoins(_ count: Int) {
        self.totalCoins = count
    }
    
    /// Increments collected coin count.
    public func recordCoinCollected(value: Int = 1) {
        self.coinsCollected += value
    }
    
    /// Resets statistics for level restart.
    public func reset() {
        self.coinsCollected = 0
        self.totalCoins = 0
    }
}
