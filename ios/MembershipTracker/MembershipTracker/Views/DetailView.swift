import SwiftUI
import SwiftData

struct DetailView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @Bindable var membership: Membership

    @State private var showEdit = false
    @State private var confirmDelete = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 0) {
                    // 头部
                    VStack(spacing: 11) {
                        LogoBadge(abbr: membership.abbr, colorHex: membership.colorHex, size: 66)
                        Text(membership.name)
                            .font(.system(size: 22, weight: .heavy))
                            .foregroundStyle(Theme.txt)
                        Text("\(CategoryInfo.info(for: membership.category).icon) \(membership.category) · \(statusText)")
                            .font(.system(size: 13.5, weight: .semibold))
                    }
                    .padding(.top, 8)

                    // 信息列表
                    VStack(spacing: 0) {
                        infoRow("订阅价格", "¥\(money(membership.price)) / \(membership.cycle.label)", highlight: true)
                        infoRow("折合每月", "¥\(money(membership.monthlyCost))")
                        infoRow("下次扣费", "\(Membership.shortDate(membership.nextDate))（\(dueCountdown)）")
                        infoRow("支付方式", membership.method)
                        infoRow("订阅周期", membership.cycle.label)
                        if !membership.note.isEmpty {
                            infoRow("备注", membership.note)
                        }
                    }
                    .glassCard(radius: 22)
                    .padding(.horizontal, 22)
                    .padding(.top, 22)

                    // 操作
                    VStack(spacing: 12) {
                        Button { showEdit = true } label: {
                            Text("编辑信息").primaryButton()
                        }
                        .buttonStyle(.plain)

                        Button { toggleStatus() } label: {
                            Text(membership.status == .cancelled ? "恢复订阅" : "标记为已取消")
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 16)
                                .background(Color.white.opacity(0.07), in: RoundedRectangle(cornerRadius: 16))
                                .foregroundStyle(Theme.txt)
                                .font(.system(size: 16.5, weight: .bold))
                        }
                        .buttonStyle(.plain)

                        Button { confirmDelete = true } label: {
                            Text("删除该会员")
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 16)
                                .background(Theme.red.opacity(0.14), in: RoundedRectangle(cornerRadius: 16))
                                .overlay(RoundedRectangle(cornerRadius: 16).strokeBorder(Theme.red.opacity(0.3), lineWidth: 1))
                                .foregroundStyle(Theme.red)
                                .font(.system(size: 16.5, weight: .bold))
                        }
                        .buttonStyle(.plain)
                    }
                    .padding(.horizontal, 22)
                    .padding(.top, 22)

                    Spacer(minLength: 40)
                }
            }
            .background(Theme.bgSoft)
            .navigationTitle("会员详情")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("完成") { dismiss() }
                }
            }
            .sheet(isPresented: $showEdit) {
                MembershipFormView(membership: membership)
                    .presentationBackground(Theme.bgSoft)
            }
            .alert("确定删除该会员？", isPresented: $confirmDelete) {
                Button("取消", role: .cancel) {}
                Button("删除", role: .destructive) { delete() }
            } message: {
                Text("此操作不可恢复")
            }
        }
    }

    private var statusText: String {
        if membership.status == .cancelled { return "已取消" }
        let d = membership.daysUntilDue
        if d < 0 { return "已过期" }
        if d <= 7 { return "\(d) 天后到期" }
        return "生效中"
    }

    private var dueCountdown: String {
        let d = membership.daysUntilDue
        return d >= 0 ? "\(d)天后" : "已过期"
    }

    private func infoRow(_ k: String, _ v: String, highlight: Bool = false) -> some View {
        HStack {
            Text(k).font(.system(size: 14.5, weight: .semibold)).foregroundStyle(Theme.txt2)
            Spacer()
            Text(v)
                .font(.system(size: 14.5, weight: .bold))
                .foregroundStyle(highlight ? Theme.accent : Theme.txt)
                .multilineTextAlignment(.trailing)
        }
        .padding(.horizontal, 17).padding(.vertical, 14)
        .overlay(alignment: .bottom) {
            Rectangle().fill(Color.white.opacity(0.05)).frame(height: 1).padding(.leading, 17)
        }
    }

    private func toggleStatus() {
        membership.status = membership.status == .cancelled ? .active : .cancelled
        try? context.save()
        if let all = try? context.fetch(FetchDescriptor<Membership>()) {
            NotificationService.shared.rescheduleAll(memberships: all)
        }
    }

    private func delete() {
        context.delete(membership)
        try? context.save()
        dismiss()
    }
}

// MARK: - 主按钮样式

extension Text {
    func primaryButton() -> some View {
        self
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(Theme.accentGradient, in: RoundedRectangle(cornerRadius: 16))
            .foregroundStyle(.white)
            .font(.system(size: 16.5, weight: .bold))
            .shadow(color: Theme.accent.opacity(0.6), radius: 14, y: 8)
    }
}
