import Foundation

/// Centralized manager for persistent game progression and statistics.
///
/// Handles saving and loading `SaveData` via `UserDefaults`.
/// Resilient against corrupted or unreadable data, with fallback to default values.
public final class SaveManager: @unchecked Sendable {
    
    // MARK: - Singleton
    
    public static let shared = SaveManager()
    
    // MARK: - Storage Keys
    
    private let storageKey = "com.vntm.caverangerx.savedata"
    private let userDefaults: UserDefaults
    
    // MARK: - Active Save State
    
    public private(set) var currentSave: SaveData
    
    // MARK: - Initialization
    
    public init(userDefaults: UserDefaults = .standard) {
        self.userDefaults = userDefaults
        self.currentSave = SaveData.default
        load()
    }
    
    // MARK: - Load & Save
    
    /// Loads saved game data from UserDefaults. Recovers safely if corrupted or missing.
    @discardableResult
    public func load() -> SaveData {
        guard let data = userDefaults.data(forKey: storageKey) else {
            #if DEBUG
            print("[SAVE] Loaded (Default - No existing save found)")
            #endif
            self.currentSave = SaveData.default
            return self.currentSave
        }
        
        do {
            let decoder = JSONDecoder()
            let decodedSave = try decoder.decode(SaveData.self, from: data)
            self.currentSave = decodedSave
            #if DEBUG
            print("[SAVE] Loaded successfully (Version: \(decodedSave.gameVersion), Completed: \(decodedSave.completedLevels.count))")
            #endif
            return self.currentSave
        } catch {
            #if DEBUG
            print("[SAVE] Invalid save recovered (Error: \(error.localizedDescription)). Resetting to default data.")
            #endif
            self.currentSave = SaveData.default
            return self.currentSave
        }
    }
    
    /// Persists current save state to UserDefaults.
    @discardableResult
    public func save() -> Bool {
        do {
            let encoder = JSONEncoder()
            let encodedData = try encoder.encode(currentSave)
            userDefaults.set(encodedData, forKey: storageKey)
            #if DEBUG
            print("[SAVE] Saved successfully to UserDefaults")
            #endif
            return true
        } catch {
            #if DEBUG
            print("[SAVE] Failed to encode SaveData: \(error.localizedDescription)")
            #endif
            return false
        }
    }
    
    // MARK: - Level Completion & Records
    
    /// Result payload describing record updates on level completion.
    public struct LevelCompletionResult: Sendable {
        public let isFirstCompletion: Bool
        public let isNewBestTime: Bool
        public let isNewBestCoins: Bool
        public let previousBestTime: TimeInterval?
        public let currentBestTime: TimeInterval
        public let previousBestCoins: Int?
        public let currentBestCoins: Int
    }
    
    /// Records a level completion with coin count and elapsed time.
    /// Updates best time and best coins only if improved.
    @discardableResult
    public func markLevelCompleted(levelID: String, coins: Int, time: TimeInterval) -> LevelCompletionResult {
        let isFirstCompletion = !currentSave.completedLevels.contains(levelID)
        if isFirstCompletion {
            currentSave.completedLevels.append(levelID)
        }
        
        // 1. Time record comparison
        let prevTime = currentSave.bestLevelTime[levelID]
        let isNewBestTime: Bool
        let finalBestTime: TimeInterval
        
        if let existingBestTime = prevTime {
            if time < existingBestTime {
                currentSave.bestLevelTime[levelID] = time
                isNewBestTime = true
                finalBestTime = time
                #if DEBUG
                print("[SAVE] New best time for \(levelID): \(String(format: "%.2f", time))s (Previous: \(String(format: "%.2f", existingBestTime))s)")
                #endif
            } else {
                isNewBestTime = false
                finalBestTime = existingBestTime
            }
        } else {
            currentSave.bestLevelTime[levelID] = time
            isNewBestTime = true
            finalBestTime = time
            #if DEBUG
            print("[SAVE] First completion time for \(levelID): \(String(format: "%.2f", time))s")
            #endif
        }
        
        // 2. Coin record comparison
        let prevCoins = currentSave.bestCoinsCollected[levelID]
        let isNewBestCoins: Bool
        let finalBestCoins: Int
        
        if let existingBestCoins = prevCoins {
            if coins > existingBestCoins {
                currentSave.bestCoinsCollected[levelID] = coins
                isNewBestCoins = true
                finalBestCoins = coins
                #if DEBUG
                print("[SAVE] New best coins for \(levelID): \(coins) (Previous: \(existingBestCoins))")
                #endif
            } else {
                isNewBestCoins = false
                finalBestCoins = existingBestCoins
            }
        } else {
            currentSave.bestCoinsCollected[levelID] = coins
            isNewBestCoins = true
            finalBestCoins = coins
            #if DEBUG
            print("[SAVE] First completion coins for \(levelID): \(coins)")
            #endif
        }
        
        // 3. Update lifetime total coins collected
        let totalBest = currentSave.bestCoinsCollected.values.reduce(0, +)
        currentSave.totalCoinsCollected = totalBest
        
        // 4. Update highest completed level
        currentSave.highestCompletedLevel = currentSave.completedLevels.count
        
        #if DEBUG
        print("[SAVE] Level completed: \(levelID)")
        #endif
        
        // Persist updates
        save()
        
        return LevelCompletionResult(
            isFirstCompletion: isFirstCompletion,
            isNewBestTime: isNewBestTime,
            isNewBestCoins: isNewBestCoins,
            previousBestTime: prevTime,
            currentBestTime: finalBestTime,
            previousBestCoins: prevCoins,
            currentBestCoins: finalBestCoins
        )
    }
    
    // MARK: - Query API
    
    /// Returns the best completion time in seconds for a given level ID, if completed.
    public func bestTime(for levelID: String) -> TimeInterval? {
        return currentSave.bestLevelTime[levelID]
    }
    
    /// Returns the highest coin count collected in a single run for a given level ID.
    public func bestCoins(for levelID: String) -> Int? {
        return currentSave.bestCoinsCollected[levelID]
    }
    
    /// Returns whether the given level ID has been completed at least once.
    public func isLevelCompleted(levelID: String) -> Bool {
        return currentSave.completedLevels.contains(levelID)
    }
    
    // MARK: - Reset API
    
    /// Resets all saved progression and restores default state in memory and storage.
    public func resetProgress() {
        self.currentSave = SaveData.default
        userDefaults.removeObject(forKey: storageKey)
        #if DEBUG
        print("[SAVE] Save reset to defaults")
        #endif
    }
}
