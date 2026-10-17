import SwiftUI

/// 联系人头像：首字 + 重要度颜色
struct ContactAvatar: View {
    let contact: Contact

    var body: some View {
        let color = contact.importance.color
        Circle()
            .fill(Color(red: color.red, green: color.green, blue: color.blue))
            .frame(width: 32, height: 32)
            .overlay(
                Text(String(contact.name.prefix(1)))
                    .foregroundStyle(.white)
                    .font(.system(size: 14, weight: .semibold))
            )
    }
}

/// 联系人列表行：姓名 + 逾期提示 + 公司/职位 + 上次联系时间
struct ContactRowView: View {
    let contact: Contact

    private var subtitle: String {
        switch (contact.company.isEmpty, contact.position.isEmpty) {
        case (false, false): return "\(contact.company) · \(contact.position)"
        case (false, true): return contact.company
        case (true, false): return contact.position
        case (true, true): return "—"
        }
    }

    var body: some View {
        HStack(spacing: 10) {
            ContactAvatar(contact: contact)
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 6) {
                    Text(contact.name)
                        .fontWeight(.medium)
                    if let label = contact.dueLabel {
                        Text(label)
                            .font(.caption)
                            .foregroundStyle(.orange)
                    }
                }
                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
            Spacer()
            if let last = contact.lastContactDate {
                Text(last, style: .relative)
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            } else {
                Text("从未联系")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }
        }
        .padding(.vertical, 2)
    }
}
