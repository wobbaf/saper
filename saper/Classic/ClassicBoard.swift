import Foundation

/// Fixed-size minesweeper board for classic mode.
class ClassicBoard {
    let columns: Int
    let rows: Int
    let mineCount: Int
    var tiles: [[Tile]]
    private(set) var isGenerated: Bool = false

    init(difficulty: ClassicDifficulty) {
        self.columns = difficulty.columns
        self.rows = difficulty.rows
        self.mineCount = difficulty.mineCount
        self.tiles = Array(
            repeating: Array(repeating: Tile(), count: difficulty.columns),
            count: difficulty.rows
        )
    }

    // MARK: - Mine Placement

    /// Place mines randomly, excluding a 3×3 safe zone around the first click.
    func generateMines(safeCol: Int, safeRow: Int) {
        guard !isGenerated else { return }
        isGenerated = true

        // Build list of valid positions (excluding 3×3 around safe click)
        var candidates: [(Int, Int)] = []
        for r in 0..<rows {
            for c in 0..<columns {
                if abs(c - safeCol) <= 1 && abs(r - safeRow) <= 1 {
                    continue
                }
                candidates.append((c, r))
            }
        }

        candidates.shuffle()

        let count = min(mineCount, candidates.count)
        for i in 0..<count {
            let (c, r) = candidates[i]
            tiles[r][c].hasMine = true
        }

        computeAllAdjacentCounts()
    }

    // MARK: - Adjacent Counts

    func computeAllAdjacentCounts() {
        for r in 0..<rows {
            for c in 0..<columns {
                tiles[r][c].adjacentMineCount = adjacentMineCount(col: c, row: r)
            }
        }
    }

    func adjacentMineCount(col: Int, row: Int) -> Int {
        var count = 0
        for dr in -1...1 {
            for dc in -1...1 {
                if dr == 0 && dc == 0 { continue }
                let nc = col + dc
                let nr = row + dr
                if inBounds(col: nc, row: nr) && tiles[nr][nc].hasMine {
                    count += 1
                }
            }
        }
        return count
    }

    // MARK: - Flood Fill

    /// BFS flood fill starting from a 0-count tile. Returns all revealed positions.
    func floodFill(startCol: Int, startRow: Int) -> [(col: Int, row: Int)] {
        var revealed: [(Int, Int)] = []
        var visited = Set<Int>()
        var queue: [(Int, Int)] = [(startCol, startRow)]

        func key(_ c: Int, _ r: Int) -> Int { r * columns + c }

        visited.insert(key(startCol, startRow))

        while !queue.isEmpty {
            let (c, r) = queue.removeFirst()

            tiles[r][c].state = .revealed
            revealed.append((c, r))

            guard tiles[r][c].adjacentMineCount == 0 else { continue }

            for dr in -1...1 {
                for dc in -1...1 {
                    if dr == 0 && dc == 0 { continue }
                    let nc = c + dc
                    let nr = r + dr
                    guard inBounds(col: nc, row: nr) else { continue }
                    let k = key(nc, nr)
                    guard !visited.contains(k) else { continue }
                    guard tiles[nr][nc].state == .hidden else { continue }
                    guard !tiles[nr][nc].hasMine else { continue }
                    visited.insert(k)
                    queue.append((nc, nr))
                }
            }
        }

        return revealed
    }

    // MARK: - Queries

    var flagCount: Int {
        tiles.reduce(0) { sum, row in
            sum + row.filter { $0.state == .flagged }.count
        }
    }

    var isWon: Bool {
        for r in 0..<rows {
            for c in 0..<columns {
                if !tiles[r][c].hasMine && tiles[r][c].state != .revealed {
                    return false
                }
            }
        }
        return isGenerated
    }

    func revealAllMines() {
        for r in 0..<rows {
            for c in 0..<columns {
                if tiles[r][c].hasMine && tiles[r][c].state != .flagged {
                    tiles[r][c].state = .mine
                }
            }
        }
    }

    func inBounds(col: Int, row: Int) -> Bool {
        col >= 0 && col < columns && row >= 0 && row < rows
    }
}
