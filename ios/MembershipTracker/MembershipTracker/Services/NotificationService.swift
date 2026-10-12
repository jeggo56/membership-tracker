import Foundation
import UserNotifications

/// 本地通知 / 到期提醒服务
@MainActor
final class NotificationService: ObservableObject {
    static let shared = NotificationService()

    @Published var isAuthorized = false

    private let center = UNUserNotificationCenter.current()

    // 设置项 key
    private let kEnabled   = "notify_enabled"
    private let kDaysAhead = "notify_days_ahead"
    private let kHour      = "notify_hour"
    private let kMinute    = "notify_minute"

    private init() {}

    // MARK: - 配置读写

    var isEnabled: Bool {
        get { UserDefaults.standard.object(forKey: kEnabled) as? Bool ?? true }
        set { UserDefaults.standard.set(newValue, forKey: kEnabled) }
    }

    /// 提前几天提醒（默认 1 天）
    var daysAhead: Int {
        get { UserDefaults.standard.object(forKey: kDaysAhead) as? Int ?? 1 }
        set { UserDefaults.standard.set(newValue, forKey: kDaysAhead) }
    }

    /// 提醒时间（默认 09:00）
    var notifyHour: Int {
        get { UserDefaults.standard.object(forKey: kHour) as? Int ?? 9 }
        set { UserDefaults.standard.set(newValue, forKey: kHour) }
    }
    var notifyMinute: Int {
        get { UserDefaults.standard.object(forKey: kMinute) as? Int ?? 0 }
        set { UserDefaults.standard.set(newValue, forKey: kMinute) }
    }

    var notifyTimeText: String {
        String(format: "%02d:%02d", notifyHour, notifyMinute)
    }

    // MARK: - 权限

    func requestAuthorization() async {
        do {
            let granted = try await center.requestAuthorization(options: [.alert, .sound, .badge])
            isAuthorized = granted
            isEnabled = granted
        } catch {
            isAuthorized = false
        }
    }

    func refreshAuthorizationStatus() async {
        let settings = await center.notificationSettings()
        isAuthorized = (settings.authorizationStatus == .authorized)
    }

    // MARK: - 重新调度所有提醒（核心）

    /// 根据当前订阅数据，重建全部待发送的提醒
    func rescheduleAll(memberships: [Membership]) {
        center.removeAllPendingNotificationRequests()

        guard isEnabled, isAuthorized else { return }

        let cal = Calendar.current

        for m in memberships where m.status == .active {
            // 到期日必须是今天或未来
            guard cal.startOfDay(for: m.nextDate) >= cal.startOfDay(for: Date()) else { continue }

            // 计算"提前 N 天"对应的提醒日期
            guard let remindDate = cal.date(byAdding: .day, value: -daysAhead,
                                            to: cal.startOfDay(for: m.nextDate)) else { continue }

            // 提醒触发时刻 = 提醒日当天的 notifyHour:notifyMinute
            var comps = cal.dateComponents([.year, .month, .day], from: remindDate)
            comps.hour = notifyHour
            comps.minute = notifyMinute

            guard let triggerDate = cal.date(from: comps) else { continue }
            // 触发时间已过的不再调度
            guard triggerDate > Date() else { continue }

            let content = UNMutableNotificationContent()
            content.title = "⏰ \(m.name) 即将到期"
            content.body = dueBody(for: m)
            content.sound = .default
            content.userInfo = ["membershipId": m.id.uuidString]

            let dateComps = cal.dateComponents([.year, .month, .day, .hour, .minute], from: triggerDate)
            let trigger = UNCalendarNotificationTrigger(dateMatching: dateComps, repeats: false)

            let request = UNNotificationRequest(
                identifier: "due-\(m.id.uuidString)",
                content: content,
                trigger: trigger
            )
            center.add(request)
        }
    }

    /// 当天到期汇总提醒（可选：每天早上汇总）
    func scheduleDailySummary(memberships: [Membership]) {
        guard isEnabled, isAuthorized else { return }

        let dueToday = memberships.filter { $0.status == .active && $0.daysUntilDue == 0 }
        guard !dueToday.isEmpty else { return }

        let content = UNMutableNotificationContent()
        content.title = "💳 今天要扣费了"
        let total = dueToday.reduce(0) { $0 + $1.price }
        content.body = dueToday.map { "\($0.name) ¥\(Self.money($0.price))" }.joined(separator: "、")
            + "，合计 ¥\(Self.money(total))"
        content.sound = .default

        let comps = DateComponents(hour: notifyHour, minute: notifyMinute)
        let trigger = UNCalendarNotificationTrigger(dateMatching: comps, repeats: true)
        center.add(UNNotificationRequest(identifier: "daily-summary", content: content, trigger: trigger))
    }

    // MARK: - 测试通知

    func sendTestNotification() async {
        let content = UNMutableNotificationContent()
        content.title = "会员管家 · 测试提醒"
        content.body = "这是一条测试通知。到期前 \(daysAhead) 天的 \(notifyTimeText) 会自动提醒你 ✅"
        content.sound = .default

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 2, repeats: false)
        try? await center.add(UNNotificationRequest(identifier: "test-\(UUID().uuidString)", content: content, trigger: trigger))
    }

    /// 立刻给某个会员发一条测试到期通知
    func sendDueTest(for m: Membership) async {
        let content = UNMutableNotificationContent()
        content.title = "⏰ \(m.name) 即将到期"
        content.body = dueBody(for: m)
        content.sound = .default
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 2, repeats: false)
        try? await center.add(UNNotificationRequest(identifier: "duetest-\(UUID().uuidString)", content: content, trigger: trigger))
    }

    // MARK: - 辅助

    private func dueBody(for m: Membership) -> String {
        let d = m.daysUntilDue
        let when = d == 0 ? "今天" : (d == 1 ? "明天" : "\(d) 天后")
        return "\(when)将扣费 ¥\(Self.money(m.price))（\(m.cycle.label)），请留意账户余额"
    }

    static func money(_ v: Double) -> String {
        v == v.rounded() ? String(format: "%.0f", v) : String(format: "%.2f", v)
    }
}
