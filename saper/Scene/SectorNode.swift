import SpriteKit

/// Container node for an 8x8 sector of tiles.
class SectorNode: SKNode {
    let coordinate: SectorCoordinate
    var tileNodes: [[TileNode]] = []
    private var overlayNode: SKShapeNode?
    private var borderNode: SKShapeNode?
    private var modifierBadgeNode: SKLabelNode?
    private var skin: SkinDefinition

    init(coordinate: SectorCoordinate, sector: Sector, renderer: TileRenderer, skin: SkinDefinition) {
        self.skin = skin
        self.coordinate = coordinate
        super.init()

        let size = Constants.sectorSize
        for row in 0..<size {
            var rowNodes: [TileNode] = []
            for col in 0..<size {
                let tileNode = TileNode(
                    localX: col,
                    localY: row,
                    sectorCoord: coordinate,
                    renderer: renderer
                )
                tileNode.updateAppearance(tile: sector.tiles[row][col])
                addChild(tileNode)
                rowNodes.append(tileNode)
            }
            tileNodes.append(rowNodes)
        }

        // Sector border
        let sectorPixelSize = Constants.sectorPixelSize
        let origin = CGPoint(
            x: CGFloat(coordinate.originTileX) * Constants.tileSize,
            y: CGFloat(coordinate.originTileY) * Constants.tileSize
        )
        let borderRect = CGRect(
            x: origin.x,
            y: origin.y,
            width: sectorPixelSize,
            height: sectorPixelSize
        )
        // Heat color: cyan at low density → orange → red at max density
        let densityNorm = CGFloat(max(0, min(1, (sector.density - 0.10) / (Constants.maxDensity - 0.10))))
        let br = CGFloat(min(1.0, densityNorm * 2.0))
        let bg = CGFloat(max(0.1, 0.8 - densityNorm * 0.8))
        let bb = CGFloat(max(0.0, 1.0 - densityNorm * 1.5))

        borderNode = SKShapeNode(rect: borderRect)
        borderNode?.strokeColor = SKColor(red: br, green: bg, blue: bb, alpha: 0.35)
        borderNode?.lineWidth = 1.5
        borderNode?.fillColor = .clear
        borderNode?.zPosition = -1
        if let border = borderNode {
            addChild(border)
            // Slow neon pulse on the grid line
            let dim = SKAction.customAction(withDuration: 2.0) { node, t in
                let alpha = 0.20 + 0.18 * abs(sin(Double(t) * .pi / 2.0))
                (node as? SKShapeNode)?.strokeColor = SKColor(red: br, green: bg, blue: bb, alpha: alpha)
            }
            border.run(SKAction.repeatForever(dim))
        }

        updateOverlay(status: sector.status)
        updateModifierBadge(modifier: sector.modifier)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func updateTile(at localX: Int, localY: Int, with tile: Tile, animated: Bool = false) {
        guard localX >= 0, localX < Constants.sectorSize,
              localY >= 0, localY < Constants.sectorSize else { return }

        let tileNode = tileNodes[localY][localX]
        if animated {
            if tile.state == .mine {
                tileNode.animateMineReveal()
            } else {
                tileNode.animateReveal(tile: tile)
            }
        } else {
            tileNode.updateAppearance(tile: tile)
        }
    }

    func updateAllTiles(sector: Sector) {
        for row in 0..<Constants.sectorSize {
            for col in 0..<Constants.sectorSize {
                tileNodes[row][col].updateAppearance(tile: sector.tiles[row][col])
            }
        }
    }

    func updateOverlay(status: SectorStatus, animated: Bool = false, gemCost: Int = 0) {
        overlayNode?.removeFromParent()
        overlayNode = nil

        let sectorPixelSize = Constants.sectorPixelSize
        let origin = CGPoint(
            x: CGFloat(coordinate.originTileX) * Constants.tileSize,
            y: CGFloat(coordinate.originTileY) * Constants.tileSize
        )
        let overlayRect = CGRect(
            x: origin.x,
            y: origin.y,
            width: sectorPixelSize,
            height: sectorPixelSize
        )
        let center = CGPoint(x: origin.x + sectorPixelSize / 2, y: origin.y + sectorPixelSize / 2)

        switch status {
        case .solved:
            let overlay = SKShapeNode(rect: overlayRect)
            overlay.fillColor = skin.solvedOverlayFill
            overlay.strokeColor = skin.solvedOverlayBorder
            overlay.lineWidth = 2
            overlay.zPosition = 10
            overlayNode = overlay
            addChild(overlay)

            if animated {
                animateSectorSolved(center: center, rect: overlayRect)
            }

        case .locked:
            let overlay = SKShapeNode(rect: overlayRect)
            overlay.fillColor = skin.lockedOverlayFill
            overlay.strokeColor = skin.lockedOverlayBorder
            overlay.lineWidth = 2
            overlay.zPosition = 10
            overlayNode = overlay
            addChild(overlay)

            // Pulsing animation
            let pulseOut = SKAction.fadeAlpha(to: 0.03, duration: 1.0)
            let pulseIn = SKAction.fadeAlpha(to: 0.12, duration: 1.0)
            overlay.run(SKAction.repeatForever(SKAction.sequence([pulseOut, pulseIn])))

            if animated {
                animateSectorFailed(center: center, rect: overlayRect)
            }

        case .inactive:
            let overlay = SKShapeNode(rect: overlayRect)
            overlay.fillColor = skin.inactiveOverlayFill
            overlay.strokeColor = skin.inactiveOverlayBorder
            overlay.lineWidth = 1.5
            overlay.zPosition = 10
            overlayNode = overlay
            addChild(overlay)

            // Gem cost label in the center
            let costText = gemCost > 0 ? "\(gemCost) 💎" : "💎"
            let gemLabel = SKLabelNode(text: costText)
            gemLabel.fontName = "Helvetica-Bold"
            gemLabel.fontSize = 22
            gemLabel.fontColor = skin.inactiveCostLabelColor
            gemLabel.position = CGPoint(x: center.x, y: center.y - 11)
            gemLabel.zPosition = 11
            gemLabel.alpha = 1.0
            overlay.addChild(gemLabel)

        case .active:
            break
        }
    }

    func updateModifierBadge(modifier: SectorModifier?) {
        modifierBadgeNode?.removeFromParent()
        modifierBadgeNode = nil
        guard let modifier = modifier else { return }

        let sectorPixelSize = Constants.sectorPixelSize
        let origin = CGPoint(
            x: CGFloat(coordinate.originTileX) * Constants.tileSize,
            y: CGFloat(coordinate.originTileY) * Constants.tileSize
        )

        let badge = SKLabelNode(text: modifier.badge)
        badge.fontSize = 14
        badge.verticalAlignmentMode = .top
        badge.horizontalAlignmentMode = .right
        badge.position = CGPoint(x: origin.x + sectorPixelSize - 4, y: origin.y + sectorPixelSize - 4)
        badge.zPosition = 12
        badge.alpha = 0.9
        addChild(badge)
        modifierBadgeNode = badge

        // Subtle pulse
        let fadeDown = SKAction.fadeAlpha(to: 0.55, duration: 1.2)
        let fadeUp = SKAction.fadeAlpha(to: 0.9, duration: 1.2)
        badge.run(SKAction.repeatForever(SKAction.sequence([fadeDown, fadeUp])))
    }

    // MARK: - Sector Solved Animation

    private func animateSectorSolved(center: CGPoint, rect: CGRect) {
        // 1. Particle burst from center
        let particleCount = 24
        for i in 0..<particleCount {
            let angle = CGFloat(i) / CGFloat(particleCount) * .pi * 2
            let particle = SKShapeNode(circleOfRadius: 3)
            particle.fillColor = skin.solvedParticleColor
            particle.strokeColor = .clear
            particle.position = center
            particle.zPosition = 20
            particle.alpha = 0.9
            addChild(particle)

            let dist = Constants.sectorPixelSize * 0.6
            let target = CGPoint(x: center.x + cos(angle) * dist, y: center.y + sin(angle) * dist)
            let move = SKAction.move(to: target, duration: 0.5)
            move.timingMode = .easeOut
            let fade = SKAction.fadeOut(withDuration: 0.5)
            let scale = SKAction.scale(to: 0.2, duration: 0.5)
            let group = SKAction.group([move, fade, scale])
            particle.run(SKAction.sequence([group, SKAction.removeFromParent()]))
        }

        // 2. Expanding ring
        let ring = SKShapeNode(circleOfRadius: 10)
        ring.strokeColor = skin.solvedRingColor
        ring.fillColor = .clear
        ring.lineWidth = 3
        ring.position = center
        ring.zPosition = 19
        addChild(ring)

        let expand = SKAction.scale(to: Constants.sectorPixelSize / 20, duration: 0.6)
        expand.timingMode = .easeOut
        let fadeRing = SKAction.fadeOut(withDuration: 0.6)
        ring.run(SKAction.sequence([SKAction.group([expand, fadeRing]), SKAction.removeFromParent()]))

        // 3. Flash overlay
        let flash = SKShapeNode(rect: rect)
        flash.fillColor = skin.solvedFlashColor
        flash.strokeColor = .clear
        flash.zPosition = 18
        addChild(flash)
        flash.run(SKAction.sequence([SKAction.fadeOut(withDuration: 0.4), SKAction.removeFromParent()]))

        // 4. Border glow pulse
        if let overlay = overlayNode {
            let borderColor = skin.solvedOverlayBorder
            var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
            borderColor.getRed(&r, green: &g, blue: &b, alpha: &a)
            let glowUp = SKAction.customAction(withDuration: 0.3) { node, t in
                (node as? SKShapeNode)?.strokeColor = SKColor(red: r, green: g, blue: b, alpha: a + (1.0 - a) * (1.0 - t / 0.3))
            }
            overlay.run(SKAction.sequence([
                glowUp,
                SKAction.customAction(withDuration: 0) { [borderColor] node, _ in
                    (node as? SKShapeNode)?.strokeColor = borderColor
                }
            ]))
        }
    }

    // MARK: - Sector Failed Animation

    private func animateSectorFailed(center: CGPoint, rect: CGRect) {
        // 1. Flash
        let flash = SKShapeNode(rect: rect)
        flash.fillColor = skin.failedFlashColor
        flash.strokeColor = .clear
        flash.zPosition = 18
        addChild(flash)
        flash.run(SKAction.sequence([SKAction.fadeOut(withDuration: 0.5), SKAction.removeFromParent()]))

        // 2. Shake the sector tiles
        let shakeRight = SKAction.moveBy(x: 6, y: 0, duration: 0.04)
        let shakeLeft = SKAction.moveBy(x: -12, y: 0, duration: 0.04)
        let shakeCenter = SKAction.moveBy(x: 6, y: 0, duration: 0.04)
        let shakeSequence = SKAction.sequence([shakeRight, shakeLeft, shakeCenter])
        for row in tileNodes {
            for tileNode in row {
                tileNode.run(SKAction.repeat(shakeSequence, count: 3))
            }
        }

        // 3. Particles scattering outward
        let particleCount = 16
        for i in 0..<particleCount {
            let angle = CGFloat(i) / CGFloat(particleCount) * .pi * 2 + CGFloat.random(in: -0.2...0.2)
            let particle = SKShapeNode(circleOfRadius: 2.5)
            particle.fillColor = skin.failedParticleColor
            particle.strokeColor = .clear
            particle.position = center
            particle.zPosition = 20
            addChild(particle)

            let dist = Constants.sectorPixelSize * 0.45
            let target = CGPoint(x: center.x + cos(angle) * dist, y: center.y + sin(angle) * dist)
            let move = SKAction.move(to: target, duration: 0.4)
            move.timingMode = .easeOut
            let fade = SKAction.fadeOut(withDuration: 0.4)
            particle.run(SKAction.sequence([SKAction.group([move, fade]), SKAction.removeFromParent()]))
        }

        // 4. X marker at center
        let xMark = SKLabelNode(text: "✕")
        xMark.fontName = "Helvetica-Bold"
        xMark.fontSize = 40
        xMark.fontColor = skin.failedXMarkColor
        xMark.position = center
        xMark.zPosition = 21
        xMark.setScale(0.1)
        addChild(xMark)

        let pop = SKAction.scale(to: 1.0, duration: 0.2)
        pop.timingMode = .easeOut
        let hold = SKAction.wait(forDuration: 0.8)
        let fadeX = SKAction.fadeOut(withDuration: 0.5)
        xMark.run(SKAction.sequence([pop, hold, fadeX, SKAction.removeFromParent()]))
    }

    /// Get the bounding rect in world coordinates.
    var worldBoundingRect: CGRect {
        CGRect(
            x: CGFloat(coordinate.originTileX) * Constants.tileSize,
            y: CGFloat(coordinate.originTileY) * Constants.tileSize,
            width: Constants.sectorPixelSize,
            height: Constants.sectorPixelSize
        )
    }
}
