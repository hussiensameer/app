import SwiftUI

/// شبكة سودوكو 9×9. تُستخدم في اللعبة وفي الحلّال.
struct BoardView: View {
    let values: [Int]
    let fixed: [Bool]
    let notes: [UInt16]
    let wrong: [Bool]
    let selected: Int?
    let onSelect: (Int) -> Void

    var body: some View {
        GeometryReader { geo in
            let size = min(geo.size.width, geo.size.height)
            let cell = size / 9
            ZStack(alignment: .topLeading) {
                ForEach(0..<81, id: \.self) { i in
                    cellView(i, cell)
                        .frame(width: cell, height: cell)
                        .position(x: (CGFloat(i % 9) + 0.5) * cell, y: (CGFloat(i / 9) + 0.5) * cell)
                        .contentShape(Rectangle())
                        .onTapGesture { onSelect(i) }
                }
                Canvas { ctx, sz in
                    for k in 0...9 {
                        let p = CGFloat(k) * sz.width / 9
                        var v = Path()
                        v.move(to: CGPoint(x: p, y: 0))
                        v.addLine(to: CGPoint(x: p, y: sz.height))
                        var h = Path()
                        h.move(to: CGPoint(x: 0, y: p))
                        h.addLine(to: CGPoint(x: sz.width, y: p))
                        let thick = k % 3 == 0
                        let color = thick ? Theme.gridLine : Theme.border
                        let w: CGFloat = thick ? 2 : 0.7
                        ctx.stroke(v, with: .color(color), lineWidth: w)
                        ctx.stroke(h, with: .color(color), lineWidth: w)
                    }
                }
                .allowsHitTesting(false)
            }
            .frame(width: size, height: size)
            .background(Theme.background)
        }
        .aspectRatio(1, contentMode: .fit)
        .environment(\.layoutDirection, .leftToRight)
    }

    private func background(_ i: Int) -> Color {
        guard let s = selected else { return .clear }
        if i == s { return Theme.softBlue }
        if values[s] != 0 && values[i] == values[s] { return Theme.softBlue.opacity(0.7) }
        if isPeer(i, s) { return Theme.peer }
        return .clear
    }

    @ViewBuilder
    private func cellView(_ i: Int, _ cell: CGFloat) -> some View {
        ZStack {
            Rectangle().fill(wrong[i] ? Theme.softRed : background(i))
            if values[i] != 0 {
                Text(String(values[i]))
                    .font(.system(size: cell * 0.58, weight: fixed[i] ? .bold : .regular, design: .rounded))
                    .foregroundColor(fixed[i] ? .black : (wrong[i] ? Theme.primary : Theme.secondary))
            } else if notes[i] != 0 {
                VStack(spacing: 0) {
                    ForEach(0..<3, id: \.self) { r in
                        HStack(spacing: 0) {
                            ForEach(0..<3, id: \.self) { c in
                                let d = r * 3 + c + 1
                                Text(notes[i] & (UInt16(1) << UInt16(d)) != 0 ? String(d) : " ")
                                    .font(.system(size: cell * 0.22))
                                    .foregroundColor(Theme.muted)
                                    .frame(width: cell / 3.4, height: cell / 3.4)
                            }
                        }
                    }
                }
            }
        }
    }
}

struct NumberPad: View {
    var remaining: ((Int) -> Int)? = nil
    let onTap: (Int) -> Void

    var body: some View {
        HStack(spacing: 6) {
            ForEach(1...9, id: \.self) { d in
                let left = remaining?(d) ?? 1
                Button { onTap(d) } label: {
                    Text(String(d))
                        .font(.system(size: 26, weight: .semibold, design: .rounded))
                        .frame(maxWidth: .infinity, minHeight: 52)
                        .foregroundColor(left <= 0 ? Theme.muted.opacity(0.4) : Theme.secondary)
                        .background(RoundedRectangle(cornerRadius: 4).fill(Theme.gray))
                        .overlay(RoundedRectangle(cornerRadius: 4).stroke(Theme.border))
                }
                .disabled(left <= 0)
            }
        }
        .environment(\.layoutDirection, .leftToRight)
    }
}
