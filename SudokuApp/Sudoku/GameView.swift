import SwiftUI

struct GameView: View {
    @EnvironmentObject private var progress: GameProgress
    @StateObject private var vm: GameViewModel
    @Environment(\.dismiss) private var dismiss
    private let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    init(difficulty: Difficulty, level: Int) {
        _vm = StateObject(wrappedValue: GameViewModel(difficulty: difficulty, level: level))
    }

    var body: some View {
        ZStack {
            VStack(spacing: 14) {
                header
                if let p = vm.puzzle {
                    BoardView(values: vm.values, fixed: vm.fixed, notes: vm.notes, wrong: vm.wrong,
                              selected: vm.selected) { vm.selected = $0 }
                        .id(p.level)
                    controls
                    NumberPad(remaining: { vm.remaining($0) }) { vm.enter($0) }
                } else {
                    Spacer()
                    ProgressView("جاري توليد اللغز…")
                    Spacer()
                }
            }
            .padding(.horizontal, 12)
            .padding(.bottom, 8)

            if vm.won { winOverlay }
        }
        .background(Theme.background.ignoresSafeArea())
        .navigationTitle("\(vm.difficulty.title) · مستوى \(vm.level)")
        .navigationBarTitleDisplayMode(.inline)
        .task(id: vm.level) { await vm.load() }
        .onReceive(timer) { _ in vm.tick() }
        .onChange(of: vm.won) { _, won in
            if won { progress.finish(vm.difficulty, level: vm.level, seconds: vm.seconds) }
        }
    }

    private var header: some View {
        HStack {
            Label(formatTime(vm.seconds), systemImage: "clock")
            Spacer()
            Label("الأخطاء: \(vm.mistakes)", systemImage: "xmark.circle")
                .foregroundColor(vm.mistakes > 0 ? Theme.primary : Theme.muted)
            Spacer()
            Label("تلميحات: \(vm.hints)", systemImage: "lightbulb")
        }
        .font(.subheadline)
        .foregroundColor(Theme.muted)
        .padding(.top, 8)
    }

    private var controls: some View {
        HStack(spacing: 8) {
            toolButton("تراجع", "arrow.uturn.backward") { vm.undo() }
            toolButton("مسح", "eraser") { vm.erase() }
            toolButton(vm.noteMode ? "ملاحظات: تشغيل" : "ملاحظات", "pencil", active: vm.noteMode) { vm.noteMode.toggle() }
            toolButton("تلميح", "lightbulb") { vm.hint() }
        }
    }

    private func toolButton(_ title: String, _ icon: String, active: Bool = false,
                            action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Image(systemName: icon).font(.title3)
                Text(title).font(.caption)
            }
            .frame(maxWidth: .infinity, minHeight: 52)
            .foregroundColor(active ? .white : .black)
            .background(RoundedRectangle(cornerRadius: 4).fill(active ? Theme.secondary : Theme.gray))
            .overlay(RoundedRectangle(cornerRadius: 4).stroke(active ? Theme.secondary : Theme.border))
        }
    }

    private var winOverlay: some View {
        ZStack {
            Color.black.opacity(0.35).ignoresSafeArea()
            VStack(spacing: 14) {
                Text("🎉 أحسنت!").font(.title.bold())
                Text("أنهيت المستوى \(vm.level) (\(vm.difficulty.title)) بوقت \(formatTime(vm.seconds))")
                    .multilineTextAlignment(.center)
                    .foregroundColor(Theme.muted)
                Button("المستوى التالي") { vm.level += 1 }
                    .buttonStyle(ThemeButtonStyle(kind: .primary))
                Button("القائمة الرئيسية") { dismiss() }
                    .buttonStyle(ThemeButtonStyle())
            }
            .padding(20)
            .background(RoundedRectangle(cornerRadius: 8).fill(Theme.background))
            .overlay(RoundedRectangle(cornerRadius: 8).stroke(Theme.border))
            .shadow(color: .black.opacity(0.25), radius: 6, x: 3, y: 3)
            .padding(32)
        }
    }
}
