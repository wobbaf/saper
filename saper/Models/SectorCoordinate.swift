import Foundation

struct SectorCoordinate: Hashable, Codable {
    let x: Int
    let y: Int

    var distanceFromOrigin: Int {
        abs(x) + abs(y) // Manhattan distance
    }

    func chebyshevDistance(to other: SectorCoordinate) -> Int {
        max(abs(x - other.x), abs(y - other.y))
    }

    init(x: Int, y: Int) {
        self.x = x
        self.y = y
    }

    /// Convert global tile coordinates to sector coordinate using floor division.
    init(fromTileX tileX: Int, tileY: Int) {
        self.x = SectorCoordinate.floorDiv(tileX, Constants.sectorSize)
        self.y = SectorCoordinate.floorDiv(tileY, Constants.sectorSize)
    }

    /// The global tile coordinate of the sector's bottom-left tile.
    var originTileX: Int { x * Constants.sectorSize }
    var originTileY: Int { y * Constants.sectorSize }

    /// All 8 neighboring sector coordinates.
    var neighbors: [SectorCoordinate] {
        var result: [SectorCoordinate] = []
        for dx in -1...1 {
            for dy in -1...1 {
                if dx == 0 && dy == 0 { continue }
                result.append(SectorCoordinate(x: x + dx, y: y + dy))
            }
        }
        return result
    }

    private static func floorDiv(_ a: Int, _ b: Int) -> Int {
        let q = a / b
        let r = a - q * b
        if r != 0 && (r ^ b) < 0 {
            return q - 1
        }
        return q
    }
}
