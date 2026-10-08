import SwiftUI

// MARK: - Random

/// مولّد عشوائي ثابت (seeded) حتى يكون كل مستوى رقمه نفس اللغز دائماً.
struct SplitMix64: RandomNumberGenerator {
    var state: UInt64
    init(seed: UInt64) { state = seed }
    mutating func next() -> UInt64 {
        state &+= 0x9E3779B97F4A7C15
        var z = state
        z = (z ^ (z >> 30)) &* 0xBF58476D1CE4E5B9
        z = (z ^ (z >> 27)) &* 0x94D049BB133111EB
        return z ^ (z >> 31)
    }
}

// MARK: - Difficulty

enum Difficulty: String, CaseIterable, Identifiable, Hashable {
    case easy, medium, hard, expert, master

    var id: String { rawValue }

    var title: String {
        switch self {
        case .easy: return "سهل"
        case .medium: return "متوسط"
        case .hard: return "صعب"
        case .expert: return "خبير"
        case .master: return "أسطوري"
        }
    }

    /// عدد الأرقام الظاهرة المستهدف (كلما قلّ صار أصعب).
    var clues: Int {
        switch self {
        case .easy: return 40
        case .medium: return 34
        case .hard: return 30
        case .expert: return 26
        case .master: return 22
        }
    }

    var color: Color {
        switch self {
        case .easy: return Color(hex: 0x5ba55b)
        case .medium: return Theme.secondary
        case .hard: return Color(hex: 0xf5a623)
        case .expert: return Theme.primary
        case .master: return Color(hex: 0x7e57c2)
        }
    }

    var seedBase: UInt64 {
        switch self {
        case .easy: return 1_000_003
        case .medium: return 2_000_029
        case .hard: return 3_000_017
        case .expert: return 4_000_037
        case .master: return 5_000_011
        }
    }
}

struct Puzzle {
    let difficulty: Difficulty
    let level: Int
    let givens: [Int]
    let solution: [Int]
}

// MARK: - Solver

enum SolveResult {
    case invalid            // الأرقام المدخلة متعارضة
    case none               // لا يوجد حل
    case unique([Int])      // حل وحيد
    case multiple([Int])    // أكثر من حل (يُعرض أحدها)
}

struct SudokuSolver {
    private var grid: [Int]
    private var rows = [Int](repeating: 0, count: 9)
    private var cols = [Int](repeating: 0, count: 9)
    private var boxes = [Int](repeating: 0, count: 9)
    private var rng: SplitMix64
    private let randomize: Bool
    private let limit: Int
    private(set) var count = 0
    private(set) var firstSolution: [Int]?

    /// يرجع nil إذا كانت الأرقام الأولية متعارضة.
    init?(_ start: [Int], limit: Int, seed: UInt64? = nil) {
        grid = start
        self.limit = limit
        randomize = seed != nil
        rng = SplitMix64(seed: seed ?? 0)
        for i in 0..<81 where start[i] != 0 {
            let bit = 1 << start[i]
            let r = i / 9, c = i % 9, b = (r / 3) * 3 + c / 3
            if rows[r] & bit != 0 || cols[c] & bit != 0 || boxes[b] & bit != 0 { return nil }
            rows[r] |= bit; cols[c] |= bit; boxes[b] |= bit
        }
    }

    mutating func run() {
        count = 0
        firstSolution = nil
        search()
    }

    private mutating func search() {
        if count >= limit { return }
        var best = -1
        var bestMask = 0
        var bestCount = 10
        for i in 0..<81 where grid[i] == 0 {
            let r = i / 9, c = i % 9, b = (r / 3) * 3 + c / 3
            let avail = ~(rows[r] | cols[c] | boxes[b]) & 0x3FE
            let n = avail.nonzeroBitCount
            if n == 0 { return }
            if n < bestCount {
                bestCount = n; best = i; bestMask = avail
                if n == 1 { break }
            }
        }
        if best == -1 {
            count += 1
            if firstSolution == nil { firstSolution = grid }
            return
        }
        var digits = (1...9).filter { bestMask & (1 << $0) != 0 }
        if randomize { digits.shuffle(using: &rng) }
        let r = best / 9, c = best % 9, b = (r / 3) * 3 + c / 3
        for d in digits {
            let bit = 1 << d
            grid[best] = d
            rows[r] |= bit; cols[c] |= bit; boxes[b] |= bit
            search()
            grid[best] = 0
            rows[r] &= ~bit; cols[c] &= ~bit; boxes[b] &= ~bit
            if count >= limit { return }
        }
    }

    static func solve(_ grid: [Int]) -> SolveResult {
        guard var s = SudokuSolver(grid, limit: 2) else { return .invalid }
        s.run()
        guard let sol = s.firstSolution else { return .none }
        return s.count == 1 ? .unique(sol) : .multiple(sol)
    }
}

// MARK: - Generator

enum SudokuGenerator {
    /// يولّد لغزاً بحل وحيد. نفس (difficulty, level) يعطي دائماً نفس اللغز.
    static func generate(difficulty: Difficulty, level: Int) -> Puzzle {
        var rng = SplitMix64(seed: difficulty.seedBase &+ UInt64(max(level, 1)) &* 0x9E3779B97F4A7C15)

        var filler = SudokuSolver([Int](repeating: 0, count: 81), limit: 1, seed: rng.next())!
        filler.run()
        let solution = filler.firstSolution!

        var grid = solution
        var filled = 81
        for idx in (0..<81).shuffled(using: &rng) {
            if filled <= difficulty.clues { break }
            let saved = grid[idx]
            grid[idx] = 0
            var checker = SudokuSolver(grid, limit: 2)!
            checker.run()
            if checker.count == 1 {
                filled -= 1
            } else {
                grid[idx] = saved
            }
        }
        return Puzzle(difficulty: difficulty, level: level, givens: grid, solution: solution)
    }
}

@inline(__always)
func isPeer(_ i: Int, _ j: Int) -> Bool {
    i / 9 == j / 9 || i % 9 == j % 9 || (i / 27 == j / 27 && (i % 9) / 3 == (j % 9) / 3)
}
