import SwiftUI

/// 中间栏联系人列表（T1 先为空壳，T2 填充内容）
struct ContactListView: View {
    @Binding var selection: Contact.ID?
    let section: SidebarSection

    var body: some View {
        List(selection: $selection) {
            // 占位，T2 实现
        }
        .navigationTitle(section.rawValue)
    }
}
