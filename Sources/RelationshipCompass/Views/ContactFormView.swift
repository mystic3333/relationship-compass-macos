import SwiftUI

/// 新增/编辑联系人表单（姓名必填）
struct ContactFormView: View {
    let existing: Contact?
    @EnvironmentObject private var store: ContactStore
    @Environment(\.dismiss) private var dismiss

    @State private var name: String
    @State private var company: String
    @State private var position: String
    @State private var phone: String
    @State private var email: String
    @State private var notes: String
    @State private var importance: ImportanceLevel
    @State private var cadenceOption: CadenceOption
    @State private var customDays: Int

    private var isEditing: Bool { existing != nil }

    init(existing: Contact? = nil) {
        self.existing = existing
        _name = State(initialValue: existing?.name ?? "")
        _company = State(initialValue: existing?.company ?? "")
        _position = State(initialValue: existing?.position ?? "")
        _phone = State(initialValue: existing?.phone ?? "")
        _email = State(initialValue: existing?.email ?? "")
        _notes = State(initialValue: existing?.notes ?? "")
        _importance = State(initialValue: existing?.importance ?? .normal)
        _customDays = State(initialValue: existing?.cadenceDays ?? 14)
        _cadenceOption = State(initialValue: CadenceOption.option(forDays: existing?.cadenceDays))
    }

    var body: some View {
        Form {
            Section("基本信息") {
                TextField("姓名 *", text: $name)
                TextField("公司", text: $company)
                TextField("职位", text: $position)
            }
            Section("联系方式") {
                TextField("电话", text: $phone)
                TextField("邮箱", text: $email)
            }
            Section("备注") {
                TextField("备注", text: $notes, axis: .vertical)
                    .lineLimit(3...6)
            }
            Section("重要度与频率") {
                Picker("重要度", selection: $importance) {
                    ForEach(ImportanceLevel.allCases) { level in
                        Text(level.rawValue).tag(level)
                    }
                }
                Picker("频率", selection: $cadenceOption) {
                    ForEach(CadenceOption.allCases) { option in
                        Text(option.rawValue).tag(option)
                    }
                }
                if cadenceOption == .custom {
                    Stepper(value: $customDays, in: 1...365) {
                        Text("自定义天数：\(customDays) 天")
                    }
                }
            }
        }
        .formStyle(.grouped)
        .frame(width: 420, height: 460)
        .navigationTitle(isEditing ? "编辑联系人" : "新增联系人")
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("取消") { dismiss() }
            }
            ToolbarItem(placement: .confirmationAction) {
                Button(isEditing ? "保存" : "新增") {
                    save()
                }
                .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty)
            }
        }
    }

    private func save() {
        let trimmedName = name.trimmingCharacters(in: .whitespaces)
        let cadence: Int? = cadenceOption == .custom ? max(1, customDays) : cadenceOption.days
        if var contact = existing {
            contact.name = trimmedName
            contact.company = company
            contact.position = position
            contact.phone = phone
            contact.email = email
            contact.notes = notes
            contact.importance = importance
            contact.cadenceDays = cadence
            store.updateContact(contact)
        } else {
            store.addContact(Contact(
                name: trimmedName, company: company, position: position,
                phone: phone, email: email, notes: notes,
                importance: importance, cadenceDays: cadence
            ))
        }
        dismiss()
    }
}
