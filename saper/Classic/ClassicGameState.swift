import Foundation
import Combine

/// Game state for classic (finite board) minesweeper mode.
class ClassicGameState: ObservableObject {
    @Published var difficulty: ClassicDifficulty
    @Published var board: ClassicBoard
    @Published var elapsedSeconds: Int = 0
    @Published var isGameOver: Bool = false
    @Published var isWon: Bool = false
    @Published var smileyState: SmileyState = .happy

    enum SmileyState {
        case happy
        case surprised
        case cool
        case dead
    }

    @Published var undoCount: Int = 3
    /// Whether the player can undo the last mine hit (only available right after hitting a mine).
    @Published var canUndo: Bool = false

    var minesRemaining: Int {
        board.mineCount - board.flagCount
    }

    private var timer: Timer?
    private var timerRunning: Bool = false

    /// Snapshot of all tile states taken before each reveal action, used for undo.
    private var tileSnapshot: [[TileState]] = []

    // Scene callbacks
    var onTileRevealed: ((Int, Int) -> Void)?
    var onTilesRevealed: (([( Int, Int)]) -> Void)?
    var onTileStateChanged: ((Int, Int) -> Void)?
    var onMineHit: ((Int, Int) -> Void)?
    var onGameWon: (() -> Void)?
    var onBoardReset: (() -> Void)?

    init(difficulty: ClassicDifficulty) {
        self.difficulty = difficulty
        self.board = ClassicBoard(difficulty: difficulty)
    }

    // MARK: - Actions

    func revealTile(col: Int, row: Int) {
        guard !isGameOver && !isWon else { return }
        guard board.inBounds(col: col, row: row) else { return }

        let tile = board.tiles[row][col]
        guard tile.state == .hidden else {
            // Chord reveal on already-revealed numbered tiles
            if tile.state == .revealed && tile.adjacentMineCount > 0 {
                chordReveal(col: col, row: row)
            }
            return
        }

        // First click — generate mines
        if !board.isGenerated {
            board.generateMines(safeCol: col, safeRow: row)
            startTimer()
        }

        // Save snapshot before action
        saveTileSnapshot()
        canUndo = false

        // Mine hit
        if board.tiles[row][col].hasMine {
            board.tiles[row][col].state = .mine
            board.revealAllMines()
            isGameOver = true
            smileyState = .dead
            stopTimer()
            canUndo = undoCount > 0
            AudioManager.shared.play(.mineExplosion)
            HapticsManager.shared.play(.mineHit)
            onMineHit?(col, row)
            return
        }

        // Safe reveal
        board.tiles[row][col].state = .revealed
        let count = board.tiles[row][col].adjacentMineCount

        if count == 0 {
            let filled = board.floodFill(startCol: col, startRow: row)
            AudioManager.shared.play(.floodFill)
            HapticsManager.shared.play(.floodFillTap)
            onTilesRevealed?(filled)
        } else {
            AudioManager.shared.play(.tileReveal(number: count))
            HapticsManager.shared.play(.tileReveal(number: count))
            onTileRevealed?(col, row)
        }

        checkWin()
    }

    func toggleFlag(col: Int, row: Int) {
        guard !isGameOver && !isWon else { return }
        guard board.inBounds(col: col, row: row) else { return }

        let tile = board.tiles[row][col]
        switch tile.state {
        case .hidden:
            board.tiles[row][col].state = .flagged
            AudioManager.shared.play(.flagPlace)
            HapticsManager.shared.play(.flagPlaced)
        case .flagged:
            board.tiles[row][col].state = .hidden
            AudioManager.shared.play(.flagRemove)
            HapticsManager.shared.play(.flagRemoved)
        default:
            return
        }
        onTileStateChanged?(col, row)
    }

