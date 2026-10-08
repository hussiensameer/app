import SwiftUI

enum Route: Hashable {
    case game(Difficulty)
    case solver
}

struct HomeView: View {
    @EnvironmentObject private var progress: GameProgress

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 14) {
                    VStack(spacing: 6) {
                        Text("سودوكو")
                            .font(.system(size: 40, weight: .bold))
                            .foregroundColor(Theme.primary)
                        Text("مستويات لا نهائية بصعوبات مختلفة")
                            .italic()
                            .foregroundColor(Theme.muted)
                    }
                    .padding(.vertical, 18)

                    ForEach(Difficulty.allCases) { d in
                        NavigationLink(value: Route.game(d)) { card(d) }
                            .buttonStyle(.plain)
                    }

                    NavigationLink(value: Route.solver) {
                        Label("حلّال سودوكو: أدخل لغزاً واحلّه", systemImage: "wand.and.stars")
                    }
                    .buttonStyle(ThemeButtonStyle(kind: .secondary))
                    .padding(.top, 8)
                }
                .padding(16)
            }
            .background(Theme.background.ignoresSafeArea())
            .navigationDestination(for: Route.self) { route in
                switch route {
                case .game(let d): GameView(difficulty: d, level: progress.level(d))
                case .solver: SolverView()
                }
            }
        }
    }

    private func card(_ d: Difficulty) -> some View {
        HStack(spacing: 14) {
            Circle().fill(d.color).frame(width: 18, height: 18)
            VStack(alignment: .leading, spacing: 4) {
                Text(d.title).font(.title3.weight(.semibold)).foregroundColor(.black)
                Text("أنجزت \(progress.completedCount(d)) · أفضل وقت: \(progress.bestTime(d).map(formatTime) ?? "—")")
                    .font(.caption).foregroundColor(Theme.muted)
            }
            Spacer()
            Text("مستوى \(progress.level(d))")
                .font(.subheadline)
                .padding(.vertical, 6).padding(.horizontal, 12)
                .foregroundColor(d.color)
                .overlay(RoundedRectangle(cornerRadius: 20).stroke(d.color))
        }
        .padding(14)
        .background(RoundedRectangle(cornerRadius: 8).fill(Theme.background))
        .overlay(RoundedRectangle(cornerRadius: 8).stroke(Theme.border))
    }
}
