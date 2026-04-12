import SpriteKit
import UIKit

/// Main SpriteKit scene for the minesweeper game board.
class GameScene: SKScene {
    var gameState: GameState!

    private let cameraController = CameraController()
    private let tileRenderer = TileRenderer()
    private let hudNode = HUDNode()
    private let starfield = StarfieldNode()

    private var sectorNodes: [SectorCoordinate: SectorNode] = [:]
    private let cameraNode = SKCameraNode()

    private var lastUpdateTime: TimeInterval = 0
    private var sectorUpdateAccumulator: TimeInterval = 0
    private let sectorUpdateInterval: TimeInterval = 0.5

    private var tapGesture: UITapGestureRecognizer?
    private var longPressGesture: UILongPressGestureRecognizer?
    private var lastFlagToggleTime: TimeInterval = 0

    // MARK: - Scene Lifecycle

    override func didMove(to view: SKView) {
        backgroundColor = backgroundColorForTier(gameState.difficultyTier, skin: gameState.profile.currentSkin)

        // Camera — start centered on middle of sector (0,0)
        let startX = Constants.sectorPixelSize / 2
        let startY = Constants.sectorPixelSize / 2
        cameraNode.position = CGPoint(x: startX, y: startY)
        cameraNode.setScale(Constants.defaultCameraScale)
        addChild(cameraNode)
        camera = cameraNode

        // Camera controller
        cameraController.cameraNode = cameraNode
        cameraController.scene = self
        cameraController.setupGestures(in: view)
        cameraController.onCameraMoved = { [weak self] in
            self?.onCameraChanged()
        }

        // Tile textures
        tileRenderer.generateTextures(for: gameState.profile.currentSkin, in: view)

        // Starfield
        starfield.setup(for: view.bounds.size)
        addChild(starfield)

        // HUD
        cameraNode.addChild(hudNode)

        // Gesture recognizers for gameplay
        setupGameplayGestures(in: view)

        // Wire up game state callbacks
        setupGameStateCallbacks()

        // Initial sector load
        loadInitialSectors()
    }

    // MARK: - Gesture Setup

