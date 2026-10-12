import SwiftUI

// MARK: - 会员卡片

struct MembershipCard: View {
    let membership: Membership
    var onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 14) {
                // 左侧色条
                Rectangle()
                    .fill(Color(hex: membership.colorHex))
                    .frame(width: 3.5)
                    .clipShape(RoundedRectangle(cornerRadius: 2))
                    .padding(.vertical, 14)

                LogoBadge(abbr: membership.abbr, colorHex: membership.colorHex, size: 48)

                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 6) {
                        Text(membership.name)
                            .font(.system(size: 16, weight: .bold))
                            .foregroundStyle(Theme.txt)
                        if membership.status == .cancelled {
                            Text("已取消")
                                .font(.system(size: 10, weight: .bold))
                                .foregroundStyle(Theme.txt2)
                                .padding(.horizontal, 6).padding(.vertical, 2)
                                .background(Theme.txt2.opacity(0.2), in: RoundedRectangle(cornerRadius: 6))
                        }
                    }
                    Text("\(CategoryInfo.info(for: membership.category).icon) \(membership.category) · \(membership.cycle.label) · \(membership.method)")
                        .font(.system(size: 12.5, weight: .medium))
                        .foregroundStyle(Theme.txt2)
                        .lineLimit(1)
                }

                Spacer(minLength: 4)

                VStack(alignment: .trailing, spacing: 4) {
                    Text("¥\(money(membership.price))")
                        .font(.system(size: 16, weight: .heavy))
                        .foregroundStyle(Theme.txt)
                    Text(membership.dueText)
                        .font(.system(size: 11.5, weight: .bold))
                        .foregroundStyle(dueColor)
                }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 6)
            .glassCard(radius: 22)
            .opacity(membership.status == .cancelled ? 0.5 : 1)
        }
        .buttonStyle(.plain)
    }

    private var dueColor: Color {
        if membership.status == .cancelled { return Theme.txt3 }
        let d = membership.daysUntilDue
        if d < 0 { return Theme.txt3 }
        if d == 0 { return Theme.red }
        if d <= 7 { return Theme.orange }
        return Theme.txt3
    }
}

// MARK: - 空状态

struct EmptyState: View {
    let title: String
    let subtitle: String
    var icon: String = "📭"

    var body: some View {
        VStack(spacing: 14) {
            Text(icon).font(.system(size: 52)).opacity(0.55)
            Text(title).font(.system(size: 17, weight: .bold)).foregroundStyle(Theme.txt)
            Text(subtitle)
                .font(.system(size: 13.5, weight: .medium))
                .foregroundStyle(Theme.txt2)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 60)
        .padding(.horizontal, 40)
    }
}

// MARK: - Section 标题

struct SectionTitle: View {
    let text: String
    var action: (label: String, handler: () -> Void)? = nil

    var body: some View {
        HStack {
            Text(text.uppercased())
                .font(.system(size: 13, weight: .bold))
                .foregroundStyle(Theme.txt2)
                .tracking(0.9)
            Spacer()
            if let action {
                Button(action.label, action: action.handler)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(Theme.accent)
            }
        }
        .padding(.horizontal, 22)
        .padding(.top, 22)
        .padding(.bottom, 11)
    }
}
