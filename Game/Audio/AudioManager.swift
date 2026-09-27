import Foundation
import AVFoundation

/// Centralized sound effect identifier mapping logical gameplay events
/// directly to the 16 discovered audio files located in Assets/Audio.
public enum SoundEffect: String, CaseIterable, Sendable {
    case playerJump     = "player_jump.wav"
    case playerLand     = "player_land.wav"
    case playerHurt     = "player_hurt.wav"
    case whipAttack     = "whip_attack.wav"
    case whipImpact     = "whip_impact.wav"
    case revolverFire   = "revolver_fire.wav"
    case revolverReload = "revolver_reload.wav"
    case bulletImpact   = "bullet_impact.wav"
    case snakeAttack    = "snake_attack.wav"
    case snakeHurt      = "snake_hurt.wav"
    case snakeDeath     = "snake_death.wav"
    case coinCollect    = "coin_collect.wav"
    case exitActivate   = "exit_activate.wav"
    case levelComplete  = "level_complete.wav"
    case uiClick        = "ui_click.wav"
    case uiPause        = "ui_pause.wav"
    
    /// File basename without extension.
    public var baseName: String {
        (rawValue as NSString).deletingPathExtension
    }
    
    /// File extension.
    public var fileExtension: String {
        (rawValue as NSString).pathExtension
    }
}

/// Centralized audio manager managing lightweight sound effect playback for Cave Ranger.
///
/// Features:
/// - Pre-warmed audio player pool supporting natural sound overlaps without memory leaks.
/// - Master and SFX volume controls.
/// - Missing-file safety preventing game crashes on missing or corrupted audio assets.
/// - Audio session ambient mode configuration so background music from other apps is respected.
public final class AudioManager: NSObject {
    
    // MARK: - Singleton Instance
    
    public static let shared = AudioManager()
    
    // MARK: - Volume Configuration
    
    /// Global master volume multiplier (0.0 ... 1.0).
    public var masterVolume: Float = 1.0 {
        didSet { updateActivePlayerVolumes() }
    }
    
    /// Sound effects volume multiplier (0.0 ... 1.0).
    public var sfxVolume: Float = 1.0 {
        didSet { updateActivePlayerVolumes() }
    }
    
    /// Effective sound effect volume output.
    public var effectiveSFXVolume: Float {
        max(0.0, min(1.0, masterVolume * sfxVolume))
    }
    
    // MARK: - Audio Pool & Cache
    
    /// Maximum concurrent audio player instances per sound effect to prevent spam/runaway allocations.
    private let maxInstancesPerSound: Int = 3
    
    /// Cached audio player pool organized by sound effect enum.
    private var playerPool: [SoundEffect: [AVAudioPlayer]] = [:]
    
    /// Set of sound file names that failed to load, preventing log spam.
    private var failedSoundWarnings: Set<String> = []
    
    /// Lock for thread-safe access to player pools.
    private let lock = NSLock()
    
    // MARK: - Initialization
    
    private override init() {
        super.init()
        setupAudioSession()
        preloadCommonSounds()
    }
    
    // MARK: - Audio Session Configuration
    
    private func setupAudioSession() {
        #if os(iOS)
        do {
            try AVAudioSession.sharedInstance().setCategory(.ambient, mode: .default, options: [.mixWithOthers])
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            if GameConfig.Debug.showPlayerDebug {
                print("[AUDIO] Failed to configure AVAudioSession: \(error.localizedDescription)")
            }
        }
        #endif
    }
    
    // MARK: - Sound Preloading
    
    /// Preloads high-frequency sounds to ensure zero-latency initial playback.
    private func preloadCommonSounds() {
        let frequentSounds: [SoundEffect] = [
            .playerJump, .playerLand, .playerHurt,
            .whipAttack, .whipImpact,
            .revolverFire, .revolverReload, .bulletImpact,
            .coinCollect, .uiClick, .uiPause
        ]
        for sound in frequentSounds {
            _ = createPlayer(for: sound)
        }
    }
    
    // MARK: - SFX Playback API
    
