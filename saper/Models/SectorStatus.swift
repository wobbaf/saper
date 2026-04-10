import Foundation

enum SectorStatus: Int, Codable {
    case active
    case solved
    case locked    // mine hit — pay gems to re-enter
    case inactive = 3  // not yet accessible — no adjacent solved sector
}
