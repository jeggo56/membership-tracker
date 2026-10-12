import SwiftUI
import SwiftData

struct SettingsView: View {
    @Environment(\.modelContext) private var context
    @StateObject private var notifications = NotificationService.shared
    @Query private var memberships: [Membership]

    @State private var showDayPicker = false
    @State private var showTimePicker = false
    @State private var showClearConfirm = false
    @State private var showExport = false
    @State private var exportText = ""

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                Text("我的")
                    .font(.system(size: 31, weight: .heavy)).foregroundStyle(Theme.txt)
                    .padding(.horizontal, 22).padding(.top, 8)

                // 头像卡
                HStack(spacing: 15) {
                    Text("会").font(.system(size: 24, weight: .heavy)).foregroundStyle(.white)
                        .frame(width: 58, height: 58)
                        .background(Theme.accentGradient, in: Circle())
                    VStack(alignment: .leading, spacing: 3) {
                        Text("我的会员账户").font(.system(size: 19, weight: .heavy)).foregroundStyle(Theme.txt)
                        Text("\(activeCount) 个在订阅 · 数据存于本机")
                            .font(.system(size: 13, weight: .medium)).foregroundStyle(Theme.txt2)
                    }
                    Spacer()
                }
                .padding(20)
                .background(
                    LinearGradient(colors: [Theme.accent.opacity(0.16), Theme.accent2.opacity(0.10)],
                                   startPoint: .topLeading, endPoint: .bottomTrailing),
                    in: RoundedRectangle(cornerRadius: 24)
                )
                .overlay(RoundedRectangle(cornerRadius: 24).strokeBorder(Theme.cardBrd, lineWidth: 1))
                .padding(.horizontal, 18).padding(.top, 10)

                // 提醒组
                VStack(spacing: 0) {
                    row(icon: "🔔", color: Theme.orange, label: "到期提醒",
                        value: notifications.isAuthorized && notifications.isEnabled ? "已开启" : "未开启") {
                        Task {
                            if notifications.isAuthorized && notifications.isEnabled {
                                notifications.isEnabled = false
                            } else {
                                await notifications.requestAuthorization()
                                if notifications.isAuthorized {
                                    notifications.rescheduleAll(memberships: memberships)
                                }
                            }
                        }
                    }
                    divider
                    row(icon: "⏱️", color: Theme.yellow, label: "提前提醒天数",
                        value: "\(notifications.daysAhead) 天前") { showDayPicker = true }
                    divider
                    row(icon: "🕘", color: Theme.accent2, label: "提醒时间",
                        value: notifications.notifyTimeText) { showTimePicker = true }
                    divider
                    row(icon: "🧪", color: Theme.green, label: "发送测试提醒", value: "") {
                        Task {
                            if !notifications.isAuthorized { await notifications.requestAuthorization() }
                            await notifications.sendTestNotification()
                        }
                    }
                }
                .glassCard(radius: 22)
                .padding(.horizontal, 18).padding(.top, 16)

                // 通用组
                VStack(spacing: 0) {
                    row(icon: "💱", color: Theme.green, label: "货币单位", value: "¥ 人民币") {}
                    divider
                    row(icon: "🌙", color: Theme.accent2, label: "外观", value: "深色") {}
                }
                .glassCard(radius: 22)
                .padding(.horizontal, 18).padding(.top, 16)

                // 数据组
                VStack(spacing: 0) {
                    row(icon: "⬆️", color: Theme.accent, label: "导出数据", value: "") { exportData() }
                    divider
                    row(icon: "🗑️", color: Theme.red, label: "清空数据", value: "", danger: true) { showClearConfirm = true }
                }
                .glassCard(radius: 22)
                .padding(.horizontal, 18).padding(.top, 16)

                Text("会员管家 v1.0 · SwiftUI 原生版")
                    .font(.system(size: 12, weight: .semibold)).foregroundStyle(Theme.txt3)
                    .frame(maxWidth: .infinity).padding(.top, 26)

