import Foundation

class Sector: Codable {
    let coordinate: SectorCoordinate
    var tiles: [[Tile]]
    var status: SectorStatus = .inactive
    var density: Double = 0.0
    var gemReward: Int = 0
    var gemCollected: Bool = false
    var firstTapDone: Bool = false
    var isModified: Bool = false
    var modifier: SectorModifier? = nil

    init(coordinate: SectorCoordinate, tiles: [[Tile]], gemReward: Int = 0) {
        self.coordinate = coordinate
        self.tiles = tiles
        self.gemReward = gemReward
    }

    var mineCount: Int {
        tiles.flatMap { $0 }.filter { $0.hasMine }.count
    }

    var hiddenSafeTileCount: Int {
        tiles.flatMap { $0 }.filter { !$0.hasMine && $0.state == .hidden }.count
    }

    var revealedCount: Int {
        tiles.flatMap { $0 }.filter { $0.state == .revealed }.count
    }

    var totalSafeTiles: Int {
        tiles.flatMap { $0 }.filter { !$0.hasMine }.count
    }

    var isSolvable: Bool {
        status == .active && hiddenSafeTileCount > 0
    }

    var isSolved: Bool {
        hiddenSafeTileCount == 0 && status != .locked
    }

    func tile(atLocalX x: Int, localY y: Int) -> Tile? {
        guard x >= 0, x < Constants.sectorSize, y >= 0, y < Constants.sectorSize else { return nil }
        return tiles[y][x]
    }

    func setTile(_ tile: Tile, atLocalX x: Int, localY y: Int) {
        guard x >= 0, x < Constants.sectorSize, y >= 0, y < Constants.sectorSize else { return }
        tiles[y][x] = tile
        isModified = true
    }
}
