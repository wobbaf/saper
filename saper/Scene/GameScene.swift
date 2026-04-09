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
        backgroundColor = gameState.profile.currentSkin.backgroundColor

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

        let tile = sector.tiles[localY][localX]

        if tile.state == .revealed && tile.adjacentMineCount > 0 {
            gameState.chordReveal(globalX: globalX, globalY: globalY)
        } else if tile.state == .hidden {
            gameState.revealTile(globalX: globalX, globalY: globalY)
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
    /// Only create nodes within a reasonable visual radius.
    private func syncSectorNodes() {
        let center = cameraController.centerSectorCoordinate()
        let visualRadius = Constants.loadRadius + 1

        for (coord, sector) in gameState.boardManager.sectors {
            if coord.chebyshevDistance(to: center) <= visualRadius {
                if sectorNodes[coord] == nil {
                    let sectorNode = SectorNode(
                        coordinate: coord,
                        sector: sector,
                        renderer: tileRenderer
                    )
                    addChild(sectorNode)
                    sectorNodes[coord] = sectorNode
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

        gameState.onGemCollected = { _ in }
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
        guard let sector = gameState.boardManager.sector(at: coord) else { return }

        let centerX = CGFloat(coord.originTileX) * Constants.tileSize + Constants.sectorPixelSize / 2
        let centerY = CGFloat(coord.originTileY) * Constants.tileSize + Constants.sectorPixelSize / 2

        if sector.gemReward > 0 && !sector.gemCollected {
            hudNode.showFloatingText(
                "+\(sector.gemReward) gems",
                at: CGPoint(x: centerX, y: centerY),
                color: SKColor(red: 0.3, green: 0.8, blue: 1.0, alpha: 1)
            )
        }

        hudNode.showFloatingText(
            "+\(Constants.xpPerSectorSolve) XP",
            at: CGPoint(x: centerX, y: centerY + 25),
            color: SKColor(red: 0.5, green: 1.0, blue: 0.5, alpha: 1)
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
