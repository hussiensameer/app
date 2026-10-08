import SwiftUI

/// أدخل أرقام لغز سودوكو من ورقة أو مجلة ثم اضغط «حلّ».
struct SolverView: View {
    @State private var user = [Int](repeating: 0, count: 81)
    @State private var solution: [Int]?
    @State private var selected: Int?
    @State private var message = "اختر خانة ثم اكتب الرقم."
    @State private var messageIsError = false

    private static let sample = "530070000600195000098000060800060003400803001700020006060000280000419005000080079"

    private var shown: [Int] { (0..<81).map { user[$0] != 0 ? user[$0] : (solution?[$0] ?? 0) } }
    private var fixed: [Bool] { user.map { $0 != 0 } }

    private var conflicts: [Bool] {
        (0..<81).map { i in
            user[i] != 0 && (0..<81).contains { $0 != i && user[$0] == user[i] && isPeer(i, $0) }
        }
    }

    var body: some View {
        VStack(spacing: 14) {
            Text(message)
                .font(.subheadline)
                .foregroundColor(messageIsError ? Theme.primary : Theme.muted)
                .multilineTextAlignment(.center)
                .frame(minHeight: 36)

            BoardView(values: shown, fixed: fixed, notes: [UInt16](repeating: 0, count: 81),
                      wrong: conflicts, selected: selected) { selected = $0 }

            NumberPad { digit in
                guard let s = selected else { return }
                user[s] = digit
                solution = nil
                setMessage("اختر خانة ثم اكتب الرقم.")
            }

            HStack(spacing: 8) {
                Button("مسح الخانة") {
                    if let s = selected { user[s] = 0; solution = nil }
                }.buttonStyle(ThemeButtonStyle())
                Button("مسح الكل") {
                    user = [Int](repeating: 0, count: 81); solution = nil
                    setMessage("اختر خانة ثم اكتب الرقم.")
                }.buttonStyle(ThemeButtonStyle())
                Button("مثال") { loadSample() }.buttonStyle(ThemeButtonStyle())
            }

            Button { solve() } label: { Label("حلّ", systemImage: "checkmark.seal") }
                .buttonStyle(ThemeButtonStyle(kind: .primary))
        }
        .padding(.horizontal, 12)
        .padding(.bottom, 8)
        .background(Theme.background.ignoresSafeArea())
        .navigationTitle("حلّال سودوكو")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func setMessage(_ text: String, error: Bool = false) {
        message = text
        messageIsError = error
    }

    private func loadSample() {
        user = Self.sample.map { Int(String($0)) ?? 0 }
        solution = nil
        setMessage("تم تحميل لغز مثال. اضغط «حلّ».")
    }

    private func solve() {
        if user.allSatisfy({ $0 == 0 }) {
            setMessage("أدخل أرقام اللغز أولاً.", error: true)
            return
        }
        switch SudokuSolver.solve(user) {
        case .invalid:
            setMessage("الأرقام المدخلة فيها تعارض (مكررة بنفس الصف أو العمود أو المربع).", error: true)
        case .none:
            setMessage("هذا اللغز ما إله حل. تأكد من الأرقام.", error: true)
        case .unique(let s):
            solution = s
            setMessage("تم الحل ✅ (الأرقام الزرقاء هي الحل)")
        case .multiple(let s):
            solution = s
            setMessage("اللغز عنده أكثر من حل، عُرض أحدها (الأزرق).")
        }
    }
}
