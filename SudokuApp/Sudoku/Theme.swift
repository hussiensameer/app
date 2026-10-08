import SwiftUI

extension Color {
    init(hex: UInt32) {
        self.init(.sRGB,
                  red: Double((hex >> 16) & 0xff) / 255,
                  green: Double((hex >> 8) & 0xff) / 255,
                  blue: Double(hex & 0xff) / 255,
                  opacity: 1)
    }
}

/// ألوان مأخوذة من موقع cthiq.com (أبيض + أحمر #dd4b39 + أزرق #4d90fe + رمادي فاتح).
enum Theme {
    static let primary = Color(hex: 0xdd4b39)
    static let secondary = Color(hex: 0x4d90fe)
    static let background = Color.white
    static let gray = Color(hex: 0xeeeeee)
    static let border = Color(hex: 0xdddddd)
    static let muted = Color(hex: 0x888888)
    static let gridLine = Color(hex: 0x333333)
    static let softBlue = Color(hex: 0xdbe8ff)
    static let softRed = Color(hex: 0xfbe0dc)
    static let peer = Color(hex: 0xf3f3f3)
}

struct ThemeButtonStyle: ButtonStyle {
    enum Kind { case plain, primary, secondary }
    var kind: Kind = .plain

    private var fill: Color {
        switch kind {
        case .plain: return Theme.gray
        case .primary: return Theme.primary
        case .secondary: return Theme.secondary
        }
    }

    private var stroke: Color { kind == .plain ? Theme.border : fill }

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline)
            .padding(.vertical, 12)
            .padding(.horizontal, 16)
            .frame(maxWidth: .infinity)
            .foregroundColor(kind == .plain ? .black : .white)
            .background(RoundedRectangle(cornerRadius: 4).fill(fill))
            .overlay(RoundedRectangle(cornerRadius: 4).stroke(stroke, lineWidth: 1))
            .opacity(configuration.isPressed ? 0.75 : 1)
    }
}
