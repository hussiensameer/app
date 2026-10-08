import SwiftUI

@MainActor
final class SolverViewModel: ObservableObject {
    @Published private(set) var cells = [Int](repeating: 0, count: 81)
    @Published private(set) var kinds = [CellKind](repeating: .given, count: 81)
    @Published var selected: Int?
    @Published private(set) var message: String?
    @Published private(set) var isSolved = false

    var conflicts: Set<Int> { SudokuSolver.conflictingCells(in: cells) }

    func enter(_ digit: Int) {
        guard let index = selected else { return }
        resetSolution()
        cells[index] = digit
        kinds[index] = .given
    }

    func erase() {
        guard let index = selected else { return }
        resetSolution()
        cells[index] = 0
        kinds[index] = .given
    }

    func clear() {
        cells = [Int](repeating: 0, count: 81)
        kinds = [CellKind](repeating: .given, count: 81)
        selected = nil
        message = nil
        isSolved = false
    }

    func solve() {
        resetSolution()
        guard cells.contains(where: { $0 != 0 }) else {
            message = "أدخل بعض الأرقام أولاً"
            return
        }
        if SudokuSolver.hasConflicts(cells) {
            message = "هناك أرقام مكررة (بالأحمر). صحّحها ثم حاول مجدداً"
            return
        }
        let givens = cells
        guard let solution = SudokuSolver.solve(givens) else {
            message = "لا يوجد حلّ لهذا اللغز"
            return
        }
        let unique = SudokuSolver.countSolutions(givens, limit: 2) == 1
        for i in 0..<81 where givens[i] == 0 {
            cells[i] = solution[i]
            kinds[i] = .solved
        }
        selected = nil
        isSolved = true
        message = unique ? nil : "للغز أكثر من حلّ، هذا أحدها"
    }

    /// Removes a previously shown solution so the user can edit the givens again.
    private func resetSolution() {
        for i in 0..<81 where kinds[i] == .solved {
            cells[i] = 0
            kinds[i] = .given
        }
        isSolved = false
        message = nil
    }
}

struct SolverView: View {
    @StateObject private var model = SolverViewModel()

    var body: some View {
        VStack(spacing: 16) {
            Text("أدخل اللغز ثم اضغط «حلّ»")
                .foregroundColor(Theme.muted)

            BoardView(
                cells: model.cells,
                kinds: model.kinds,
                selected: model.selected,
                conflicts: model.conflicts,
                onTap: { model.selected = $0 }
            )

            NumberPad(onDigit: model.enter, onErase: model.erase)

            if let message = model.message {
                Text(message)
                    .font(.callout)
                    .foregroundColor(Theme.primary)
                    .multilineTextAlignment(.center)
            }

            HStack {
                Button("حلّ") { model.solve() }
                    .buttonStyle(.themed(.primary))
                Button("مسح الكل") { model.clear() }
                    .buttonStyle(.themed())
            }
            Spacer(minLength: 0)
        }
        .padding()
        .background(Theme.background.ignoresSafeArea())
        #if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
        #endif
    }
}
