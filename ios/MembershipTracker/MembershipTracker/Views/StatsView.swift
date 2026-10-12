import SwiftUI
import SwiftData

struct StatsView: View {
    @Query private var memberships: [Membership]

    private var active: [Membership] { memberships.filter { $0.status == .active } }
    private var totalMonthly: Double { active.reduce(0) { $0 + $1.monthlyCost } }

    private var byCategory: [(name: String, amount: Double)] {
        var dict: [String: Double] = [:]
        active.forEach { dict[$0.category, default: 0] += $0.monthlyCost }
        return dict.map { (name: $0.key, amount: $0.value) }.sorted { $0.amount > $1.amount }
    }

    /// 近 6 个月支出（月度订阅全额，年付会员在到期月计入）
    private var last6Months: [(label: String, cost: Double)] {
        let cal = Calendar.current
        let now = Date()
        var result: [(String, Double)] = []
        for i in stride(from: 5, through: 0, by: -1) {
            guard let monthDate = cal.date(byAdding: .month, value: -i, to: now) else { continue }
            let comps = cal.dateComponents([.year, .month], from: monthDate)
            var cost = 0.0
            for m in active {
                if m.cycle == .monthly {
                    cost += m.price
                } else {
                    let dueComps = cal.dateComponents([.year, .month], from: m.nextDate)
                    if dueComps.year == comps.year && dueComps.month == comps.month {
                        cost += m.price
                    }
                }
            }
            result.append(("\(comps.month!)月", cost))
        }
        return result
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                VStack(alignment: .leading, spacing: 5) {
                    Text("支出统计").font(.system(size: 31, weight: .heavy)).foregroundStyle(Theme.txt)
                    Text("看清钱都花在了哪些会员上").font(.system(size: 14, weight: .medium)).foregroundStyle(Theme.txt2)
                }
                .padding(.horizontal, 22).padding(.top, 8)

                // 月度固定支出
                VStack(alignment: .leading, spacing: 3) {
                    Text("月度固定支出").font(.system(size: 13, weight: .semibold)).foregroundStyle(Theme.txt2)
                    HStack(alignment: .firstTextBaseline, spacing: 4) {
                        Text("¥\(money(totalMonthly))").font(.system(size: 36, weight: .heavy)).tracking(-1.2)
                        Text("/ 月").font(.system(size: 15, weight: .semibold)).foregroundStyle(Theme.txt2)
                    }
                    .foregroundStyle(Theme.txt)
                    Text("折合全年约 ¥\(money(totalMonthly * 12))")
                        .font(.system(size: 13, weight: .semibold)).foregroundStyle(Theme.txt2).padding(.top, 3)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(20)
                .glassCard(radius: 24)
                .padding(.horizontal, 18).padding(.top, 14)

                // 柱状图
                SectionTitle(text: "近 6 个月支出")
                barChart

                // 分类
                SectionTitle(text: "按分类")
                categoryList

                Spacer(minLength: 100)
            }
        }
        .background(Theme.bg)
    }

    private var barChart: some View {
        let months = last6Months
        let maxCost = max(months.map(\.cost).max() ?? 1, 1)
        return HStack(alignment: .bottom, spacing: 9) {
            ForEach(Array(months.enumerated()), id: \.offset) { _, m in
                VStack(spacing: 5) {
                    Text(m.cost > 0 ? money(m.cost) : "—")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundStyle(Theme.txt2)
                    RoundedRectangle(cornerRadius: 8)
                        .fill(LinearGradient(colors: [Theme.accent2, Theme.accent],
                                             startPoint: .top, endPoint: .bottom))
                        .frame(height: max(3, CGFloat(m.cost / maxCost) * 104))
                    Text(m.label).font(.system(size: 11, weight: .semibold)).foregroundStyle(Theme.txt2)
                }
                .frame(maxWidth: .infinity)
            }
        }
        .frame(height: 150)
        .padding(.horizontal, 18)
        .padding(.top, 4)
    }

    private var categoryList: some View {
        let cats = byCategory
        let maxAmount = cats.first?.amount ?? 1
        return VStack(spacing: 10) {
            if cats.isEmpty {
                EmptyState(title: "暂无数据", subtitle: "添加会员后自动统计")
            } else {
                ForEach(cats, id: \.name) { c in
                    let info = CategoryInfo.info(for: c.name)
                    HStack(spacing: 12) {
                        Text(info.icon)
                            .font(.system(size: 17))
                            .frame(width: 36, height: 36)
                            .background(Color(hex: info.colorHex).opacity(0.13),
                                        in: RoundedRectangle(cornerRadius: 11))
                        VStack(alignment: .leading, spacing: 6) {
                            HStack(spacing: 2) {
                                Text(c.name).font(.system(size: 14.5, weight: .bold)).foregroundStyle(Theme.txt)
                                Spacer()
                                Text("¥\(money(c.amount))").font(.system(size: 15, weight: .heavy)).foregroundStyle(Theme.txt)
                                Text("/月").font(.system(size: 11, weight: .semibold)).foregroundStyle(Theme.txt2)
                            }
                            GeometryReader { geo in
                                ZStack(alignment: .leading) {
                                    Capsule().fill(Color.white.opacity(0.08))
                                    Capsule().fill(Color(hex: info.colorHex))
                                        .frame(width: geo.size.width * CGFloat(c.amount / maxAmount))
                                }
                            }
                            .frame(height: 5)
                        }
                    }
                    .padding(.horizontal, 15).padding(.vertical, 13)
                    .glassCard(radius: 15)
                }
            }
        }
        .padding(.horizontal, 18)
    }
}
