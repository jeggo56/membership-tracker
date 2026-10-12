import SwiftUI
import SwiftData

struct MembershipFormView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss

    /// nil = 新增，非 nil = 编辑
    let membership: Membership?

    @State private var name = ""
    @State private var priceText = ""
    @State private var category = "视频"
    @State private var cycle: BillingCycle = .monthly
    @State private var nextDate = Calendar.current.date(byAdding: .day, value: 30, to: Date()) ?? Date()
    @State private var method = "微信支付"
    @State private var note = ""
    @State private var abbr = ""
    @State private var colorHex = "#6c8cff"
    @State private var selectedPreset: String? = nil

    private let methods = ["微信支付", "支付宝", "京东支付", "信用卡", "Apple Pay", "其它"]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    // 平台快选
                    VStack(alignment: .leading, spacing: 7) {
                        fieldLabel("快捷选择平台")
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 9) {
                                ForEach(PlatformPreset.all) { p in
                                    presetChip(p)
                                }
                            }
                            .padding(.vertical, 2)
                        }
                    }

                    inputField("会员名称", text: $name, placeholder: "如：腾讯视频 VIP")

                    HStack(spacing: 12) {
                        inputField("价格（元）", text: $priceText, placeholder: "0.00", keyboard: .decimalPad)
                        VStack(alignment: .leading, spacing: 7) {
                            fieldLabel("分类")
                            Menu {
                                Picker("分类", selection: $category) {
                                    ForEach(CategoryInfo.names, id: \.self) { Text($0).tag($0) }
                                }
                            } label: {
                                HStack {
                                    Text(category).foregroundStyle(Theme.txt).font(.system(size: 16, weight: .semibold))
                                    Spacer()
                                    Image(systemName: "chevron.up.chevron.down").font(.system(size: 11)).foregroundStyle(Theme.txt3)
                                }
                                .padding(.horizontal, 15).padding(.vertical, 13)
                                .background(Color.white.opacity(0.06), in: RoundedRectangle(cornerRadius: 13))
                                .overlay(RoundedRectangle(cornerRadius: 13).strokeBorder(Color.white.opacity(0.1), lineWidth: 1))
                            }
                        }
                    }

                    // 周期分段
                    VStack(alignment: .leading, spacing: 7) {
                        fieldLabel("订阅周期")
                        HStack(spacing: 4) {
                            ForEach(BillingCycle.allCases) { c in
                                Button {
                                    withAnimation(.easeInOut(duration: 0.15)) { cycle = c }
                                } label: {
                                    Text(c.label)
                                        .font(.system(size: 14, weight: .bold))
                                        .foregroundStyle(cycle == c ? .white : Theme.txt2)
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, 10)
                                        .background(cycle == c ? Theme.accent : Color.clear,
                                                    in: RoundedRectangle(cornerRadius: 10))
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding(4)
                        .background(Color.white.opacity(0.06), in: RoundedRectangle(cornerRadius: 13))
                    }

                    // 日期
                    VStack(alignment: .leading, spacing: 7) {
                        fieldLabel("下次扣费/到期日")
                        DatePicker("", selection: $nextDate, displayedComponents: .date)
                            .datePickerStyle(.compact)
                            .labelsHidden()
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.horizontal, 15).padding(.vertical, 10)
                            .background(Color.white.opacity(0.06), in: RoundedRectangle(cornerRadius: 13))
                            .overlay(RoundedRectangle(cornerRadius: 13).strokeBorder(Color.white.opacity(0.1), lineWidth: 1))
                            .environment(\.locale, Locale(identifier: "zh_CN"))
                    }

                    // 支付方式
                    VStack(alignment: .leading, spacing: 7) {
                        fieldLabel("支付方式")
                        Menu {
                            Picker("支付方式", selection: $method) {
                                ForEach(methods, id: \.self) { Text($0).tag($0) }
                            }
                        } label: {
                            HStack {
                                Text(method).foregroundStyle(Theme.txt).font(.system(size: 16, weight: .semibold))
                                Spacer()
                                Image(systemName: "chevron.up.chevron.down").font(.system(size: 11)).foregroundStyle(Theme.txt3)
                            }
                            .padding(.horizontal, 15).padding(.vertical, 13)
                            .background(Color.white.opacity(0.06), in: RoundedRectangle(cornerRadius: 13))
                            .overlay(RoundedRectangle(cornerRadius: 13).strokeBorder(Color.white.opacity(0.1), lineWidth: 1))
                        }
                    }

                    // 备注
                    VStack(alignment: .leading, spacing: 7) {
                        fieldLabel("备注")
                        TextField("如：连续包月，自动续费", text: $note, axis: .vertical)
                            .lineLimit(2...4)
                            .font(.system(size: 14.5, weight: .medium))
                            .foregroundStyle(Theme.txt)
                            .padding(.horizontal, 15).padding(.vertical, 13)
                            .background(Color.white.opacity(0.06), in: RoundedRectangle(cornerRadius: 13))
                            .overlay(RoundedRectangle(cornerRadius: 13).strokeBorder(Color.white.opacity(0.1), lineWidth: 1))
                    }

                    Button(action: save) {
                        Text(membership == nil ? "添加会员" : "保存修改").primaryButton()
                    }
                    .buttonStyle(.plain)
                    .padding(.top, 4)

                    Spacer(minLength: 20)
                }
                .padding(22)
            }
            .background(Theme.bgSoft)
            .navigationTitle(membership == nil ? "添加会员" : "编辑会员")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("取消") { dismiss() }
                }
            }
            .onAppear(perform: load)
        }
    }

    // MARK: - 子组件

    private func fieldLabel(_ t: String) -> some View {
        Text(t.uppercased())
            .font(.system(size: 12.5, weight: .bold))
            .foregroundStyle(Theme.txt2)
            .tracking(0.3)
    }

    private func inputField(_ label: String, text: Binding<String>, placeholder: String,
                           keyboard: UIKeyboardType = .default) -> some View {
        VStack(alignment: .leading, spacing: 7) {
            fieldLabel(label)
            TextField(placeholder, text: text)
                .keyboardType(keyboard)
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(Theme.txt)
                .padding(.horizontal, 15).padding(.vertical, 13)
                .background(Color.white.opacity(0.06), in: RoundedRectangle(cornerRadius: 13))
                .overlay(RoundedRectangle(cornerRadius: 13).strokeBorder(Color.white.opacity(0.1), lineWidth: 1))
        }
    }

    private func presetChip(_ p: PlatformPreset) -> some View {
        let on = selectedPreset == p.id
        return Button {
            selectPreset(p)
        } label: {
            VStack(spacing: 5) {
                LogoBadge(abbr: p.abbr, colorHex: p.colorHex, size: 30)
                Text(p.name)
                    .font(.system(size: 9.5, weight: .semibold))
                    .foregroundStyle(Theme.txt2)
                    .lineLimit(1)
            }
            .frame(width: 62)
            .padding(.vertical, 9)
            .background(on ? Theme.accent.opacity(0.16) : Color.white.opacity(0.05),
                        in: RoundedRectangle(cornerRadius: 14))
            .overlay(RoundedRectangle(cornerRadius: 14)
                .strokeBorder(on ? Theme.accent : Color.white.opacity(0.08), lineWidth: 1.5))
        }
        .buttonStyle(.plain)
    }

    // MARK: - 逻辑

    private func selectPreset(_ p: PlatformPreset) {
        selectedPreset = p.id
        name = p.name
        abbr = p.abbr
        colorHex = p.colorHex
        category = p.category
    }

    private func load() {
        guard let m = membership else { return }
        name = m.name
        priceText = money(m.price)
        category = m.category
        cycle = m.cycle
        nextDate = m.nextDate
        method = m.method
        note = m.note
        abbr = m.abbr
        colorHex = m.colorHex
        selectedPreset = PlatformPreset.all.first { $0.name == m.name }?.id
    }

    private func save() {
        let trimmed = name.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return }
        guard let price = Double(priceText.replacingOccurrences(of: ",", with: "")), price >= 0 else { return }

        let finalAbbr = abbr.isEmpty ? String(trimmed.prefix(1)) : abbr

        if let m = membership {
            // 编辑
            m.name = trimmed
            m.price = price
            m.category = category
            m.cycle = cycle
            m.nextDate = nextDate
            m.method = method
            m.note = note
            m.abbr = finalAbbr
            m.colorHex = colorHex
        } else {
            // 新增
            let m = Membership(
                name: trimmed, abbr: finalAbbr, colorHex: colorHex, category: category,
                price: price, cycle: cycle, nextDate: nextDate, method: method, note: note
            )
            context.insert(m)
        }

        try? context.save()

        // 重新调度提醒
        if let all = try? context.fetch(FetchDescriptor<Membership>()) {
            NotificationService.shared.rescheduleAll(memberships: all)
        }
        dismiss()
    }
}
