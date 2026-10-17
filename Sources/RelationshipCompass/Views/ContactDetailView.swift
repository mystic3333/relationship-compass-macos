import SwiftUI

/// 右侧详情栏（T1 先为占位，T4 实现完整详情）
struct ContactDetailView: View {
    let contact: Contact?

    var body: some View {
        if let contact {
            Text(contact.name)
                .font(.title)
                .padding()
        } else {
            ContentUnavailableView(
                "选择一个联系人",
                systemImage: "person.crop.circle",
                description: Text("从列表中选择一个联系人查看详情")
            )
        }
    }
}
