import Foundation

/// يحفظ تقدم اللاعب (المستوى الحالي وأفضل وقت لكل صعوبة).
final class GameProgress: ObservableObject {
    @Published private(set) var levels: [String: Int]
    @Published private(set) var completed: [String: Int]
    @Published private(set) var best: [String: Int]

    private let defaults = UserDefaults.standard

    init() {
        levels = defaults.dictionary(forKey: "levels") as? [String: Int] ?? [:]
        completed = defaults.dictionary(forKey: "completed") as? [String: Int] ?? [:]
        best = defaults.dictionary(forKey: "best") as? [String: Int] ?? [:]
    }

    func level(_ d: Difficulty) -> Int { levels[d.rawValue] ?? 1 }
    func completedCount(_ d: Difficulty) -> Int { completed[d.rawValue] ?? 0 }
    func bestTime(_ d: Difficulty) -> Int? { best[d.rawValue] }

    func finish(_ d: Difficulty, level: Int, seconds: Int) {
        if level >= self.level(d) { levels[d.rawValue] = level + 1 }
        completed[d.rawValue, default: 0] += 1
        if seconds < (best[d.rawValue] ?? Int.max) { best[d.rawValue] = seconds }
        defaults.set(levels, forKey: "levels")
        defaults.set(completed, forKey: "completed")
        defaults.set(best, forKey: "best")
    }
}

func formatTime(_ s: Int) -> String {
    String(format: "%02d:%02d", s / 60, s % 60)
}
