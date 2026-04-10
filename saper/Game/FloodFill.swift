import Foundation

/// BFS flood fill for 0-tiles that works across sector boundaries.
struct FloodFill {

    struct TilePosition: Hashable {
        let globalX: Int
        let globalY: Int
    }

    /// Perform flood fill starting from a 0-tile. Returns all revealed positions.
    static func execute(
        startX: Int,
        startY: Int,
        boardManager: BoardManager
    ) -> [TilePosition] {
        var revealed: [TilePosition] = []
        var queue: [TilePosition] = [TilePosition(globalX: startX, globalY: startY)]
        var visited: Set<TilePosition> = []

        while !queue.isEmpty {
            let pos = queue.removeFirst()
            if visited.contains(pos) { continue }
            visited.insert(pos)

            let sectorCoord = SectorCoordinate(fromTileX: pos.globalX, tileY: pos.globalY)
            let sector = boardManager.ensureSector(at: sectorCoord)

            if sector.status == .locked { continue }

            let localX = pos.globalX - sectorCoord.originTileX
            let localY = pos.globalY - sectorCoord.originTileY

            guard localX >= 0, localX < Constants.sectorSize,
                  localY >= 0, localY < Constants.sectorSize else { continue }

            let tile = sector.tiles[localY][localX]
            if tile.hasMine { continue }
            if tile.state == .revealed { continue }
            if tile.state == .flagged { continue }

            // Always compute a fresh adjacent count — cached values can be stale
            // when ensureSafeFirstTap relocated a mine in a neighbouring sector.
            let count = boardManager.adjacentMineCount(
                globalTileX: pos.globalX,
                globalTileY: pos.globalY
            )
            sector.tiles[localY][localX].adjacentMineCount = count

            sector.tiles[localY][localX].state = .revealed
            sector.isModified = true
            revealed.append(pos)

            // If this tile has 0 adjacent mines, enqueue all 8 neighbors
            if sector.tiles[localY][localX].adjacentMineCount == 0 {
                for dx in -1...1 {
                    for dy in -1...1 {
                        if dx == 0 && dy == 0 { continue }
                        let np = TilePosition(globalX: pos.globalX + dx, globalY: pos.globalY + dy)
                        if !visited.contains(np) {
                            queue.append(np)
                        }
                    }
                }
            }
        }

        return revealed
    }
}
