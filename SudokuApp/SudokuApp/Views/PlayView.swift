import SwiftUI

@MainActor
final class GameViewModel: ObservableObject {
    let difficulty: Difficulty
    @Published private(set) var level: Int
    @Published private(set) var puzzle: SudokuPuzzle?
    @Published private(set) var cells = [Int](repeating: 0, count: 81)
    @Published var selected: Int?
    @Published private(set) var isLoading = false

    init(difficulty: Difficulty) {
        self.difficulty = difficulty
        self.level = LevelStore.currentLevel(for: difficulty)
    }

    var isSolved: Bool { SudokuSolver.isSolved(cells) }
    var conflicts: Set<Int> { SudokuSolver.conflictingCells(in: cells) }

    var kinds: [CellKind] {
        guard let puzzle = puzzle else { return [CellKind](repeating: .entered, count: 81) }
        return (0..<81).map { puzzle.puzzle[$0] != 0 ? .given : .entered }
    }

    func load() {
        isLoading = true
        selected = nil
        let difficulty = difficulty
        let level = level
        Task {
            let generated = await Task.detached(priority: .userInitiated) {
                SudokuGenerator.generate(difficulty: difficulty, level: level)
            }.value
            puzzle = generated
            cells = generated.puzzle
            isLoading = false
        }
    }

    func nextLevel() {
        level += 1
        LevelStore.setCurrentLevel(level, for: difficulty)
        load()
    }

    func restart() {
        guard let puzzle = puzzle else { return }
        cells = puzzle.puzzle
        selected = nil
    }

    private func isEditable(_ index: Int) -> Bool {
        puzzle.map { $0.puzzle[index] == 0 } ?? false
    }

    func enter(_ digit: Int) {
        guard let index = selected, isEditable(index) else { return }
        cells[index] = digit
    }

    func erase() {
        guard let index = selected, isEditable(index) else { return }
        cells[index] = 0
    }

    /// Reveals the correct digit for the selected cell.
    func hint() {
        guard let index = selected, isEditable(index), let puzzle = puzzle else { return }
        cells[index] = puzzle.solution[index]
    }
}

struct PlayView: View {
    @StateObject private var model: GameViewModel

    init(difficulty: Difficulty) {
        _model = StateObject(wrappedValue: GameViewModel(difficulty: difficulty))
    }

    var body: some View {
        VStack(spacing: 16) {
            HStack {
                Text(model.difficulty.title)
                    .font(.title2)
                LevelBadge(level: model.level)
                    .foregroundColor(Theme.muted)
                    .background(Theme.border.opacity(0.4))
                    .clipShape(Capsule())
                Spacer()
            }

            ZStack {
                BoardView(
                    cells: model.cells,
                    kinds: model.kinds,
                    selected: model.selected,
                    conflicts: model.conflicts,
                    onTap: { model.selected = $0 }
                )
                if model.isLoading {
                    ProgressView().scaleEffect(1.5)
                }
            }

            if model.isSolved {
                Text("أحسنت! أكملت اللغز")
                    .font(.title3)
                    .foregroundColor(Theme.secondary)
                Button("المستوى التالي") { model.nextLevel() }
                    .buttonStyle(.themed(.primary))
            } else {
                NumberPad(onDigit: model.enter, onErase: model.erase)
                HStack {
                    Button("تلميح") { model.hint() }
                        .buttonStyle(.themed())
                    Button("إعادة") { model.restart() }
                        .buttonStyle(.themed())
                }
            }
            Spacer(minLength: 0)
        }
        .padding()
        .background(Theme.background.ignoresSafeArea())
        #if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
        #endif
        .onAppear {
            if model.puzzle == nil { model.load() }
        }
    }
}
