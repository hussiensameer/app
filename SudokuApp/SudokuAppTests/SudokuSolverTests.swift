import XCTest
@testable import SudokuApp

final class SudokuSolverTests: XCTestCase {
    private let puzzle = SudokuSolverTests.parse(
        "530070000600195000098000060800060003400803001700020006060000280000419005000080079")
    private let solution = SudokuSolverTests.parse(
        "534678912672195348198342567859761423426853791713924856961537284287419635345286179")

    static func parse(_ string: String) -> [Int] {
        string.compactMap { $0.wholeNumberValue }
    }

    func testSolvesKnownPuzzle() {
        XCTAssertEqual(SudokuSolver.solve(puzzle), solution)
    }

    func testKnownPuzzleHasExactlyOneSolution() {
        XCTAssertEqual(SudokuSolver.countSolutions(puzzle, limit: 2), 1)
    }

    func testSolvedGridIsReturnedUnchanged() {
        XCTAssertEqual(SudokuSolver.solve(solution), solution)
        XCTAssertTrue(SudokuSolver.isSolved(solution))
    }

    func testEmptyGridHasManySolutionsAndIsSolvable() {
        let empty = [Int](repeating: 0, count: 81)
        XCTAssertEqual(SudokuSolver.countSolutions(empty, limit: 2), 2)
        let solved = SudokuSolver.solve(empty)
        XCTAssertNotNil(solved)
        XCTAssertTrue(SudokuSolver.isSolved(solved ?? []))
    }

    func testSolutionKeepsTheGivens() throws {
        let solved = try XCTUnwrap(SudokuSolver.solve(puzzle))
        for i in 0..<81 where puzzle[i] != 0 {
            XCTAssertEqual(solved[i], puzzle[i])
        }
    }

    func testDuplicateGivensAreRejected() {
        var grid = [Int](repeating: 0, count: 81)
        grid[0] = 5
        grid[8] = 5   // same row
        XCTAssertEqual(SudokuSolver.conflictingCells(in: grid), [0, 8])
        XCTAssertNil(SudokuSolver.solve(grid))
        XCTAssertEqual(SudokuSolver.countSolutions(grid), 0)
    }

    func testConflictsInColumnAndBox() {
        var grid = [Int](repeating: 0, count: 81)
        grid[0] = 3
        grid[27] = 3  // same column
        grid[10] = 3  // same box
        XCTAssertEqual(SudokuSolver.conflictingCells(in: grid), [0, 27, 10])
    }

    func testUnsolvableGridReturnsNil() {
        // Row 0 holds 1-8, so its last cell needs a 9, but a 9 already sits below it in the same column.
        var grid = [Int](repeating: 0, count: 81)
        for c in 0..<8 { grid[c] = c + 1 }
        grid[9 + 8] = 9
        XCTAssertFalse(SudokuSolver.hasConflicts(grid))
        XCTAssertNil(SudokuSolver.solve(grid))
        XCTAssertEqual(SudokuSolver.countSolutions(grid), 0)
    }

    func testWrongSizeOrDigitsAreRejected() {
        XCTAssertNil(SudokuSolver.solve([1, 2, 3]))
        var grid = [Int](repeating: 0, count: 81)
        grid[4] = 12
        XCTAssertNil(SudokuSolver.solve(grid))
    }

    func testIncompleteGridIsNotSolved() {
        XCTAssertFalse(SudokuSolver.isSolved(puzzle))
    }
}
