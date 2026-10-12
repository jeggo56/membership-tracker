import SwiftUI
import SwiftData

struct ListView: View {
    @Query(sort: \Membership.createdAt, order: .reverse) private var memberships: [Membership]
    @Binding var showAddSheet: Bool
    @State private var filterCat: String = "全部"
    @State private var detailMembership: Membership?

    private var filtered: [Membership] {
        var list = memberships
        if filterCat != "全部" { list = list.filter { $0.category == filterCat } }
        return list.sorted { a, b in
            if a.status != b.status { return a.status == .active }
            return a.daysUntilDue < b.daysUntilDue
        }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                VStack(alignment: .leading, spacing: 5) {
                    Text("我的会员")
                        .font(.system(size: 31, weight: .heavy))
                        .foregroundStyle(Theme.txt)
                    Text("共 \(memberships.count) 项 · 点按查看详情")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(Theme.txt2)
                }
                .padding(.horizontal, 22)
                .padding(.top, 8)

                // 分类 chips
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        chip("全部")
                        ForEach(CategoryInfo.names, id: \.self) { c in chip(c) }
                    }
                    .padding(.horizontal, 18)
                }
                .padding(.top, 14)

                // 列表
                VStack(spacing: 11) {
                    if filtered.isEmpty {
                        EmptyState(title: "这里是空的", subtitle: "换个分类看看，或添加新会员")
                    } else {
                        ForEach(filtered) { m in
                            MembershipCard(membership: m) { detailMembership = m }
                        }
                    }
                }
                .padding(.horizontal, 18)
                .padding(.top, 14)

                Spacer(minLength: 100)
            }
        }
        .background(Theme.bg)
        .sheet(item: $detailMembership) { m in
            DetailView(membership: m)
                .presentationBackground(Theme.bgSoft)
        }
    }

    private func chip(_ c: String) -> some View {
        let on = filterCat == c
        return Button {
            withAnimation(.easeInOut(duration: 0.15)) { filterCat = c }
        } label: {
            Text(c)
                .font(.system(size: 13, weight: .bold))
                .foregroundStyle(on ? .white : Theme.txt2)
                .padding(.horizontal, 15).padding(.vertical, 8)
                .background(on ? Theme.accent : Color.white.opacity(0.05),
                            in: Capsule())
                .overlay(Capsule().strokeBorder(on ? Color.clear : Color.white.opacity(0.1), lineWidth: 1))
        }
        .buttonStyle(.plain)
    }
}
