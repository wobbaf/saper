import Foundation

enum TileState: Int, Codable {
    case hidden
    case revealed
    case mine
    case flagged
    case question  // legacy — treated as hidden on decode
}
