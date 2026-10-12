import SwiftUI

/// 全局设计系统
enum Theme {
    // 背景
    static let bg      = Color(hex: "#0b0d14")
    static let bgSoft  = Color(hex: "#12151f")
    static let card    = Color.white.opacity(0.055)
    static let cardBrd = Color.white.opacity(0.09)

    // 文字
    static let txt    = Color(hex: "#f2f4f8")
    static let txt2   = Color(hex: "#9aa3b2")
    static let txt3   = Color(hex: "#5f6879")

    // 强调色
    static let accent  = Color(hex: "#6c8cff")
    static let accent2 = Color(hex: "#8b5cf6")
    static let green   = Color(hex: "#34d399")
    static let orange  = Color(hex: "#fb923c")
    static let red     = Color(hex: "#f87171")
    static let yellow  = Color(hex: "#fbbf24")

    static let heroGradient = LinearGradient(
        colors: [Color(hex: "#6c8cff"), Color(hex: "#8b5cf6"), Color(hex: "#a855f7")],
        startPoint: .topLeading, endPoint: .bottomTrailing
    )

    static let accentGradient = LinearGradient(
        colors: [Color(hex: "#6c8cff"), Color(hex: "#8b5cf6")],
        startPoint: .topLeading, endPoint: .bottomTrailing
    )
}

/// 玻璃拟态卡片背景
struct GlassCard: ViewModifier {
    var radius: CGFloat = 22
    func body(content: Content) -> some View {
        content
            .background(Theme.card, in: RoundedRectangle(cornerRadius: radius, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: radius, style: .continuous)
                    .strokeBorder(Theme.cardBrd, lineWidth: 1)
            )
    }
}

extension View {
    func glassCard(radius: CGFloat = 22) -> some View {
        modifier(GlassCard(radius: radius))
    }
}

/// 平台 logo 方块
struct LogoBadge: View {
    let abbr: String
    let colorHex: String
    var size: CGFloat = 48

    var body: some View {
        let color = Color(hex: colorHex)
        Text(abbr)
            .font(.system(size: size * 0.4, weight: .heavy))
            .foregroundStyle(.white)
            .frame(width: size, height: size)
            .background(
                LinearGradient(colors: [color, color.opacity(0.62)],
                               startPoint: .topLeading, endPoint: .bottomTrailing),
                in: RoundedRectangle(cornerRadius: size * 0.29, style: .continuous)
            )
            .shadow(color: .black.opacity(0.4), radius: 6, y: 4)
    }
}

/// 金额格式化
func money(_ v: Double) -> String {
    v == v.rounded() ? String(format: "%.0f", v) : String(format: "%.2f", v)
}
