import SwiftUI

/// 右侧详情栏：资料、重要度、联系节奏、互动记录
struct ContactDetailView: View {
    let contact: Contact?
    @EnvironmentObject private var store: ContactStore

    /// 始终取 store 中最新值，避免展示陈旧数据
    private var current: Contact? {
        guard let id = contact?.id else { return nil }
        return store.contact(id: id)
    }

    private func update(_ transform: (inout Contact) -> Void) {
        guard var c = current else { return }
        transform(&c)
        store.updateContact(c)
    }

    // MARK: - 待联系状态文案

    private func dueExplanation(for c: Contact) -> String {
        if let last = c.lastContactDate {
            let days = Calendar.current.dateComponents([.day], from: last, to: Date.now).day ?? 0
            if let due = c.dueDate, due < Date.now {
                let overdue = Calendar.current.dateComponents([.day], from: due, to: Date.now).day ?? 0
                return "上次联系 \(days) 天前 · 频率每 \(c.effectiveCadenceDays) 天 · 已逾期 \(overdue) 天"
            } else if let due = c.dueDate {
                let remaining = Calendar.current.dateComponents([.day], from: Date.now, to: due).day ?? 0
                return "上次联系 \(days) 天前 · 频率每 \(c.effectiveCadenceDays) 天 · 还有 \(remaining) 天应联系"
            }
            return "上次联系 \(days) 天前 · 频率每 \(c.effectiveCadenceDays) 天"
        }
        return "从未联系 · 待联系"
    }

    // MARK: - 频率选择

    private var cadenceBinding: Binding<CadenceOption> {
        Binding(
            get: { CadenceOption.option(forDays: current?.cadenceDays) },
            set: { option in
                update { c in
                    if option == .custom {
                        c.cadenceDays = c.cadenceDays ?? 14
                    } else {
                        c.cadenceDays = option.days
                    }
                }
            }
        )
    }

    private var customDaysBinding: Binding<Int> {
        Binding(
            get: { current?.cadenceDays ?? 14 },
            set: { days in update { $0.cadenceDays = max(1, days) } }
        )
    }

    // MARK: - 重要度选择

    private var importanceBinding: Binding<ImportanceLevel> {
        Binding(
            get: { current?.importance ?? .normal },
            set: { level in update { $0.importance = level } }
        )
    }

    // MARK: - 主体

    var body: some View {
        if let c = current {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    header(c)
                    infoSection(c)
                    cadenceSection(c)
                    interactionsSection(c)
                }
                .padding(20)
            }
        } else {
            ContentUnavailableView(
                "选择一个联系人",
                systemImage: "person.crop.circle",
                description: Text("从列表中选择一个联系人查看详情")
            )
        }
    }

    private func header(_ c: Contact) -> some View {
        HStack(spacing: 14) {
            ContactAvatar(contact: c)
                .scaleEffect(1.8)
            VStack(alignment: .leading, spacing: 4) {
                Text(c.name)
                    .font(.title2)
                    .fontWeight(.semibold)
                if let label = c.dueLabel {
                    Label(label, systemImage: "bell")
                        .font(.callout)
                        .foregroundStyle(.orange)
                }
            }
            Spacer()
            Picker("重要度", selection: importanceBinding) {
                ForEach(ImportanceLevel.allCases) { level in
                    Text(level.rawValue).tag(level)
                }
            }
            .pickerStyle(.menu)
            .fixedSize()
        }
        .padding(.bottom, 4)
    }

    private func infoSection(_ c: Contact) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("基本资料").font(.headline)
            if !c.company.isEmpty {
                infoRow(icon: "building.2", text: c.position.isEmpty ? c.company : "\(c.company) · \(c.position)")
            } else if !c.position.isEmpty {
                infoRow(icon: "building.2", text: c.position)
            }
            if !c.phone.isEmpty {
                infoRow(icon: "phone", text: c.phone,
                        link: URL(string: "tel:\(c.phone.replacingOccurrences(of: "-", with: ""))"))
            }
            if !c.email.isEmpty {
                infoRow(icon: "envelope", text: c.email, link: URL(string: "mailto:\(c.email)"))
            }
            if !c.notes.isEmpty {
                infoRow(icon: "note.text", text: c.notes)
            }
            if c.company.isEmpty && c.position.isEmpty && c.phone.isEmpty && c.email.isEmpty && c.notes.isEmpty {
                Text("暂无其他资料").foregroundStyle(.secondary).font(.callout)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func infoRow(icon: String, text: String, link: URL? = nil) -> some View {
        HStack(alignment: .top, spacing: 8) {
            Image(systemName: icon)
                .foregroundStyle(.secondary)
                .frame(width: 18)
            if let link {
                Link(text, destination: link)
            } else {
                Text(text)
            }
            Spacer()
        }
    }

    private func cadenceSection(_ c: Contact) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("联系节奏").font(.headline)
            HStack {
                Text("频率")
                Spacer()
                Picker("频率", selection: cadenceBinding) {
                    ForEach(CadenceOption.allCases) { option in
                        Text(option.rawValue).tag(option)
                    }
                }
                .pickerStyle(.menu)
                .fixedSize()
            }
            if CadenceOption.option(forDays: c.cadenceDays) == .custom {
                HStack {
                    Text("自定义天数")
                    Spacer()
                    Stepper(value: customDaysBinding, in: 1...365) {
                        Text("\(customDaysBinding.wrappedValue) 天")
                            .monospacedDigit()
                    }
                }
            }
            Label(dueExplanation(for: c), systemImage: "calendar")
                .font(.callout)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func interactionsSection(_ c: Contact) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("互动记录").font(.headline)
            if c.interactions.isEmpty {
                Text("还没有互动记录，添加一条试试")
                    .font(.callout)
                    .foregroundStyle(.secondary)
            } else {
                ForEach(c.interactions.sorted { $0.date > $1.date }) { interaction in
                    HStack(alignment: .top, spacing: 8) {
                        Image(systemName: interaction.method.icon)
                            .foregroundStyle(.secondary)
                            .frame(width: 18)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(interaction.date, format: .dateTime.year().month().day())
                                .font(.callout)
                            if !interaction.notes.isEmpty {
                                Text(interaction.notes)
                                    .font(.callout)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        Spacer()
                        Text(interaction.date, style: .relative)
                            .font(.caption)
                            .foregroundStyle(.tertiary)
                    }
                    .padding(.vertical, 2)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
