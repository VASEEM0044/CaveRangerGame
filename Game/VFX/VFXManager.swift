import SpriteKit

/// Centralized lightweight retro pixel-art visual effects manager.
///
/// Features:
/// - Fast programmatic square pixel particle bursts (5–15 particles per effect).
/// - Guaranteed automatic memory cleanup using SKAction lifecycle sequences.
/// - Zero external dependencies or heavy shader requirements.
/// - Designed for 60 FPS performance on iOS devices.
public enum VFXManager {
    
    // MARK: - Dust Effects (Jump & Land)
    
    /// Spawns small retro square dust particles at feet position upon jumping or landing.
    public static func createDustPuff(at position: CGPoint, in parent: SKNode, particleCount: Int = 6) {
        let container = SKNode()
        container.position = position
        container.zPosition = 8
        parent.addChild(container)
        
        let colors = [
            SKColor(red: 0.40, green: 0.35, blue: 0.32, alpha: 0.85),
            SKColor(red: 0.50, green: 0.45, blue: 0.40, alpha: 0.75),
            SKColor(red: 0.30, green: 0.25, blue: 0.22, alpha: 0.65)
        ]
        
        for i in 0..<particleCount {
            let size = CGFloat.random(in: 2.5...4.5)
            let particle = SKShapeNode(rectOf: CGSize(width: size, height: size))
            particle.fillColor = colors[i % colors.count]
            particle.strokeColor = .clear
            
            let spreadX = CGFloat.random(in: -18.0...18.0)
            let spreadY = CGFloat.random(in: 4.0...14.0)
            let duration = Double.random(in: 0.18...0.30)
            
            container.addChild(particle)
            
            let moveAction = SKAction.moveBy(x: spreadX, y: spreadY, duration: duration)
            moveAction.timingMode = .easeOut
            let fadeAction = SKAction.fadeOut(withDuration: duration)
            let scaleAction = SKAction.scale(to: 0.2, duration: duration)
            let group = SKAction.group([moveAction, fadeAction, scaleAction])
            
            particle.run(group)
        }
        
        // Auto remove container node
        container.run(SKAction.sequence([
            SKAction.wait(forDuration: 0.35),
            SKAction.removeFromParent()
        ]))
    }
    
    // MARK: - Combat Impact Bursts (Whip & Bullet)
    
    /// Spawns a sharp pixel impact burst on weapon hits.
    public static func createImpactBurst(at position: CGPoint,
                                         in parent: SKNode,
                                         color: SKColor = SKColor(red: 1.0, green: 0.85, blue: 0.30, alpha: 1.0),
                                         particleCount: Int = 8) {
        let container = SKNode()
        container.position = position
        container.zPosition = 15
        parent.addChild(container)
        
        // Central brief flash square
        let flashBox = SKShapeNode(rectOf: CGSize(width: 8.0, height: 8.0))
        flashBox.fillColor = .white
        flashBox.strokeColor = color
        flashBox.lineWidth = 1.0
        container.addChild(flashBox)
        flashBox.run(SKAction.sequence([
            SKAction.scale(to: 1.5, duration: 0.05),
            SKAction.fadeOut(withDuration: 0.08),
            SKAction.removeFromParent()
        ]))
        
        // Radiating square pixel sparks
        for _ in 0..<particleCount {
            let sparkSize = CGFloat.random(in: 2.0...3.5)
            let spark = SKShapeNode(rectOf: CGSize(width: sparkSize, height: sparkSize))
            spark.fillColor = color
            spark.strokeColor = .clear
            container.addChild(spark)
            
            let angle = CGFloat.random(in: 0...(2 * .pi))
            let speed = CGFloat.random(in: 25.0...60.0)
            let dx = cos(angle) * speed
            let dy = sin(angle) * speed
            let duration = Double.random(in: 0.12...0.22)
            
            let moveAction = SKAction.moveBy(x: dx, y: dy, duration: duration)
            moveAction.timingMode = .easeOut
            let fadeAction = SKAction.fadeOut(withDuration: duration)
            let group = SKAction.group([moveAction, fadeAction])
            
            spark.run(group)
        }
        
        container.run(SKAction.sequence([
            SKAction.wait(forDuration: 0.25),
            SKAction.removeFromParent()
        ]))
    }
    
    // MARK: - Coin Sparkle Burst
    
