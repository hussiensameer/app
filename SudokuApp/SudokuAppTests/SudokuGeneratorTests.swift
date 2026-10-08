import XCTest
@testable import SudokuApp

final class SudokuGeneratorTests: XCTestCase {
    func testEveryDifficultyHasAUniqueSolution() {
        for difficulty in Difficulty.allCases {
            for level in 1...3 {
                let generated = SudokuGenerator.generate(difficulty: difficulty, level: level)
                XCTAssertEqual(SudokuSolver.countSolutions(generated.puzzle, limit: 2), 1,
                               "\(difficulty) level \(level) must have exactly one solution")
            }
        }
    }

    func testStoredSolutionIsValidAndMatchesPuzzle() throws {
        for difficulty in Difficulty.allCases {
            let generated = SudokuGenerator.generate(difficulty: difficulty, level: 7)
            XCTAssertTrue(SudokuSolver.isSolved(generated.solution))
            XCTAssertEqual(SudokuSolver.solve(generated.puzzle), generated.solution)
            for i in 0..<81 where generated.puzzle[i] != 0 {
                XCTAssertEqual(generated.puzzle[i], generated.solution[i])
            }
        }
    }

    func testHarderLevelsHaveFewerClues() {
        func averageClues(_ difficulty: Difficulty) -> Double {
            let counts = (1...3).map { SudokuGenerator.generate(difficulty: difficulty, level: $0).clueCount }
            return Double(counts.reduce(0, +)) / Double(counts.count)
        }
        XCTAssertGreaterThan(averageClues(.easy), averageClues(.medium))
        XCTAssertGreaterThan(averageClues(.medium), averageClues(.hard))
        XCTAssertGreaterThan(averageClues(.hard), averageClues(.expert))
    }

    func testClueCountsStayNearTheTarget() {
        for difficulty in Difficulty.allCases {
            let generated = SudokuGenerator.generate(difficulty: difficulty, level: 1)
            XCTAssertLessThanOrEqual(generated.clueCount, difficulty.targetClues + 3)
            XCTAssertGreaterThanOrEqual(generated.clueCount, 17)
        }
    }

    func testSameLevelGivesSamePuzzle() {
        let a = SudokuGenerator.generate(difficulty: .hard, level: 12)
        let b = SudokuGenerator.generate(difficulty: .hard, level: 12)
        XCTAssertEqual(a, b)
    }

    func testDifferentLevelsGiveDifferentPuzzles() {
        let a = SudokuGenerator.generate(difficulty: .medium, level: 1)
        let b = SudokuGenerator.generate(difficulty: .medium, level: 2)
        XCTAssertNotEqual(a.puzzle, b.puzzle)
    }

    func testEndlessLevels() {
        // Levels keep coming, including large level numbers.
        for level in [1, 100, 10_000, 1_000_000] {
            let generated = SudokuGenerator.generate(difficulty: .easy, level: level)
            XCTAssertEqual(SudokuSolver.countSolutions(generated.puzzle, limit: 2), 1)
        }
    }
}
