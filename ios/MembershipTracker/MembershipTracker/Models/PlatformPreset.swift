import SwiftUI

/// 平台预设库（品牌色 + 首字母 + 默认分类）
struct PlatformPreset: Identifiable, Hashable {
    let id: String
    let name: String
    let abbr: String
    let colorHex: String
    let category: String

    static let all: [PlatformPreset] = [
        .init(id: "tencent", name: "腾讯视频",  abbr: "腾", colorHex: "#00A4FF", category: "视频"),
        .init(id: "iqiyi",   name: "爱奇艺",    abbr: "爱", colorHex: "#00CC36", category: "视频"),
        .init(id: "youku",   name: "优酷",      abbr: "优", colorHex: "#1F7BF9", category: "视频"),
        .init(id: "mango",   name: "芒果TV",    abbr: "芒", colorHex: "#FF6A00", category: "视频"),
        .init(id: "bili",    name: "哔哩哔哩",  abbr: "B",  colorHex: "#FB7299", category: "视频"),
        .init(id: "meituan", name: "美团",      abbr: "美", colorHex: "#FFD100", category: "生活"),
        .init(id: "eleme",   name: "饿了么",    abbr: "饿", colorHex: "#0F9BFF", category: "生活"),
        .init(id: "jd",      name: "京东PLUS",  abbr: "京", colorHex: "#E1251B", category: "电商"),
        .init(id: "taobao",  name: "淘宝88VIP", abbr: "淘", colorHex: "#FF5000", category: "电商"),
        .init(id: "pdd",     name: "拼多多",    abbr: "拼", colorHex: "#E02E24", category: "电商"),
        .init(id: "netease", name: "网易云音乐", abbr: "网", colorHex: "#C20C0C", category: "音乐"),
        .init(id: "qqmusic", name: "QQ音乐",    abbr: "Q",  colorHex: "#31C27C", category: "音乐"),
        .init(id: "spotify", name: "Spotify",   abbr: "S",  colorHex: "#1DB954", category: "音乐"),
        .init(id: "wps",     name: "WPS会员",   abbr: "WP", colorHex: "#E64A19", category: "工具"),
        .init(id: "ximalaya",name: "喜马拉雅",  abbr: "喜", colorHex: "#F86442", category: "音频"),
        .init(id: "baidu",   name: "百度网盘",  abbr: "度", colorHex: "#2A6AF0", category: "工具"),
        .init(id: "icloud",  name: "iCloud+",   abbr: "☁",  colorHex: "#4A90E2", category: "工具"),
        .init(id: "openai",  name: "ChatGPT",   abbr: "AI", colorHex: "#10A37F", category: "工具"),
        .init(id: "claude",  name: "Claude",    abbr: "C",  colorHex: "#D97757", category: "工具"),
    ]
}

/// 分类定义
struct CategoryInfo {
    let name: String
    let icon: String
    let colorHex: String

    static let all: [CategoryInfo] = [
        .init(name: "视频", icon: "🎬", colorHex: "#6c8cff"),
        .init(name: "生活", icon: "🍜", colorHex: "#fb923c"),
        .init(name: "电商", icon: "🛍️", colorHex: "#f87171"),
        .init(name: "音乐", icon: "🎵", colorHex: "#34d399"),
        .init(name: "音频", icon: "🎧", colorHex: "#22d3ee"),
        .init(name: "工具", icon: "🧰", colorHex: "#a855f7"),
        .init(name: "其它", icon: "📦", colorHex: "#9aa3b2"),
    ]

    static let names: [String] = all.map(\.name)

    static func info(for name: String) -> CategoryInfo {
        all.first { $0.name == name } ?? all.last!
    }
}

// MARK: - Color 扩展：支持十六进制

extension Color {
    init(hex: String) {
        let s = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: s).scanHexInt64(&int)
        let r, g, b: UInt64
        switch s.count {
        case 3: // RGB (12-bit)
            (r, g, b) = ((int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (r, g, b) = (int >> 16, int >> 8 & 0xFF, int & 0xFF)
        default:
            (r, g, b) = (0.42, 0.55, 1.0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: 1
        )
    }

    /// 取同色系更深的颜色（用于渐变）
    var darker: Color {
        // 简单近似：混合黑色
        return self.opacity(0.62)
    }
}
