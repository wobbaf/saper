import Foundation

struct Tile: Codable {
    var state: TileState = .hidden
    var hasMine: Bool = false
    var adjacentMineCount: Int = 0
    var hasGem: Bool = false
    var gemCollected: Bool = false
}
