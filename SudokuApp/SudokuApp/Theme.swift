import SwiftUI

/// Colors and metrics taken from the cthiq.com site files (ar/common/common.css):
/// white page, light-grey #ddd borders and #eee buttons, red #dd4b39 primary, blue #4d90fe secondary.
enum Theme {
    static let background = Color.white
    static let border = Color(hex: 0xDDDDDD)
    static let surface = Color(hex: 0xEEEEEE)
    static let muted = Color(hex: 0x888888)
    static let primary = Color(hex: 0xDD4B39)
    static let secondary = Color(hex: 0x4D90FE)
    static let text = Color.black
    static let cornerRadius: CGFloat = 4
}

extension Color {
    init(hex: UInt32) {
        self.init(
            red: Double((hex >> 16) & 0xFF) / 255,
            green: Double((hex >> 8) & 0xFF) / 255,
            blue: Double(hex & 0xFF) / 255
        )
    }
}

enum ButtonKind {
    case normal, primary, secondary
}

/// Mirrors the site's `button`, `button.primary` and `button.secondary` rules.
struct ThemedButtonStyle: ButtonStyle {
    var kind: ButtonKind = .normal

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.title3)
            .padding(10)
            .frame(minWidth: 64)
            .foregroundColor(kind == .normal ? Theme.text : .white)
            .background(background)
            .overlay(
                RoundedRectangle(cornerRadius: Theme.cornerRadius)
                    .stroke(configuration.isPressed ? Theme.muted : borderColor, lineWidth: 1)
            )
            .cornerRadius(Theme.cornerRadius)
            .opacity(configuration.isPressed ? 0.85 : 1)
    }

    private var background: Color {
        switch kind {
        case .normal: return Theme.surface
        case .primary: return Theme.primary
        case .secondary: return Theme.secondary
        }
    }

    private var borderColor: Color {
        kind == .normal ? Theme.border : background
    }
}

extension ButtonStyle where Self == ThemedButtonStyle {
    static func themed(_ kind: ButtonKind = .normal) -> ThemedButtonStyle {
        ThemedButtonStyle(kind: kind)
    }
}
