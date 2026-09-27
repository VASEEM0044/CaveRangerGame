import Foundation

/// Persistent progression and statistics model for Cave Ranger.
///
/// Fully `Codable` and designed for `UserDefaults` storage.
/// Supports multiple level records by level ID (e.g. "mine_01").
public struct SaveData: Codable, Equatable, Sendable {
    
    /// Schema version for future save data migrations.
    public var gameVersion: String
    
    /// List of completed level IDs (e.g. ["mine_01"]).
    public var completedLevels: [String]
    
    /// Total aggregate coins collected across all completions or lifetime bests.
    public var totalCoinsCollected: Int
    
    /// Map of level ID to best completion time in seconds (faster time = lower value).
    public var bestLevelTime: [String: TimeInterval]
    
    /// Map of level ID to best coins collected in a single run (e.g. ["mine_01": 18]).
    public var bestCoinsCollected: [String: Int]
    
    /// Numerical index or count of highest completed level for progression unlocking.
    public var highestCompletedLevel: Int
    
    // MARK: - Default Initializer
    
    public init(
        gameVersion: String = "1.0",
        completedLevels: [String] = [],
        totalCoinsCollected: Int = 0,
        bestLevelTime: [String: TimeInterval] = [:],
        bestCoinsCollected: [String: Int] = [:],
        highestCompletedLevel: Int = 0
    ) {
        self.gameVersion = gameVersion
        self.completedLevels = completedLevels
        self.totalCoinsCollected = totalCoinsCollected
        self.bestLevelTime = bestLevelTime
        self.bestCoinsCollected = bestCoinsCollected
        self.highestCompletedLevel = highestCompletedLevel
    }
    
    /// Provides clean initial state for a fresh game session.
    public static var `default`: SaveData {
        SaveData(
            gameVersion: "1.0",
            completedLevels: [],
            totalCoinsCollected: 0,
            bestLevelTime: [:],
            bestCoinsCollected: [:],
            highestCompletedLevel: 0
        )
    }
}
