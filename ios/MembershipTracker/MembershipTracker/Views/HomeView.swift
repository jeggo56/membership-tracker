import SwiftUI
import SwiftData

struct HomeView: View {
    @Query(sort: \Membership.createdAt, order: .reverse) private var memberships: [Membership]
    @Binding var showAddSheet: Bool
    @State private var detailMembership: Membership?

    private var active: [Membership] { memberships.filter { $0.status == .active } }
    private var totalMonthly: Double { active.reduce(0) { $0 + $1.monthlyCost } }
    private var dueSoon: [Membership] { active.filter(\.isDueSoon).sorted { $0.daysUntilDue < $1.daysUntilDue } }
    private var yearlyCount: Int { active.filter { $0.cycle == .yearly }.count }

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                pageHead

                heroCard

                quickRow
                    .padding(.top, 16)

                if let first = dueSoon.first {
                    alertStrip(first)
                        .padding(.top, 16)
                }

                SectionTitle(text: "近期到期")
                    .padding(.top, 6)

                VStack(spacing: 11) {
                    let upcoming = active.sorted { $0.daysUntilDue < $1.daysUntilDue }.prefix(5)
                    if upcoming.isEmpty {
                        EmptyState(title: "还没有在订阅的会员",
                                   subtitle: "点击下方 ＋ 添加你的第一个会员")
                    } else {
                        ForEach(Array(upcoming)) { m in
                            MembershipCard(membership: m) { detailMembership = m }
                        }
                    }
                }
                .padding(.horizontal, 18)

                Spacer(minLength: 100)
            }
        }
        .background(Theme.bg)
        .sheet(item: $detailMembership) { m in
            DetailView(membership: m)
                .presentationBackground(Theme.bgSoft)
        }
    }

    // MARK: - 页头

    private var pageHead: some View {
        VStack(alignment: .leading, spacing: 5) {
            Text("会员概览")
                .font(.system(size: 31, weight: .heavy))
                .foregroundStyle(Theme.txt)
            Text("\(active.count) 个在订阅 · 每月自动扣费一目了然")
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(Theme.txt2)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 22)
        .padding(.top, 8)
    }

    // MARK: - Hero 卡

    private var heroCard: some View {
        ZStack(alignment: .topLeading) {
            Theme.heroGradient

            // 装饰圆
            Circle().fill(Color.white.opacity(0.14))
                .frame(width: 200, height: 200)
                .offset(x: 250, y: -90)
            Circle().fill(Color.white.opacity(0.08))
                .frame(width: 130, height: 130)
                .offset(x: 300, y: 60)

            VStack(alignment: .leading, spacing: 0) {
                Text("每月订阅支出")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(.white.opacity(0.88))

                HStack(alignment: .firstTextBaseline, spacing: 2) {
                    Text("¥").font(.system(size: 22, weight: .bold))
                    Text(money(totalMonthly)).font(.system(size: 44, weight: .heavy))
                        .tracking(-1.5)
                    Text("/月").font(.system(size: 15, weight: .semibold)).opacity(0.85)
                        .padding(.leading, 2)
                }
                .foregroundStyle(.white)
                .padding(.top, 2)

                HStack(spacing: 18) {
                    metaBlock("折合年费", "¥\(money(totalMonthly * 12))")
                    metaBlock("在订阅", "\(active.count) 项")
                }
                .padding(.top, 16)
            }
            .padding(22)
        }
        .clipShape(RoundedRectangle(cornerRadius: 26, style: .continuous))
        .shadow(color: Theme.accent.opacity(0.55), radius: 23, y: 18)
        .padding(.horizontal, 18)
        .padding(.top, 14)
    }

    private func metaBlock(_ label: String, _ value: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(label).font(.system(size: 12.5, weight: .semibold)).foregroundStyle(.white.opacity(0.9))
            Text(value).font(.system(size: 18, weight: .heavy)).tracking(-0.3).foregroundStyle(.white)
        }
    }

    // MARK: - 快捷统计

    private var quickRow: some View {
        HStack(spacing: 11) {
            quickCard(icon: "⏰", color: Theme.orange, value: "\(dueSoon.count)", label: "7天内到期")
            quickCard(icon: "📅", color: Theme.green, value: "\(yearlyCount)", label: "年付会员")
            quickCard(icon: "💳", color: Theme.accent, value: "\(active.count)", label: "自动续费")
        }
        .padding(.horizontal, 18)
    }

    private func quickCard(icon: String, color: Color, value: String, label: String) -> some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(icon)
                .font(.system(size: 15))
                .frame(width: 26, height: 26)
                .background(color.opacity(0.18), in: RoundedRectangle(cornerRadius: 8))
            Text(value).font(.system(size: 20, weight: .heavy)).foregroundStyle(Theme.txt)
            Text(label).font(.system(size: 11.5, weight: .semibold)).foregroundStyle(Theme.txt2)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.vertical, 14).padding(.horizontal, 12)
        .glassCard(radius: 15)
    }

    // MARK: - 提醒条

    private func alertStrip(_ m: Membership) -> some View {
        let d = m.daysUntilDue
        let when = d == 0 ? "今天" : (d == 1 ? "明天" : "\(d)天后")
        return HStack(spacing: 12) {
            Text("🔔").font(.system(size: 17))
                .frame(width: 34, height: 34)
                .background(Theme.orange.opacity(0.22), in: RoundedRectangle(cornerRadius: 10))
            (
                Text("最近一笔：").foregroundColor(Theme.txt)
                + Text(m.name).foregroundColor(Theme.orange).fontWeight(.heavy)
                + Text(" \(when)自动续费 ").foregroundColor(Theme.txt)
                + Text("¥\(money(m.price))").foregroundColor(Theme.orange).fontWeight(.heavy)
                + Text("，注意账户余额").foregroundColor(Theme.txt)
            )
            .font(.system(size: 13.5, weight: .semibold))
            .lineLimit(2)
            Spacer(minLength: 0)
        }
        .padding(13)
        .background(
            LinearGradient(colors: [Theme.orange.opacity(0.18), Theme.yellow.opacity(0.10)],
                           startPoint: .leading, endPoint: .trailing),
            in: RoundedRectangle(cornerRadius: 15, style: .continuous)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 15, style: .continuous)
                .strokeBorder(Theme.orange.opacity(0.30), lineWidth: 1)
        )
        .padding(.horizontal, 18)
    }
}

// Membership 已由 @Model 自动符合 Identifiable，无需扩展

