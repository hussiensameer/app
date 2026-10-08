import Foundation

/// A `RandomNumberGenerator` wrapper that lets the solver take either the
/// system generator or a seeded one without becoming generic.
struct AnyRNG: RandomNumberGenerator {
    private var base: any RandomNumberGenerator

    init(_ base: any RandomNumberGenerator) {
        self.base = base
    }

    mutating func next() -> UInt64 {
        base.next()
    }
}

/// Deterministic generator (SplitMix64) so a given level always produces the same puzzle.
struct SeededGenerator: RandomNumberGenerator {
    private var state: UInt64

    init(seed: UInt64) {
        state = seed
    }

    mutating func next() -> UInt64 {
        state &+= 0x9E37_79B9_7F4A_7C15
        var z = state
        z = (z ^ (z >> 30)) &* 0xBF58_476D_1CE4_E5B9
        z = (z ^ (z >> 27)) &* 0x94D0_49BB_1331_11EB
        return z ^ (z >> 31)
    }
}

/// Backtracking Sudoku solver using bitmasks and the "fewest candidates first" heuristic.
/// Grids are flat arrays of 81 integers, row by row, where 0 means empty.
enum SudokuSolver {
    static let size = 81

    /// Returns the first solution found, or `nil` if the grid is invalid or unsolvable.
    static func solve(_ grid: [Int]) -> [Int]? {
        guard var search = Search(grid: grid, limit: 1, rng: nil) else { return nil }
        search.run()
        return search.solutions.first
    }

    /// Counts solutions, stopping once `limit` is reached. A proper puzzle returns exactly 1.
    static func countSolutions(_ grid: [Int], limit: Int = 2) -> Int {
        guard var search = Search(grid: grid, limit: limit, rng: nil) else { return 0 }
        search.run()
        return search.solutions.count
    }

    /// Fills the grid with a random complete solution (used by the generator).
    static func randomSolution(from grid: [Int], using rng: AnyRNG) -> [Int]? {
        guard var search = Search(grid: grid, limit: 1, rng: rng) else { return nil }
        search.run()
        return search.solutions.first
    }

    /// Indices of non-empty cells that repeat a digit within their row, column or box.
    static func conflictingCells(in grid: [Int]) -> Set<Int> {
        guard grid.count == size else { return [] }
        var result = Set<Int>()
        for i in 0..<size where grid[i] != 0 {
            for j in (i + 1)..<size where grid[j] == grid[i] && shareUnit(i, j) {
                result.insert(i)
                result.insert(j)
            }
        }
        return result
    }

    static func hasConflicts(_ grid: [Int]) -> Bool {
        !conflictingCells(in: grid).isEmpty
    }

    /// True when the grid is completely filled with no conflicts.
    static func isSolved(_ grid: [Int]) -> Bool {
        grid.count == size && !grid.contains(0) && !hasConflicts(grid)
    }

    private static func shareUnit(_ a: Int, _ b: Int) -> Bool {
        let (ra, ca) = (a / 9, a % 9)
        let (rb, cb) = (b / 9, b % 9)
        return ra == rb || ca == cb || (ra / 3 == rb / 3 && ca / 3 == cb / 3)
    }

    private struct Search {
        var cells: [Int]
        var rows = [Int](repeating: 0, count: 9)
        var cols = [Int](repeating: 0, count: 9)
        var boxes = [Int](repeating: 0, count: 9)
        var solutions: [[Int]] = []
        let limit: Int
        var rng: AnyRNG?

        /// Fails (returns nil) when the grid has the wrong size, bad digits or conflicting givens.
        init?(grid: [Int], limit: Int, rng: AnyRNG?) {
            guard grid.count == SudokuSolver.size else { return nil }
            cells = grid
            self.limit = limit
            self.rng = rng
            for i in 0..<SudokuSolver.size {
                let digit = grid[i]
                guard (0...9).contains(digit) else { return nil }
                if digit == 0 { continue }
                let bit = 1 << (digit - 1)
                let (r, c, b) = (i / 9, i % 9, (i / 27) * 3 + (i % 9) / 3)
                if (rows[r] | cols[c] | boxes[b]) & bit != 0 { return nil }
                rows[r] |= bit
                cols[c] |= bit
                boxes[b] |= bit
            }
        }

        mutating func run() {
            var best = -1
            var bestMask = 0
            var bestCount = 10
            for i in 0..<SudokuSolver.size where cells[i] == 0 {
                let used = rows[i / 9] | cols[i % 9] | boxes[(i / 27) * 3 + (i % 9) / 3]
                let mask = ~used & 0x1FF
                let count = mask.nonzeroBitCount
                if count < bestCount {
                    best = i
                    bestMask = mask
                    bestCount = count
                    if count <= 1 { break }
                }
            }

            if best == -1 {
                solutions.append(cells)
                return
            }
            if bestCount == 0 { return }

            var digits = (1...9).filter { bestMask & (1 << ($0 - 1)) != 0 }
            if rng != nil {
                digits.shuffle(using: &rng!)
            }

            let (r, c, b) = (best / 9, best % 9, (best / 27) * 3 + (best % 9) / 3)
            for digit in digits {
                let bit = 1 << (digit - 1)
                cells[best] = digit
                rows[r] |= bit
                cols[c] |= bit
                boxes[b] |= bit
                run()
                rows[r] &= ~bit
                cols[c] &= ~bit
                boxes[b] &= ~bit
                cells[best] = 0
                if solutions.count >= limit { return }
            }
        }
    }
}
