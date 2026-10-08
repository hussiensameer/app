import SwiftUI

@main
struct SudokuApp: App {
    var body: some Scene {
        WindowGroup {
            HomeView()
                .environment(\.layoutDirection, .rightToLeft)
                .environment(\.locale, Locale(identifier: "ar"))
        }
    }
}
