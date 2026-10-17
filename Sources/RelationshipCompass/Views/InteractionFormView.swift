import SwiftUI

/// 添加互动记录表单（日期默认今天）
struct InteractionFormView: View {
    let contactID: UUID
    @EnvironmentObject private var store: ContactStore
    @Environment(\.dismiss) private var dismiss

    @State private var date: Date = Date.now
    @State private var method: InteractionMethod = .wechat
    @State private var notes: String = ""

    var body: some View {
        Form {
            DatePicker("日期", selection: $date, displayedComponents: [.date])
            Picker("方式", selection: $method) {
                ForEach(InteractionMethod.allCases) { m in
                    Label(m.rawValue, systemImage: m.icon).tag(m)
                }
            }
            TextField("备注", text: $notes, axis: .vertical)
                .lineLimit(2...4)
        }
        .formStyle(.grouped)
        .frame(width: 380, height: 260)
        .navigationTitle("添加互动")
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("取消") { dismiss() }
            }
            ToolbarItem(placement: .confirmationAction) {
                Button("添加") {
                    store.addInteraction(
                        Interaction(date: date, method: method, notes: notes),
                        to: contactID
                    )
                    dismiss()
                }
            }
        }
    }
}
