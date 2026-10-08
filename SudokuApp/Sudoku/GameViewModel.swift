import SwiftUI

@MainActor
final class GameViewModel: ObservableObject {
    @Published var difficulty: Difficulty
    @Published var level: Int
    @Published var puzzle: Puzzle?
    @Published var values = [Int](repeating: 0, count: 81)
    @Published var notes = [UInt16](repeating: 0, count: 81)
    @Published var selected: Int?
    @Published var noteMode = false
    @Published var mistakes = 0
    @Published var hints = 0
    @Published var seconds = 0
    @Published var won = false

    private var undoStack: [(values: [Int], notes: [UInt16])] = []

    init(difficulty: Difficulty, level: Int) {
        self.difficulty = difficulty
        self.level = level
    }

    func load() async {
        let d = difficulty, l = level
        puzzle = nil
        won = false
        selected = nil
        let p = await Task.detached(priority: .userInitiated) {
            SudokuGenerator.generate(difficulty: d, level: l)
        }.value
        values = p.givens
        notes = [UInt16](repeating: 0, count: 81)
        undoStack = []
        mistakes = 0
        hints = 0
        seconds = 0
        puzzle = p
    }

    var fixed: [Bool] { puzzle?.givens.map { $0 != 0 } ?? [Bool](repeating: false, count: 81) }

    var wrong: [Bool] {
        guard let p = puzzle else { return [Bool](repeating: false, count: 81) }
        return (0..<81).map { values[$0] != 0 && p.givens[$0] == 0 && values[$0] != p.solution[$0] }
    }

    func remaining(_ d: Int) -> Int { 9 - values.filter { $0 == d }.count }

    func tick() {
        if puzzle != nil && !won { seconds += 1 }
    }

    private func bit(_ d: Int) -> UInt16 { UInt16(1) << UInt16(d) }

    private func pushUndo() {
        undoStack.append((values, notes))
        if undoStack.count > 200 { undoStack.removeFirst() }
    }

    private func isEditable(_ i: Int) -> Bool { puzzle?.givens[i] == 0 }

    func enter(_ d: Int) {
        guard let s = selected, let p = puzzle, !won, isEditable(s) else { return }
        if noteMode {
            guard values[s] == 0 else { return }
            pushUndo()
            notes[s] ^= bit(d)
            return
        }
        pushUndo()
        if values[s] == d {
            values[s] = 0
            return
        }
        values[s] = d
        notes[s] = 0
        if d != p.solution[s] {
            mistakes += 1
        } else {
            for j in 0..<81 where isPeer(s, j) { notes[j] &= ~bit(d) }
        }
        checkWin()
    }

    func erase() {
        guard let s = selected, !won, isEditable(s) else { return }
        pushUndo()
        values[s] = 0
        notes[s] = 0
    }

    func undo() {
        guard !won, let last = undoStack.popLast() else { return }
        values = last.values
        notes = last.notes
    }

    func hint() {
        guard let s = selected, let p = puzzle, !won, isEditable(s), values[s] != p.solution[s] else { return }
        pushUndo()
        values[s] = p.solution[s]
        notes[s] = 0
        hints += 1
        for j in 0..<81 where isPeer(s, j) { notes[j] &= ~bit(p.solution[s]) }
        checkWin()
    }

    private func checkWin() {
        if let p = puzzle, values == p.solution { won = true }
    }
}
