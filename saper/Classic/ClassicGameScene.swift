import SpriteKit
import UIKit

/// SpriteKit scene for the classic (finite board) minesweeper mode.
class ClassicGameScene: SKScene {
    var classicGameState: ClassicGameState!

    private let tileRenderer = ClassicTileRenderer()
    private var tileNodes: [[SKSpriteNode]] = []

    private var classicTileSize: CGFloat = 0
    private var gridOriginX: CGFloat = 0
    private var gridOriginY: CGFloat = 0

    private var tapGesture: UITapGestureRecognizer?
    private var longPressGesture: UILongPressGestureRecognizer?

    // MARK: - Scene Lifecycle

    override func didMove(to view: SKView) {
        backgroundColor = ClassicTileRenderer.bgColor
        anchorPoint = .zero

        computeTileSize()
        tileRenderer.generateTextures(tileSize: classicTileSize, in: view)
        buildGrid()
        setupGestures(in: view)
        setupCallbacks()
    }

    // MARK: - Tile Sizing

    private func computeTileSize() {
        guard let view = self.view else { return }
        let maxWidth = view.bounds.width
        let maxHeight = view.bounds.height

        let board = classicGameState.board
        let fitW = maxWidth / CGFloat(board.columns)
        let fitH = maxHeight / CGFloat(board.rows)
        classicTileSize = floor(min(fitW, fitH) * 0.92)
        classicTileSize = max(classicTileSize, 20)

        let gridWidth = CGFloat(board.columns) * classicTileSize
        let gridHeight = CGFloat(board.rows) * classicTileSize
        gridOriginX = (maxWidth - gridWidth) / 2
        gridOriginY = (maxHeight - gridHeight) / 2
    }

    // MARK: - Grid Building

    private func buildGrid() {
        // Remove old tiles
        tileNodes.forEach { row in row.forEach { $0.removeFromParent() } }
        tileNodes.removeAll()

        let board = classicGameState.board
        for r in 0..<board.rows {
            var rowNodes: [SKSpriteNode] = []
            for c in 0..<board.columns {
                let tile = board.tiles[r][c]
                let tex = tileRenderer.texture(for: tile.state, adjacentCount: tile.adjacentMineCount) ?? SKTexture()
                let sprite = SKSpriteNode(texture: tex, size: CGSize(width: classicTileSize, height: classicTileSize))
                sprite.position = CGPoint(
                    x: gridOriginX + CGFloat(c) * classicTileSize + classicTileSize / 2,
                    y: gridOriginY + CGFloat(r) * classicTileSize + classicTileSize / 2
                )
                addChild(sprite)
                rowNodes.append(sprite)
            }
            tileNodes.append(rowNodes)
        }
    }

    // MARK: - Gestures

    private func setupGestures(in view: SKView) {
        let tap = UITapGestureRecognizer(target: self, action: #selector(handleTap(_:)))
        tap.numberOfTapsRequired = 1
        view.addGestureRecognizer(tap)
        self.tapGesture = tap

        let longPress = UILongPressGestureRecognizer(target: self, action: #selector(handleLongPress(_:)))
        longPress.minimumPressDuration = 0.3
        view.addGestureRecognizer(longPress)
        self.longPressGesture = longPress
    }

    @objc private func handleTap(_ gesture: UITapGestureRecognizer) {
        guard gesture.state == .ended, let view = self.view else { return }
        let viewPoint = gesture.location(in: view)
        guard let (col, row) = viewPointToGrid(viewPoint) else { return }
        classicGameState.revealTile(col: col, row: row)
    }

    @objc private func handleLongPress(_ gesture: UILongPressGestureRecognizer) {
        guard gesture.state == .began, let view = self.view else { return }
        let viewPoint = gesture.location(in: view)
        guard let (col, row) = viewPointToGrid(viewPoint) else { return }
        classicGameState.toggleFlag(col: col, row: row)
    }

    // MARK: - Coordinate Conversion

    private func viewPointToGrid(_ viewPoint: CGPoint) -> (col: Int, row: Int)? {
        let scenePoint = convertPoint(fromView: viewPoint)
        let col = Int(floor((scenePoint.x - gridOriginX) / classicTileSize))
        let row = Int(floor((scenePoint.y - gridOriginY) / classicTileSize))
        guard classicGameState.board.inBounds(col: col, row: row) else { return nil }
        return (col, row)
    }

    // MARK: - Callbacks

    private func setupCallbacks() {
        classicGameState.onTileRevealed = { [weak self] col, row in
            self?.updateTileNode(col: col, row: row, animated: true)
        }

        classicGameState.onTilesRevealed = { [weak self] positions in
            guard let self = self else { return }
            for (col, row) in positions {
                self.updateTileNode(col: col, row: row, animated: true)
            }
        }

        classicGameState.onTileStateChanged = { [weak self] col, row in
            self?.updateTileNode(col: col, row: row, animated: false)
        }

        classicGameState.onMineHit = { [weak self] _, _ in
            self?.revealAllTiles()
        }

        classicGameState.onGameWon = { [weak self] in
            self?.revealAllTiles()
        }

        classicGameState.onBoardReset = { [weak self] in
            self?.rebuildGrid()
        }
    }

    // MARK: - Tile Updates

    private func updateTileNode(col: Int, row: Int, animated: Bool) {
        guard row >= 0 && row < tileNodes.count && col >= 0 && col < tileNodes[row].count else { return }
        let tile = classicGameState.board.tiles[row][col]
        let tex = tileRenderer.texture(for: tile.state, adjacentCount: tile.adjacentMineCount)
        let sprite = tileNodes[row][col]

        if animated && tile.state == .revealed {
            let scaleDown = SKAction.scale(to: 0.85, duration: 0.04)
            let change = SKAction.run { sprite.texture = tex }
            let scaleUp = SKAction.scale(to: 1.0, duration: 0.06)
            sprite.run(SKAction.sequence([scaleDown, change, scaleUp]))
        } else {
            sprite.texture = tex
        }
    }

    private func revealAllTiles() {
        let board = classicGameState.board
        for r in 0..<board.rows {
            for c in 0..<board.columns {
                let tile = board.tiles[r][c]
                let tex = tileRenderer.texture(for: tile.state, adjacentCount: tile.adjacentMineCount)
                tileNodes[r][c].texture = tex
            }
        }
    }

    private func rebuildGrid() {
        guard self.view != nil else { return }
        buildGrid()
    }
}