    /// Spawns a golden pixel sparkle burst on coin pickup.
    public static func createCoinSparkles(at position: CGPoint, in parent: SKNode, particleCount: Int = 10) {
        let container = SKNode()
        container.position = position
        container.zPosition = 12
        parent.addChild(container)
        
        let goldColors = [
            SKColor(red: 1.0, green: 0.90, blue: 0.20, alpha: 0.95),
            SKColor(red: 1.0, green: 0.75, blue: 0.10, alpha: 0.90),
            SKColor(white: 1.0, alpha: 0.95)
        ]
        
        for i in 0..<particleCount {
            let size = CGFloat.random(in: 2.0...4.0)
            let sparkle = SKShapeNode(rectOf: CGSize(width: size, height: size))
            sparkle.fillColor = goldColors[i % goldColors.count]
            sparkle.strokeColor = .clear
            container.addChild(sparkle)
            
            let angle = CGFloat.random(in: 0...(2 * .pi))
            let distance = CGFloat.random(in: 12.0...32.0)
            let dx = cos(angle) * distance
            let dy = sin(angle) * distance + 8.0 // Slight upward drift
            let duration = Double.random(in: 0.20...0.35)
            
            let moveAction = SKAction.moveBy(x: dx, y: dy, duration: duration)
            moveAction.timingMode = .easeOut
            let fadeAction = SKAction.fadeOut(withDuration: duration)
            let scaleAction = SKAction.scale(to: 0.1, duration: duration)
            let group = SKAction.group([moveAction, fadeAction, scaleAction])
            
            sparkle.run(group)
        }
        
        container.run(SKAction.sequence([
            SKAction.wait(forDuration: 0.40),
            SKAction.removeFromParent()
        ]))
    }
    
    // MARK: - Exit & Level Completion VFX
    
    /// Spawns rising energy pixel wisps when the mine exit portal activates.
    public static func createExitActivationBurst(at position: CGPoint, in parent: SKNode, particleCount: Int = 12) {
        let container = SKNode()
        container.position = position
        container.zPosition = 6
        parent.addChild(container)
        
        let energyColors = [
            SKColor(red: 0.30, green: 0.85, blue: 1.0, alpha: 0.85),
            SKColor(red: 0.70, green: 0.40, blue: 1.0, alpha: 0.80),
            SKColor(white: 1.0, alpha: 0.90)
        ]
        
        for i in 0..<particleCount {
            let size = CGFloat.random(in: 3.0...5.0)
            let p = SKShapeNode(rectOf: CGSize(width: size, height: size))
            p.fillColor = energyColors[i % energyColors.count]
            p.strokeColor = .clear
            container.addChild(p)
            
            let startX = CGFloat.random(in: -20.0...20.0)
            p.position = CGPoint(x: startX, y: CGFloat.random(in: -10.0...10.0))
            
            let upwardRise = CGFloat.random(in: 30.0...60.0)
            let horizontalWiggle = CGFloat.random(in: -10.0...10.0)
            let duration = Double.random(in: 0.40...0.70)
            
            let moveAction = SKAction.moveBy(x: horizontalWiggle, y: upwardRise, duration: duration)
            moveAction.timingMode = .easeInEaseOut
            let fadeAction = SKAction.fadeOut(withDuration: duration)
            let group = SKAction.group([moveAction, fadeAction])
            
            p.run(group)
        }
        
        container.run(SKAction.sequence([
            SKAction.wait(forDuration: 0.75),
            SKAction.removeFromParent()
        ]))
    }
    
    /// Spawns a festive retro pixel confetti burst on level completion.
    public static func createLevelCompleteBurst(at position: CGPoint, in parent: SKNode, particleCount: Int = 16) {
        let container = SKNode()
        container.position = position
        container.zPosition = 100
        parent.addChild(container)
        
        let confettiColors = [
            SKColor(red: 1.0, green: 0.85, blue: 0.20, alpha: 1.0),
            SKColor(red: 0.30, green: 0.85, blue: 0.50, alpha: 1.0),
            SKColor(red: 0.40, green: 0.75, blue: 1.0, alpha: 1.0),
            SKColor(red: 1.0, green: 0.45, blue: 0.45, alpha: 1.0)
        ]
        
        for i in 0..<particleCount {
            let size = CGFloat.random(in: 3.5...6.0)
            let p = SKShapeNode(rectOf: CGSize(width: size, height: size))
            p.fillColor = confettiColors[i % confettiColors.count]
            p.strokeColor = .clear
            container.addChild(p)
            
            let angle = CGFloat.random(in: 0...(2 * .pi))
            let distance = CGFloat.random(in: 35.0...80.0)
            let dx = cos(angle) * distance
            let dy = sin(angle) * distance + 20.0
            let duration = Double.random(in: 0.35...0.60)
            
            let moveAction = SKAction.moveBy(x: dx, y: dy, duration: duration)
            moveAction.timingMode = .easeOut
            let fadeAction = SKAction.fadeOut(withDuration: duration)
            let group = SKAction.group([moveAction, fadeAction])
            
            p.run(group)
        }
        
        container.run(SKAction.sequence([
            SKAction.wait(forDuration: 0.70),
            SKAction.removeFromParent()
        ]))
    }
    
    // MARK: - Sprite Flash (Hurt)
    
    /// Briefly flashes a sprite node with a tint color on taking damage.
    public static func flashNode(_ node: SKSpriteNode, color: SKColor = .red, duration: TimeInterval = 0.12) {
        let originalColor = node.color
        let originalBlend = node.colorBlendFactor
        
        node.color = color
        node.colorBlendFactor = 0.75
        
        let wait = SKAction.wait(forDuration: duration)
        let restore = SKAction.run { [weak node] in
            node?.color = originalColor
            node?.colorBlendFactor = originalBlend
        }
        
        node.run(SKAction.sequence([wait, restore]), withKey: "vfx_flash")
    }
}