    /// Plays a registered sound effect with an optional custom relative volume.
    public func playSFX(_ sound: SoundEffect, volume: Float = 1.0) {
        guard effectiveSFXVolume > 0.001 else { return }
        
        lock.lock()
        defer { lock.unlock() }
        
        var players = playerPool[sound] ?? []
        
        // 1. Find an idle player in the existing pool
        if let idlePlayer = players.first(where: { !$0.isPlaying }) {
            idlePlayer.currentTime = 0
            idlePlayer.volume = effectiveSFXVolume * max(0.0, min(1.0, volume))
            idlePlayer.play()
            return
        }
        
        // 2. If pool size is under limit, create a new instance
        if players.count < maxInstancesPerSound {
            if let newPlayer = createPlayer(for: sound) {
                newPlayer.volume = effectiveSFXVolume * max(0.0, min(1.0, volume))
                newPlayer.play()
                players.append(newPlayer)
                playerPool[sound] = players
                return
            }
        }
        
        // 3. If pool is full, reuse the player with the furthest playback progress
        if let oldestPlayer = players.first {
            oldestPlayer.currentTime = 0
            oldestPlayer.volume = effectiveSFXVolume * max(0.0, min(1.0, volume))
            oldestPlayer.play()
        }
    }
    
    /// Plays a sound effect by raw filename string.
    public func playSFX(named fileName: String, volume: Float = 1.0) {
        if let sound = SoundEffect(rawValue: fileName) {
            playSFX(sound, volume: volume)
        } else if let sound = SoundEffect.allCases.first(where: { $0.baseName == fileName }) {
            playSFX(sound, volume: volume)
        } else {
            warnMissing(fileName: fileName)
        }
    }
    
    /// Stops all playing instances of a specific sound effect.
    public func stopSFX(_ sound: SoundEffect) {
        lock.lock()
        defer { lock.unlock() }
        
        if let players = playerPool[sound] {
            for player in players where player.isPlaying {
                player.stop()
                player.currentTime = 0
            }
        }
    }
    
    /// Stops all currently playing sound effects across all categories.
    public func stopAllSFX() {
        lock.lock()
        defer { lock.unlock() }
        
        for (_, players) in playerPool {
            for player in players where player.isPlaying {
                player.stop()
                player.currentTime = 0
            }
        }
    }
    
    /// Pauses all currently active audio players (e.g. on GameState == .paused).
    public func pauseAllSFX() {
        lock.lock()
        defer { lock.unlock() }
        
        for (_, players) in playerPool {
            for player in players where player.isPlaying {
                player.pause()
            }
        }
    }
    
    /// Resumes active audio players when returning from pause state.
    public func resumeAllSFX() {
        lock.lock()
        defer { lock.unlock() }
        
        for (_, players) in playerPool {
            for player in players where !player.isPlaying && player.currentTime > 0 {
                player.play()
            }
        }
    }
    
    // MARK: - Player Factory & Resource Resolution
    
    private func createPlayer(for sound: SoundEffect) -> AVAudioPlayer? {
        guard let url = resolveAudioURL(for: sound) else {
            warnMissing(fileName: sound.rawValue)
            return nil
        }
        
        do {
            let player = try AVAudioPlayer(contentsOf: url)
            player.prepareToPlay()
            player.volume = effectiveSFXVolume
            return player
        } catch {
            if !failedSoundWarnings.contains(sound.rawValue) {
                failedSoundWarnings.insert(sound.rawValue)
                if GameConfig.Debug.showPlayerDebug {
                    print("[AUDIO] Failed to initialize audio player for \(sound.rawValue): \(error.localizedDescription)")
                }
            }
            return nil
        }
    }
    
    /// Resolves file URL for a sound across app bundle locations and asset folders.
    private func resolveAudioURL(for sound: SoundEffect) -> URL? {
        let name = sound.baseName
        let ext = sound.fileExtension
        
        // 1. Direct bundle resource with subpath Assets/Audio
        if let url = Bundle.main.url(forResource: name, withExtension: ext, subdirectory: "Assets/Audio") {
            return url
        }
        
        // 2. Direct bundle resource with subpath Audio
        if let url = Bundle.main.url(forResource: name, withExtension: ext, subdirectory: "Audio") {
            return url
        }
        
        // 3. Root bundle resource
        if let url = Bundle.main.url(forResource: name, withExtension: ext) {
            return url
        }
        
        // 4. Fallback search via full filename in main bundle
        if let url = Bundle.main.url(forResource: sound.rawValue, withExtension: nil) {
            return url
        }
        
        return nil
    }
    
    private func warnMissing(fileName: String) {
        if !failedSoundWarnings.contains(fileName) {
            failedSoundWarnings.insert(fileName)
            if GameConfig.Debug.showPlayerDebug {
                print("[AUDIO WARNING] Audio file not found in bundle: \(fileName)")
            }
        }
    }
    
    private func updateActivePlayerVolumes() {
        lock.lock()
        defer { lock.unlock() }
        
        let vol = effectiveSFXVolume
        for (_, players) in playerPool {
            for player in players {
                player.volume = vol
            }
        }
    }
}
