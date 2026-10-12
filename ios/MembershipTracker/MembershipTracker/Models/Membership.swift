import Foundation
import SwiftData

/// 订阅周期
enum BillingCycle: String, Codable, CaseIterable, Identifiable {
    case monthly, quarterly, yearly
    var id: String { rawValue }

    var label: String {
        switch self {
        case .monthly:   return "按月"
        case .quarterly: return "按季"
        case .yearly:    return "按年"
        }
    }

    /// 折算成月份数，用于计算"平均每月成本"
    var months: Double {
        switch self {
        case .monthly:   return 1
        case .quarterly: return 3
        case .yearly:    return 12
        }
    }
}

/// 订阅状态
enum MembershipStatus: String, Codable {
    case active
    case cancelled

    var label: String {
        switch self {
        case .active:    return "生效中"
        case .cancelled: return "已取消"
        }
    }
}

/// 会员订阅（SwiftData 持久化模型）
@Model
final class Membership {
    @Attribute(.unique) var id: UUID
    var name: String
    /// 图标首字母 / 字符
    var abbr: String
    /// 品牌色，存十六进制字符串，如 "#00A4FF"
    var colorHex: String
    /// 分类
    var category: String
    /// 价格（元）
    var price: Double
    /// 周期
    var cycleRaw: String
    /// 下次扣费 / 到期日
    var nextDate: Date
    /// 支付方式
    var method: String
    /// 备注
    var note: String
    /// 状态
    var statusRaw: String
    var createdAt: Date

    init(
        id: UUID = UUID(),
        name: String,
        abbr: String,
        colorHex: String,
        category: String,
        price: Double,
        cycle: BillingCycle,
        nextDate: Date,
        method: String = "微信支付",
        note: String = "",
        status: MembershipStatus = .active
    ) {
        self.id = id
        self.name = name
        self.abbr = abbr
        self.colorHex = colorHex
        self.category = category
        self.price = price
        self.cycleRaw = cycle.rawValue
        self.nextDate = nextDate
        self.method = method
        self.note = note
        self.statusRaw = status.rawValue
        self.createdAt = Date()
    }

    // MARK: - 计算属性

    var cycle: BillingCycle {
        get { BillingCycle(rawValue: cycleRaw) ?? .monthly }
        set { cycleRaw = newValue.rawValue }
    }

    var status: MembershipStatus {
        get { MembershipStatus(rawValue: statusRaw) ?? .active }
        set { statusRaw = newValue.rawValue }
    }

    /// 折合每月成本
    var monthlyCost: Double {
        guard status == .active else { return 0 }
        return price / cycle.months
    }

    /// 距到期天数（自然日）
    var daysUntilDue: Int {
        let cal = Calendar.current
        let today = cal.startOfDay(for: Date())
        let due = cal.startOfDay(for: nextDate)
        return cal.dateComponents([.day], from: today, to: due).day ?? 0
    }

    /// 是否即将到期（默认 7 天内）
    var isDueSoon: Bool {
        let d = daysUntilDue
        return status == .active && d >= 0 && d <= 7
    }

    /// 到期文案
    var dueText: String {
        let d = daysUntilDue
        if status == .cancelled { return "已取消" }
        if d < 0 { return "已过期" }
        if d == 0 { return "今天到期" }
        if d <= 7 { return "\(d)天后 · \(Self.shortDate(nextDate))" }
        return "\(Self.shortDate(nextDate)) 到期"
    }

    static func shortDate(_ date: Date) -> String {
        let f = DateFormatter()
        f.locale = Locale(identifier: "zh_CN")
        f.dateFormat = "M月d日"
        return f.string(from: date)
    }
}
