import SpriteKit

/// Represents a single tile in the game board.
class TileNode: SKSpriteNode {
    let localX: Int
    let localY: Int
    let globalX: Int
    let globalY: Int

    private weak var tileRenderer: TileRenderer?

    init(localX: Int, localY: Int, sectorCoord: SectorCoordinate, renderer: TileRenderer) {
        self.localX = localX
        self.localY = localY
        self.globalX = sectorCoord.originTileX + localX
        self.globalY = sectorCoord.originTileY + localY
        self.tileRenderer = renderer

        let texture = renderer.texture(for: .hidden) ?? SKTexture()
        super.init(texture: texture, color: .clear, size: CGSize(width: Constants.tileSize, height: Constants.tileSize))

        self.position = CGPoint(
            x: CGFloat(globalX) * Constants.tileSize + Constants.tileSize / 2,
            y: CGFloat(globalY) * Constants.tileSize + Constants.tileSize / 2
        )
        self.name = "tile_\(globalX)_\(globalY)"
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func updateAppearance(tile: Tile) {
        guard let renderer = tileRenderer else { return }
        let newTexture = renderer.texture(for: tile.state, adjacentCount: tile.adjacentMineCount)
        self.texture = newTexture
        updateGemOverlay(tile: tile)
    }

    func animateReveal(tile: Tile) {
        guard let renderer = tileRenderer else { return }
        let newTexture = renderer.texture(for: tile.state, adjacentCount: tile.adjacentMineCount)

        let scaleDown = SKAction.scale(to: 0.8, duration: 0.05)
        let changeTexture = SKAction.run { [weak self] in
            self?.texture = newTexture
        }
        let scaleUp = SKAction.scale(to: 1.05, duration: 0.08)
        let settle = SKAction.scale(to: 1.0, duration: 0.05)

        if tile.hasGem && tile.state == .revealed {
            let addGem = SKAction.run { [weak self] in
                self?.updateGemOverlay(tile: tile, animated: true)
            }
            run(SKAction.sequence([scaleDown, changeTexture, scaleUp, settle, addGem]))
        } else {
            run(SKAction.sequence([scaleDown, changeTexture, scaleUp, settle]))
        }
    }

    func animateMineReveal() {
        guard let renderer = tileRenderer else { return }
        let mineTexture = renderer.texture(for: .mine)

        let flash = SKAction.sequence([
            SKAction.run { [weak self] in self?.texture = mineTexture },
            SKAction.scale(to: 1.3, duration: 0.1),
            SKAction.scale(to: 1.0, duration: 0.15),
        ])
        run(flash)
    }

    private func updateGemOverlay(tile: Tile, animated: Bool = false) {
        childNode(withName: "gemOverlay")?.removeFromParent()
        guard tile.state == .revealed && tile.hasGem else { return }

        let gemLabel = SKLabelNode(text: "💎")
        gemLabel.name = "gemOverlay"
        gemLabel.fontSize = 9
        gemLabel.verticalAlignmentMode = .center
        gemLabel.horizontalAlignmentMode = .center
        gemLabel.position = CGPoint(x: Constants.tileSize / 2 - 7, y: -Constants.tileSize / 2 + 7)
        gemLabel.zPosition = 5

        if animated {
            gemLabel.setScale(0.1)
            gemLabel.alpha = 0
            addChild(gemLabel)
            gemLabel.run(SKAction.group([
                SKAction.scale(to: 1.0, duration: 0.2),
                SKAction.fadeIn(withDuration: 0.2)
            ]))
        } else {
            addChild(gemLabel)
        }
    }
}