    private func setupGameplayGestures(in view: SKView) {
        // Single tap — reveal tile or chord
        let tap = UITapGestureRecognizer(target: self, action: #selector(handleTap(_:)))
        tap.numberOfTapsRequired = 1
        tap.delegate = GameplayGestureDelegate.shared
        view.addGestureRecognizer(tap)
        self.tapGesture = tap

        // Tap should only fire if the pan gesture fails (finger didn't move enough)
        if let panGesture = cameraController.panGesture {
            tap.require(toFail: panGesture)
        }

        // Long press — flag tile
        let longPress = UILongPressGestureRecognizer(target: self, action: #selector(handleLongPress(_:)))
        longPress.minimumPressDuration = 0.3
        longPress.delegate = GameplayGestureDelegate.shared
        view.addGestureRecognizer(longPress)
        self.longPressGesture = longPress
    }

    // MARK: - Coordinate Conversion

    /// Convert a view-space point to world-space, accounting for camera position and scale.
    private func viewPointToWorld(_ viewPoint: CGPoint) -> CGPoint {
        guard let view = self.view else { return .zero }
        let viewSize = view.bounds.size

        // Normalize to -0.5...0.5 range from center of view
        let nx = (viewPoint.x / viewSize.width) - 0.5
        let ny = 0.5 - (viewPoint.y / viewSize.height) // flip Y

        // Apply camera transform
        let worldX = cameraNode.position.x + nx * viewSize.width * cameraNode.xScale
        let worldY = cameraNode.position.y + ny * viewSize.height * cameraNode.yScale

        return CGPoint(x: worldX, y: worldY)
    }

    private func globalTileAt(worldPoint: CGPoint) -> (Int, Int) {
        let gx = Int(floor(worldPoint.x / Constants.tileSize))
        let gy = Int(floor(worldPoint.y / Constants.tileSize))
        return (gx, gy)
    }

    // MARK: - Gesture Handlers

    @objc private func handleTap(_ gesture: UITapGestureRecognizer) {
        guard gesture.state == .ended, let view = self.view else { return }

        // Suppress taps shortly after a flag toggle to prevent accidental reveals
        if CACurrentMediaTime() - lastFlagToggleTime < 0.4 { return }

        let locationInView = gesture.location(in: view)
        let worldPoint = viewPointToWorld(locationInView)
        let (globalX, globalY) = globalTileAt(worldPoint: worldPoint)

        let sectorCoord = SectorCoordinate(fromTileX: globalX, tileY: globalY)

        guard let sector = gameState.boardManager.sector(at: sectorCoord) else { return }

        let localX = globalX - sectorCoord.originTileX
        let localY = globalY - sectorCoord.originTileY
        guard localX >= 0, localX < Constants.sectorSize,
              localY >= 0, localY < Constants.sectorSize else { return }

        // Inactive or mine-hit locked sectors: tap to unlock with gems
        if sector.status == .inactive || sector.status == .locked {
            attemptUnlockSector(sectorCoord: sectorCoord)
            return
        }

        let tile = sector.tiles[localY][localX]

        if tile.state == .revealed && tile.adjacentMineCount > 0 {
            gameState.chordReveal(globalX: globalX, globalY: globalY)
        } else if tile.state == .hidden {
            gameState.revealTile(globalX: globalX, globalY: globalY)
        }
    }

    private func attemptUnlockSector(sectorCoord: SectorCoordinate) {
        let cost = gameState.unlockCost(for: sectorCoord)
        let center = CGPoint(
            x: CGFloat(sectorCoord.originTileX) * Constants.tileSize + Constants.sectorPixelSize / 2,
            y: CGFloat(sectorCoord.originTileY) * Constants.tileSize + Constants.sectorPixelSize / 2
        )
        if gameState.profile.gems >= cost {
            // Show confirmation dialog via SwiftUI before spending gems
            gameState.pendingUnlockCoord = sectorCoord
        } else {
            // Not enough gems — flash the cost
            let needed = cost - gameState.profile.gems
            hudNode.showFloatingText(
                "Need \(needed) more 💎",
                at: center,
                color: gameState.profile.currentSkin.definition.floatingWarningColor
            )
            AudioManager.shared.play(.lockedSectorTap)
            HapticsManager.shared.play(.lockedSectorTap)
        }
    }

    @objc private func handleLongPress(_ gesture: UILongPressGestureRecognizer) {
        guard gesture.state == .began, let view = self.view else { return }

        let locationInView = gesture.location(in: view)
        let worldPoint = viewPointToWorld(locationInView)
        let (globalX, globalY) = globalTileAt(worldPoint: worldPoint)

        lastFlagToggleTime = CACurrentMediaTime()
        gameState.toggleFlag(globalX: globalX, globalY: globalY)
    }

    // MARK: - Camera Changed

    private func onCameraChanged() {
        updateSectorLoading()
        starfield.updateParallax(
            cameraPosition: cameraNode.position,
            cameraScale: cameraNode.xScale
        )
        gameState.focusedSector = cameraController.centerSectorCoordinate()
    }

    // MARK: - Sector Loading

    private func loadInitialSectors() {
        let center = cameraController.centerSectorCoordinate()
        gameState.boardManager.loadSectorsAround(center, radius: Constants.loadRadius)

        // Compute adjacent counts
        for (_, sector) in gameState.boardManager.sectors {
            gameState.boardManager.computeAdjacentCounts(for: sector)
        }

        syncSectorNodes()
    }

    func updateSectorLoading() {
        let center = cameraController.centerSectorCoordinate()

        // Load new sectors
        gameState.boardManager.loadSectorsAround(center, radius: Constants.loadRadius)

        // Unload distant sectors (remove nodes)
        var toRemove: [SectorCoordinate] = []
        for (coord, _) in sectorNodes {
            if coord.chebyshevDistance(to: center) > Constants.unloadRadius {
                toRemove.append(coord)
            }
        }
        for coord in toRemove {
            sectorNodes[coord]?.removeFromParent()
            sectorNodes[coord] = nil
        }

        // Unload data for distant unmodified sectors
        let _ = gameState.boardManager.unloadSectorsBeyond(center, radius: Constants.unloadRadius)

        syncSectorNodes()
    }

    /// Create SectorNodes for loaded sectors that don't have visual nodes yet.
    private func syncSectorNodes() {
        let center = cameraController.centerSectorCoordinate()
        let visualRadius = Constants.loadRadius + 1

        for (coord, sector) in gameState.boardManager.sectors {
            if coord.chebyshevDistance(to: center) <= visualRadius {
                if sectorNodes[coord] == nil {
                    let sectorNode = SectorNode(
                        coordinate: coord,
                        sector: sector,
                        renderer: tileRenderer,
                        skin: gameState.profile.currentSkin.definition
                    )
                    addChild(sectorNode)
                    sectorNodes[coord] = sectorNode
                    if sector.status == .inactive {
                        let cost = gameState.unlockCost(for: coord)
                        sectorNode.updateOverlay(status: .inactive, gemCost: cost)
                    }
                }
            }
        }
    }

    // MARK: - Game State Callbacks

    private func setupGameStateCallbacks() {
        gameState.onTilesRevealed = { [weak self] positions in
            self?.handleTilesRevealed(positions)
        }

        gameState.onTileStateChanged = { [weak self] gx, gy, state in
            self?.handleTileStateChanged(globalX: gx, globalY: gy, state: state)
        }

        gameState.onSectorStatusChanged = { [weak self] coord, status in
            self?.handleSectorStatusChanged(coord: coord, status: status)
        }

        gameState.onMineHit = { [weak self] coord in
            self?.handleMineHit(coord: coord)
        }

        gameState.onSectorSolved = { [weak self] coord in
            self?.handleSectorSolved(coord: coord)
        }

        gameState.onSectorReset = { [weak self] coord in
            self?.handleSectorReset(coord: coord)
        }

        gameState.onGemCollected = { [weak self] amount, coord in
            guard let self = self else { return }
            let centerX = CGFloat(coord.originTileX) * Constants.tileSize + Constants.sectorPixelSize / 2
            let centerY = CGFloat(coord.originTileY) * Constants.tileSize + Constants.sectorPixelSize / 2
            self.hudNode.showFloatingText(
                "+\(amount) gems",
                at: CGPoint(x: centerX, y: centerY),
                color: self.gameState.profile.currentSkin.definition.floatingGemColor
            )
        }

        gameState.onTileGemCollected = { [weak self] gx, gy, amount in
            guard let self = self else { return }
            let worldPos = CGPoint(
                x: CGFloat(gx) * Constants.tileSize + Constants.tileSize / 2,
                y: CGFloat(gy) * Constants.tileSize + Constants.tileSize / 2 + 12
            )
            self.hudNode.showFloatingText(
                "+\(amount) 💎",
                at: worldPos,
                color: self.gameState.profile.currentSkin.definition.floatingGemColor
            )
        }

        gameState.onPiggyBankFound = { [weak self] gx, gy, amount in
            guard let self = self else { return }
            let worldX = CGFloat(gx) * Constants.tileSize + Constants.tileSize / 2
            let worldY = CGFloat(gy) * Constants.tileSize + Constants.tileSize / 2
            self.hudNode.showFloatingText(
                "+\(amount) 💰",
                at: CGPoint(x: worldX, y: worldY),
                color: self.gameState.profile.currentSkin.definition.floatingGoldColor
            )
        }

        gameState.onAchievementUnlocked = { [weak self] achievement in
            guard let self = self else { return }
            let camPos = self.cameraNode.position
            self.hudNode.showFloatingText(
                "🏆 \(achievement.displayName)",
                at: CGPoint(x: camPos.x, y: camPos.y + 60),
                color: self.gameState.profile.currentSkin.definition.floatingGoldColor
            )
        }

        gameState.onDifficultyTierChanged = { [weak self] tier in
            self?.animateBackgroundToTier(tier)
        }

        gameState.onSectorUnlocked = { [weak self] coord, cost in
            guard let self = self else { return }
            let center = CGPoint(
                x: CGFloat(coord.originTileX) * Constants.tileSize + Constants.sectorPixelSize / 2,
                y: CGFloat(coord.originTileY) * Constants.tileSize + Constants.sectorPixelSize / 2
            )
            self.hudNode.showFloatingText(
                "-\(cost) 💎",
                at: center,
                color: self.gameState.profile.currentSkin.definition.floatingGemColor
            )
        }
    }

    // MARK: - Difficulty Background

    /// Background colour for a difficulty tier — lerps from skin base colour to skin max colour.
    private func backgroundColorForTier(_ tier: Int, skin: SkinType) -> SKColor {
        let def = skin.definition
        let t = min(CGFloat(tier) / CGFloat(Constants.maxDifficultyTier), 1.0)
        var sr: CGFloat = 0, sg: CGFloat = 0, sb: CGFloat = 0, sa: CGFloat = 0
        var er: CGFloat = 0, eg: CGFloat = 0, eb: CGFloat = 0, ea: CGFloat = 0
        def.backgroundColor.getRed(&sr, green: &sg, blue: &sb, alpha: &sa)
        def.difficultyMaxColor.getRed(&er, green: &eg, blue: &eb, alpha: &ea)
        return SKColor(
            red:   sr + (er - sr) * t,
            green: sg + (eg - sg) * t,
            blue:  sb + (eb - sb) * t,
            alpha: 1
        )
    }

    private func animateBackgroundToTier(_ tier: Int) {
        let target = backgroundColorForTier(tier, skin: gameState.profile.currentSkin)
        let start = backgroundColor
        var startR: CGFloat = 0, startG: CGFloat = 0, startB: CGFloat = 0, startA: CGFloat = 0
        var endR: CGFloat = 0, endG: CGFloat = 0, endB: CGFloat = 0, endA: CGFloat = 0
        start.getRed(&startR, green: &startG, blue: &startB, alpha: &startA)
        target.getRed(&endR, green: &endG, blue: &endB, alpha: &endA)

        let duration: CGFloat = 2.5
        let fade = SKAction.customAction(withDuration: Double(duration)) { [weak self] _, t in
            let p = min(t / duration, 1.0)
            self?.backgroundColor = SKColor(
                red:   startR + (endR - startR) * p,
                green: startG + (endG - startG) * p,
                blue:  startB + (endB - startB) * p,
                alpha: 1
            )
        }
        run(fade)
    }

    private func handleTilesRevealed(_ positions: [FloodFill.TilePosition]) {
        for pos in positions {
            let sectorCoord = SectorCoordinate(fromTileX: pos.globalX, tileY: pos.globalY)
            guard let sector = gameState.boardManager.sector(at: sectorCoord),
                  let sectorNode = sectorNodes[sectorCoord] else { continue }

            let localX = pos.globalX - sectorCoord.originTileX
            let localY = pos.globalY - sectorCoord.originTileY

            guard localX >= 0, localX < Constants.sectorSize,
                  localY >= 0, localY < Constants.sectorSize else { continue }

            sectorNode.updateTile(at: localX, localY: localY, with: sector.tiles[localY][localX], animated: true)
        }
    }

    private func handleTileStateChanged(globalX: Int, globalY: Int, state: TileState) {
        let sectorCoord = SectorCoordinate(fromTileX: globalX, tileY: globalY)
        guard let sector = gameState.boardManager.sector(at: sectorCoord),
              let sectorNode = sectorNodes[sectorCoord] else { return }

        let localX = globalX - sectorCoord.originTileX
        let localY = globalY - sectorCoord.originTileY

        guard localX >= 0, localX < Constants.sectorSize,
              localY >= 0, localY < Constants.sectorSize else { return }

        sectorNode.updateTile(at: localX, localY: localY, with: sector.tiles[localY][localX], animated: true)
    }

    private func handleSectorStatusChanged(coord: SectorCoordinate, status: SectorStatus) {
        sectorNodes[coord]?.updateOverlay(status: status, animated: true)
        // A solve or unlock changes distances — refresh costs on all visible inactive sectors
        if status == .solved || status == .active {
            refreshInactiveSectorCosts()
        }
    }

    private func refreshInactiveSectorCosts() {
        for (coord, node) in sectorNodes {
            guard let sector = gameState.boardManager.sector(at: coord),
                  sector.status == .inactive else { continue }
            let cost = gameState.unlockCost(for: coord)
            node.updateOverlay(status: .inactive, gemCost: cost)
        }
    }

    private func handleMineHit(coord: SectorCoordinate) {
        guard let sector = gameState.boardManager.sector(at: coord),
              let sectorNode = sectorNodes[coord] else { return }

        for row in 0..<Constants.sectorSize {
            for col in 0..<Constants.sectorSize {
                if sector.tiles[row][col].hasMine && sector.tiles[row][col].state != .flagged {
                    sector.tiles[row][col].state = .mine
                    sectorNode.updateTile(at: col, localY: row, with: sector.tiles[row][col], animated: true)
                }
            }
        }
    }

    private func handleSectorReset(coord: SectorCoordinate) {
        guard let sector = gameState.boardManager.sector(at: coord),
              let sectorNode = sectorNodes[coord] else { return }
        sectorNode.updateAllTiles(sector: sector)
    }

    private func handleSectorSolved(coord: SectorCoordinate) {
        let centerX = CGFloat(coord.originTileX) * Constants.tileSize + Constants.sectorPixelSize / 2
        let centerY = CGFloat(coord.originTileY) * Constants.tileSize + Constants.sectorPixelSize / 2

        hudNode.showFloatingText(
            "+\(Constants.xpPerSectorSolve) XP",
            at: CGPoint(x: centerX, y: centerY + 25),
            color: gameState.profile.currentSkin.definition.floatingXPColor
        )
    }

    // MARK: - Update Loop

    override func update(_ currentTime: TimeInterval) {
        let dt = lastUpdateTime == 0 ? 0 : currentTime - lastUpdateTime
        lastUpdateTime = currentTime

        // Periodically sync sectors
        sectorUpdateAccumulator += dt
        if sectorUpdateAccumulator >= sectorUpdateInterval {
            sectorUpdateAccumulator = 0
            updateSectorLoading()
        }

        // Check timed mode
        if gameState.gameMode == .timed && gameState.timerManager.isExpired && !gameState.isGameOver {
            gameState.endGame()
        }
    }
}

/// Gesture delegate for gameplay gestures (tap + long press).
/// Allows these to work simultaneously with pan and pinch.
private class GameplayGestureDelegate: NSObject, UIGestureRecognizerDelegate {
    static let shared = GameplayGestureDelegate()

    func gestureRecognizer(
        _ gestureRecognizer: UIGestureRecognizer,
        shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer
    ) -> Bool {
        // Tap and long press should not block each other or pan/pinch
        if gestureRecognizer is UITapGestureRecognizer || gestureRecognizer is UILongPressGestureRecognizer {
            return true
        }
        return false
    }

    func gestureRecognizer(
        _ gestureRecognizer: UIGestureRecognizer,
        shouldRequireFailureOf otherGestureRecognizer: UIGestureRecognizer
    ) -> Bool {
        // Tap should NOT wait for pan/pinch to fail
        return false
    }

    func gestureRecognizer(
        _ gestureRecognizer: UIGestureRecognizer,
        shouldBeRequiredToFailBy otherGestureRecognizer: UIGestureRecognizer
    ) -> Bool {
        // Pan/pinch should NOT wait for tap to fail
        return false
    }
}