    func chordReveal(col: Int, row: Int) {
        guard !isGameOver && !isWon else { return }
        guard board.inBounds(col: col, row: row) else { return }

        let tile = board.tiles[row][col]
        guard tile.state == .revealed && tile.adjacentMineCount > 0 else { return }

        // Save snapshot before action
        saveTileSnapshot()
        canUndo = false

        // Count adjacent flags
        var flagCount = 0
        for dr in -1...1 {
            for dc in -1...1 {
                if dr == 0 && dc == 0 { continue }
                let nc = col + dc
                let nr = row + dr
                if board.inBounds(col: nc, row: nr) && board.tiles[nr][nc].state == .flagged {
                    flagCount += 1
                }
            }
        }

        guard flagCount == tile.adjacentMineCount else { return }

        // Reveal all hidden neighbors
        var revealed: [(Int, Int)] = []
        var hitMine = false

        for dr in -1...1 {
            for dc in -1...1 {
                if dr == 0 && dc == 0 { continue }
                let nc = col + dc
                let nr = row + dr
                guard board.inBounds(col: nc, row: nr) else { continue }
                guard board.tiles[nr][nc].state == .hidden else { continue }

                if board.tiles[nr][nc].hasMine {
                    board.tiles[nr][nc].state = .mine
                    hitMine = true
                } else {
                    board.tiles[nr][nc].state = .revealed
                    if board.tiles[nr][nc].adjacentMineCount == 0 {
                        let filled = board.floodFill(startCol: nc, startRow: nr)
                        revealed.append(contentsOf: filled)
                    } else {
                        revealed.append((nc, nr))
                    }
                }
            }
        }

        if hitMine {
            board.revealAllMines()
            isGameOver = true
            smileyState = .dead
            stopTimer()
            canUndo = undoCount > 0
            AudioManager.shared.play(.mineExplosion)
            HapticsManager.shared.play(.mineHit)
            onMineHit?(col, row)
        } else if !revealed.isEmpty {
            AudioManager.shared.play(.chordReveal)
            HapticsManager.shared.play(.chordReveal)
            onTilesRevealed?(revealed)
            checkWin()
        }
    }

    // MARK: - Win Check

    private func checkWin() {
        if board.isWon {
            isWon = true
            smileyState = .cool
            stopTimer()
            // Auto-flag remaining mines
            for r in 0..<board.rows {
                for c in 0..<board.columns {
                    if board.tiles[r][c].hasMine && board.tiles[r][c].state == .hidden {
                        board.tiles[r][c].state = .flagged
                    }
                }
            }
            AudioManager.shared.playCompound(SoundEffect.sectorSolvedChord)
            HapticsManager.shared.play(.sectorSolved)
            recordLeaderboardEntry()
            onGameWon?()
        }
    }

    /// Records a leaderboard entry for a classic win.
    private func recordLeaderboardEntry() {
        let seconds = elapsedSeconds
        let minutes = seconds / 60
        let secs = seconds % 60
        let timeStr = minutes > 0 ? "\(minutes)m \(secs)s" : "\(secs)s"
        let entry = LeaderboardEntry(
            score: seconds,
            mode: "classic_\(difficulty.rawValue)",
            detail: timeStr
        )
        LeaderboardPersistence.addEntry(entry)
    }

    // MARK: - Undo

    private func saveTileSnapshot() {
        tileSnapshot = board.tiles.map { row in row.map { $0.state } }
    }

    /// Undo the last mine hit — restores tile states to the snapshot before the action.
    func undoMineHit() {
        guard canUndo, undoCount > 0, isGameOver, !tileSnapshot.isEmpty else { return }

        undoCount -= 1
        canUndo = false

        // Restore tile states from snapshot
        for r in 0..<board.rows {
            for c in 0..<board.columns {
                board.tiles[r][c].state = tileSnapshot[r][c]
            }
        }
        tileSnapshot = []

        isGameOver = false
        smileyState = .happy
        startTimer()

        AudioManager.shared.play(.boosterUsed)
        HapticsManager.shared.play(.boosterRevealOne)
        onBoardReset?()
    }

    // MARK: - Timer

    private func startTimer() {
        guard !timerRunning else { return }
        timerRunning = true
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            DispatchQueue.main.async {
                self.elapsedSeconds += 1
            }
        }
    }

    private func stopTimer() {
        timer?.invalidate()
        timer = nil
        timerRunning = false
    }

    // MARK: - Restart

    func restartGame() {
        stopTimer()
        board = ClassicBoard(difficulty: difficulty)
        elapsedSeconds = 0
        isGameOver = false
        isWon = false
        smileyState = .happy
        canUndo = false
        tileSnapshot = []
        undoCount = 3
        onBoardReset?()
    }

    func newGame(difficulty: ClassicDifficulty) {
        self.difficulty = difficulty
        restartGame()
    }

    deinit {
        stopTimer()
    }
}
