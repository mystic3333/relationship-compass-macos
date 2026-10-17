import SwiftUI

/// 中间栏联系人列表：按当前视图过滤，支持姓名/公司/职位搜索
struct ContactListView: View {
    @Binding var selection: Contact.ID?
    let section: SidebarSection
    @EnvironmentObject private var store: ContactStore
    @State private var searchText = ""
    @State private var showCSVImport = false

    private var filtered: [Contact] {
        var list = store.contacts(in: section)
        let query = searchText.trimmingCharacters(in: .whitespaces)
        if !query.isEmpty {
            list = list.filter {
                $0.name.localizedCaseInsensitiveContains(query)
                    || $0.company.localizedCaseInsensitiveContains(query)
                    || $0.position.localizedCaseInsensitiveContains(query)
            }
        }
        return list
    }

    var body: some View {
        Group {
            if filtered.isEmpty {
                ContentUnavailableView(
                    "没有联系人",
                    systemImage: "person.crop.circle.badge.questionmark",
                    description: Text("当前视图或搜索条件下没有联系人")
                )
            } else {
                List(selection: $selection) {
                    ForEach(filtered) { contact in
                        ContactRowView(contact: contact)
                            .tag(contact.id)
                    }
                }
            }
        }
        .searchable(text: $searchText, prompt: "搜索姓名、公司、职位")
        .navigationTitle(section.rawValue)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    showCSVImport = true
                } label: {
                    Label("导入 CSV", systemImage: "square.and.arrow.down")
                }
                .help("按固定模板批量导入联系人")
            }
        }
        .sheet(isPresented: $showCSVImport) {
            CSVImportView()
                .environmentObject(store)
        }
    }
}
