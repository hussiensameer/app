# تطبيق سودوكو (SudokuApp)

تطبيق iOS وmacOS بـ SwiftUI: يحلّ ألغاز سودوكو التي يدخلها المستخدم، ويولّد مستويات لا تنتهي بأربع درجات صعوبة (سهل، متوسط، صعب، خبير)، ولكل لغز حلّ وحيد.

- افتح `SudokuApp.xcodeproj` في Xcode 16 أو أحدث (iOS 16+ و macOS 13+).
- الحلّال: `SudokuApp/Core/SudokuSolver.swift` (backtracking مع bitmasks).
- المولّد: `SudokuApp/Core/SudokuGenerator.swift`؛ نفس رقم المستوى والصعوبة يعطيان دائماً نفس اللغز.
- الاختبارات: `SudokuAppTests` (⌘U).
- الألوان والأزرار مأخوذة من ملفات الموقع (`ar/common/common.css`): خلفية بيضاء، أزرار رمادية فاتحة، أحمر `#dd4b39` وأزرق `#4d90fe`.
