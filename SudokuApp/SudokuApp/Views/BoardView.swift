import SwiftUI

enum CellKind {
    case given, entered, solved
}

/// Draws a 9x9 grid. It is always laid out left-to-right so rows and columns match the data.
struct BoardView: View {
    let cells: [Int]
    let kinds: [CellKind]
    let selected: Int?
    let conflicts: Set<Int>
    let onTap: (Int) -> Void

    var body: some View {
        GeometryReader { geo in
            let side = min(geo.size.width, geo.size.height)
            let cell = side / 9
            ZStack(alignment: .topLeading) {
                ForEach(0..<81, id: \.self) { index in
                    cellView(index)
                        .frame(width: cell, height: cell)
                        .position(x: (CGFloat(index % 9) + 0.5) * cell,
                                  y: (CGFloat(index / 9) + 0.5) * cell)
                }
                gridLines(side: side)
            }
            .frame(width: side, height: side)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .aspectRatio(1, contentMode: .fit)
        .environment(\.layoutDirection, .leftToRight)
    }

    private func cellView(_ index: Int) -> some View {
        let digit = cells[index]
        return Button {
            onTap(index)
        } label: {
            ZStack {
                highlight(index)
                if digit != 0 {
                    Text("\(digit)")
                        .font(.system(size: 24, weight: kinds[index] == .given ? .bold : .regular))
                        .minimumScaleFactor(0.5)
                        .foregroundColor(textColor(index))
                }
            }
        }
        .buttonStyle(.plain)
        .accessibilityLabel(digit == 0 ? "خانة فارغة" : "الرقم \(digit)")
    }

    private func highlight(_ index: Int) -> some View {
        let color: Color
        if let selected = selected {
            if selected == index {
                color = Theme.secondary.opacity(0.35)
            } else if sharesUnit(selected, index) {
                color = Theme.surface
            } else if cells[selected] != 0 && cells[selected] == cells[index] {
                color = Theme.secondary.opacity(0.15)
            } else {
                color = .clear
            }
        } else {
            color = .clear
        }
        return Rectangle().fill(color)
    }

    private func textColor(_ index: Int) -> Color {
        if conflicts.contains(index) { return Theme.primary }
        switch kinds[index] {
        case .given: return Theme.text
        case .entered: return Theme.secondary
        case .solved: return Theme.secondary
        }
    }

    private func sharesUnit(_ a: Int, _ b: Int) -> Bool {
        a / 9 == b / 9 || a % 9 == b % 9 || (a / 27 == b / 27 && (a % 9) / 3 == (b % 9) / 3)
    }

    private func gridLines(side: CGFloat) -> some View {
        let cell = side / 9
        return Path { path in
            for i in 0...9 {
                let p = CGFloat(i) * cell
                path.move(to: CGPoint(x: p, y: 0))
                path.addLine(to: CGPoint(x: p, y: side))
                path.move(to: CGPoint(x: 0, y: p))
                path.addLine(to: CGPoint(x: side, y: p))
            }
        }
        .stroke(Theme.border, lineWidth: 1)
        .overlay(
            Path { path in
                for i in stride(from: 0, through: 9, by: 3) {
                    let p = CGFloat(i) * cell
                    path.move(to: CGPoint(x: p, y: 0))
                    path.addLine(to: CGPoint(x: p, y: side))
                    path.move(to: CGPoint(x: 0, y: p))
                    path.addLine(to: CGPoint(x: side, y: p))
                }
            }
            .stroke(Theme.text, lineWidth: 2)
        )
        .allowsHitTesting(false)
    }
}

/// Digits 1-9 plus an erase button.
struct NumberPad: View {
    let onDigit: (Int) -> Void
    let onErase: () -> Void

    var body: some View {
        VStack(spacing: 8) {
            HStack(spacing: 6) {
                ForEach(1...5, id: \.self) { digit in digitButton(digit) }
            }
            HStack(spacing: 6) {
                ForEach(6...9, id: \.self) { digit in digitButton(digit) }
                Button(action: onErase) {
                    Image(systemName: "delete.backward")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.themed())
                .accessibilityLabel("مسح")
            }
        }
        .environment(\.layoutDirection, .leftToRight)
    }

    private func digitButton(_ digit: Int) -> some View {
        Button("\(digit)") { onDigit(digit) }
            .buttonStyle(.themed())
            .frame(maxWidth: .infinity)
    }
}
