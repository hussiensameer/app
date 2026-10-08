import SwiftUI

@main
struct SudokuApp: App {
    @StateObject private var progress = GameProgress()

    var body: some Scene {
        WindowGroup {
            HomeView()
                .environmentObject(progress)
                .environment(\.layoutDirection, .rightToLeft)
                .preferredColorScheme(.light)
                .tint(Theme.secondary)
        }
    }
}
