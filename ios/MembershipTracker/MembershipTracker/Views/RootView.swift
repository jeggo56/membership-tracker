import SwiftUI
import SwiftData

struct RootView: View {
    @Environment(\.modelContext) private var context
    @Query private var memberships: [Membership]

    @StateObject private var notifications = NotificationService.shared
    @State private var selectedTab: Tab = .home
    @State private var showAddSheet = false
    @State private var didBootstrap = false

    enum Tab { case home, list, stats, settings }

    var body: some View {
        ZStack(alignment: .bottom) {
            Theme.bg.ignoresSafeArea()

            // 内容
            Group {
                switch selectedTab {
                case .home:     HomeView(showAddSheet: $showAddSheet)
                case .list:     ListView(showAddSheet: $showAddSheet)
                case .stats:    StatsView()
                case .settings: SettingsView()
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)

            // 自定义 Tab Bar
            TabBar(selected: $selectedTab, onAdd: { showAddSheet = true })
        }
        .task {
            // 首次启动：请求权限 + 播种示例数据 + 调度提醒
            guard !didBootstrap else { return }
            didBootstrap = true

            await notifications.refreshAuthorizationStatus()
            if notifications.isAuthorized {
                notifications.rescheduleAll(memberships: memberships)
            }
            seedIfEmpty()
        }
        .sheet(isPresented: $showAddSheet) {
            MembershipFormView(membership: nil)
                .presentationBackground(Theme.bgSoft)
        }
    }

    /// 首次运行填充演示数据
    private func seedIfEmpty() {
        guard memberships.isEmpty else { return }
        let cal = Calendar.current
        func d(_ days: Int) -> Date { cal.date(byAdding: .day, value: days, to: Date()) ?? Date() }

        let seeds: [Membership] = [
            Membership(name: "腾讯视频", abbr: "腾", colorHex: "#00A4FF", category: "视频", price: 25,  cycle: .monthly, nextDate: d(3),   method: "微信支付", note: "连续包月，自动续费"),
            Membership(name: "爱奇艺",   abbr: "爱", colorHex: "#00CC36", category: "视频", price: 238, cycle: .yearly,  nextDate: d(46),  method: "支付宝",   note: "年卡会员"),
            Membership(name: "美团",     abbr: "美", colorHex: "#FFD100", category: "生活", price: 15,  cycle: .monthly, nextDate: d(1),   method: "微信支付", note: "外卖红包卡"),
            Membership(name: "京东PLUS", abbr: "京", colorHex: "#E1251B", category: "电商", price: 149, cycle: .yearly,  nextDate: d(120), method: "京东支付", note: "含运费券+会员价"),
            Membership(name: "网易云音乐", abbr: "网", colorHex: "#C20C0C", category: "音乐", price: 88, cycle: .yearly,  nextDate: d(9),   method: "支付宝",   note: "黑胶VIP年卡"),
            Membership(name: "ChatGPT",  abbr: "AI", colorHex: "#10A37F", category: "工具", price: 140, cycle: .monthly, nextDate: d(21),  method: "信用卡",   note: "Plus 订阅"),
        ]
        seeds.forEach { context.insert($0) }
        try? context.save()
        notifications.rescheduleAll(memberships: seeds)
    }
}

// MARK: - 自定义 Tab Bar

struct TabBar: View {
    @Binding var selected: RootView.Tab
    var onAdd: () -> Void

    var body: some View {
        HStack(spacing: 0) {
            tabButton(.home, "概览", "house.fill")
            tabButton(.list, "会员", "list.bullet")
            addButton
            tabButton(.stats, "统计", "chart.bar.fill")
            tabButton(.settings, "我的", "gearshape")
        }
        .padding(.horizontal, 8)
        .padding(.top, 9)
        .padding(.bottom, 4)
        .background(.ultraThinMaterial)
        .background(Theme.bgSoft.opacity(0.6))
        .overlay(alignment: .top) {
            Rectangle().fill(Color.white.opacity(0.07)).frame(height: 1)
        }
    }

    private func tabButton(_ t: RootView.Tab, _ title: String, _ icon: String) -> some View {
        Button {
            withAnimation(.easeInOut(duration: 0.15)) { selected = t }
        } label: {
            VStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 21, weight: .medium))
                Text(title).font(.system(size: 10.5, weight: .semibold))
            }
            .foregroundStyle(selected == t ? Theme.accent : Theme.txt3)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 5)
        }
        .buttonStyle(.plain)
    }

    private var addButton: some View {
        Button(action: onAdd) {
            Text("＋")
                .font(.system(size: 27, weight: .regular))
                .foregroundStyle(.white)
                .frame(width: 50, height: 50)
                .background(Theme.accentGradient,
                            in: RoundedRectangle(cornerRadius: 17, style: .continuous))
                .shadow(color: Theme.accent.opacity(0.75), radius: 12, y: 8)
        }
        .buttonStyle(.plain)
        .frame(maxWidth: .infinity)
        .offset(y: -11)
    }
}
