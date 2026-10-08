import Foundation

enum Difficulty: String, CaseIterable, Identifiable, Codable {
    case easy, medium, hard, expert

    var id: String { rawValue }

    /// Arabic label shown in the UI.
    var title: String {
        switch self {
        case .easy: return "سهل"
        case .medium: return "متوسط"
        case .hard: return "صعب"
        case .expert: return "خبير"
        }
    }

    /// Number of given digits the generator tries to reach (fewer = harder).
    var targetClues: Int {
        switch self {
        case .easy: return 40
        case .medium: return 34
        case .hard: return 29
        case .expert: return 25
        }
    }

    fileprivate var seedSalt: UInt64 {
        switch self {
        case .easy: return 1
        case .medium: return 2
        case .hard: return 3
        case .expert: return 4
        }
    }
}

struct SudokuPuzzle: Equatable, Sendable {
    let puzzle: [Int]
    let solution: [Int]
    let difficulty: Difficulty

    var clueCount: Int { puzzle.filter { $0 != 0 }.count }
}

/// Builds puzzles with exactly one solution: start from a random full grid, then remove
/// digits one by one, undoing any removal that would make the solution non-unique.
enum SudokuGenerator {
    /// Deterministic: the same difficulty and level number always give the same puzzle.
    static func generate(difficulty: Difficulty, level: Int) -> SudokuPuzzle {
        let seed = UInt64(truncatingIfNeeded: level) &* 0x2545_F491_4F6C_DD1D &+ difficulty.seedSalt
        return generate(difficulty: difficulty, using: SeededGenerator(seed: seed))
    }

    static func generate(difficulty: Difficulty, using generator: some RandomNumberGenerator) -> SudokuPuzzle {
        var rng = AnyRNG(generator)
        var best: SudokuPuzzle?

        // Greedy removal sometimes stalls above the target; retry a few times and keep the best.
        for _ in 0..<6 {
            let candidate = makeCandidate(difficulty: difficulty, rng: &rng)
            if best == nil || candidate.clueCount < best!.clueCount {
                best = candidate
            }
            if candidate.clueCount <= difficulty.targetClues { break }
        }
        return best!
    }

    private static func makeCandidate(difficulty: Difficulty, rng: inout AnyRNG) -> SudokuPuzzle {
        let empty = [Int](repeating: 0, count: SudokuSolver.size)
        let solution = SudokuSolver.randomSolution(from: empty, using: rng)!
        var puzzle = solution
        var clues = SudokuSolver.size

        for index in (0..<SudokuSolver.size).shuffled(using: &rng) {
            if clues <= difficulty.targetClues { break }
            let digit = puzzle[index]
            puzzle[index] = 0
            if SudokuSolver.countSolutions(puzzle, limit: 2) == 1 {
                clues -= 1
            } else {
                puzzle[index] = digit
            }
        }
        return SudokuPuzzle(puzzle: puzzle, solution: solution, difficulty: difficulty)
    }
}