                Spacer(minLength: 100)
            }
        }
        .background(Theme.bg)
        .sheet(isPresented: $showDayPicker) { dayPicker }
        .sheet(isPresented: $showTimePicker) { timePicker }
        .alert("确定清空所有数据？", isPresented: $showClearConfirm) {
            Button("取消", role: .cancel) {}
            Button("清空", role: .destructive) {
                memberships.forEach { context.delete($0) }
                try? context.save()
                NotificationService.shared.rescheduleAll(memberships: [])
            }
        } message: { Text("此操作不可恢复") }
        .sheet(isPresented: $showExport) {
            NavigationStack {
                ScrollView {
                    Text(exportText)
                        .font(.system(size: 12, design: .monospaced))
                        .foregroundStyle(Theme.txt2)
                        .textSelection(.enabled)
                        .padding()
                }
                .background(Theme.bgSoft)
                .navigationTitle("导出数据")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .topBarTrailing) {
                        ShareLink(item: exportText) { Image(systemName: "square.and.arrow.up") }
                    }
                }
            }
            .presentationBackground(Theme.bgSoft)
        }
    }

    private var activeCount: Int { memberships.filter { $0.status == .active }.count }

    // MARK: - 行

    private var divider: some View {
        Rectangle().fill(Color.white.opacity(0.055)).frame(height: 1).padding(.leading, 62)
    }

    private func row(icon: String, color: Color, label: String, value: String,
                     danger: Bool = false, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 13) {
                Text(icon).font(.system(size: 16))
                    .frame(width: 32, height: 32)
                    .background(color.opacity(0.18), in: RoundedRectangle(cornerRadius: 10))
                Text(label)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(danger ? Theme.red : Theme.txt)
                Spacer()
                if !value.isEmpty {
                    Text(value).font(.system(size: 13.5, weight: .semibold)).foregroundStyle(Theme.txt2)
                }
                Image(systemName: "chevron.right")
                    .font(.system(size: 13, weight: .semibold)).foregroundStyle(Theme.txt3)
            }
            .padding(.horizontal, 17).padding(.vertical, 15)
        }
        .buttonStyle(.plain)
    }

    // MARK: - 选择器

    private var dayPicker: some View {
        NavigationStack {
            VStack(spacing: 12) {
                ForEach([1, 2, 3, 5, 7], id: \.self) { d in
                    Button {
                        notifications.daysAhead = d
                        notifications.rescheduleAll(memberships: memberships)
                        showDayPicker = false
                    } label: {
                        HStack {
                            Text("提前 \(d) 天" + (d == 1 ? "（推荐）" : ""))
                                .font(.system(size: 16, weight: .bold))
                                .foregroundStyle(notifications.daysAhead == d ? .white : Theme.txt)
                            Spacer()
                            if notifications.daysAhead == d {
                                Image(systemName: "checkmark").foregroundStyle(.white)
                            }
                        }
                        .padding(.vertical, 16).padding(.horizontal, 18)
                        .background(notifications.daysAhead == d ? Theme.accent : Color.white.opacity(0.06),
                                    in: RoundedRectangle(cornerRadius: 14))
                    }
                    .buttonStyle(.plain)
                }
                Spacer()
            }
            .padding(20)
            .background(Theme.bgSoft)
            .navigationTitle("提前几天提醒")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .topBarTrailing) { Button("关闭") { showDayPicker = false } } }
        }
        .presentationDetents([.medium])
        .presentationBackground(Theme.bgSoft)
    }

    private var timePicker: some View {
        NavigationStack {
            VStack(spacing: 12) {
                ForEach(["08:00", "09:00", "12:00", "18:00", "20:00", "21:00"], id: \.self) { t in
                    let parts = t.split(separator: ":").map { Int($0)! }
                    let isOn = notifications.notifyHour == parts[0] && notifications.notifyMinute == parts[1]
                    Button {
                        notifications.notifyHour = parts[0]
                        notifications.notifyMinute = parts[1]
                        notifications.rescheduleAll(memberships: memberships)
                        showTimePicker = false
                    } label: {
                        HStack {
                            Text(t).font(.system(size: 16, weight: .bold))
                                .foregroundStyle(isOn ? .white : Theme.txt)
                            Spacer()
                            if isOn { Image(systemName: "checkmark").foregroundStyle(.white) }
                        }
                        .padding(.vertical, 16).padding(.horizontal, 18)
                        .background(isOn ? Theme.accent : Color.white.opacity(0.06),
                                    in: RoundedRectangle(cornerRadius: 14))
                    }
                    .buttonStyle(.plain)
                }
                Spacer()
            }
            .padding(20)
            .background(Theme.bgSoft)
            .navigationTitle("提醒时间")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .topBarTrailing) { Button("关闭") { showTimePicker = false } } }
        }
        .presentationDetents([.medium, .large])
        .presentationBackground(Theme.bgSoft)
    }

    // MARK: - 导出

    private func exportData() {
        let export: [[String: Any]] = memberships.map { m in
            [
                "name": m.name, "price": m.price, "cycle": m.cycle.label,
                "nextDate": ISO8601DateFormatter().string(from: m.nextDate),
                "category": m.category, "method": m.method, "note": m.note,
                "status": m.status.label,
            ]
        }
        if let data = try? JSONSerialization.data(withJSONObject: export, options: [.prettyPrinted, .withoutEscapingSlashes]),
           let str = String(data: data, encoding: .utf8) {
            exportText = str
            showExport = true
        }
    }
}
