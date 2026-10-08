import SwiftUI

struct HomeView: View {
    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                Spacer()
                Text("سودوكو")
                    .font(.system(size: 44, weight: .regular))
                Text("العب مستويات لا تنتهي، أو أدخل لغزك ودَعني أحلّه")
                    .font(.body.italic())
                    .multilineTextAlignment(.center)
                    .foregroundColor(Theme.muted)
                    .padding(.horizontal)

                VStack(spacing: 12) {
                    Text("العب")
                        .font(.headline)
                        .foregroundColor(Theme.muted)
                    ForEach(Difficulty.allCases) { difficulty in
                        NavigationLink(value: difficulty) {
                            HStack {
                                Text(difficulty.title)
                                Spacer()
                                LevelBadge(level: LevelStore.currentLevel(for: difficulty))
                            }
                            .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.themed(.secondary))
                    }
                }
                .padding(.horizontal, 32)

                NavigationLink(value: "solver") {
                    Text("حلّ لغزك")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.themed(.primary))
                .padding(.horizontal, 32)

                Spacer()
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Theme.background.ignoresSafeArea())
            .navigationDestination(for: Difficulty.self) { difficulty in
                PlayView(difficulty: difficulty)
            }
            .navigationDestination(for: String.self) { _ in
                SolverView()
            }
        }
    }
}

/// Rounded "level number" pill, like the site's `.level_number`.
struct LevelBadge: View {
    let level: Int

    var body: some View {
        Text("المستوى \(level)")
            .font(.subheadline)
            .padding(.horizontal, 12)
            .padding(.vertical, 4)
            .background(Color.white.opacity(0.2))
            .clipShape(Capsule())
    }
}

/// Remembers the level the player has reached for each difficulty.
enum LevelStore {
    private static func key(_ difficulty: Difficulty) -> String { "level.\(difficulty.rawValue)" }

    static func currentLevel(for difficulty: Difficulty) -> Int {
        max(1, UserDefaults.standard.integer(forKey: key(difficulty)))
    }

    static func setCurrentLevel(_ level: Int, for difficulty: Difficulty) {
        UserDefaults.standard.set(level, forKey: key(difficulty))
    }
}
