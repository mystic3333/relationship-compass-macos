import SwiftUI

struct ContentView: View {
    @EnvironmentObject private var store: ContactStore
    @State private var section: SidebarSection? = .all
    @State private var selectedID: Contact.ID?

    private var selectedContact: Contact? {
        selectedID.flatMap { store.contact(id: $0) }
    }

    var body: some View {
        NavigationSplitView {
            SidebarView(selection: $section)
                .navigationSplitViewColumnWidth(min: 180, ideal: 220)
        } content: {
            ContactListView(selection: $selectedID, section: section ?? .all)
                .navigationSplitViewColumnWidth(min: 240, ideal: 300)
        } detail: {
            ContactDetailView(contact: selectedContact)
        }
        .navigationTitle("人脉罗盘")
        .onChange(of: section ?? .all) { _, newSection in
            // 切换视图时，若选中联系人不在新视图内则清空选中
            guard let id = selectedID else { return }
            if !store.contacts(in: newSection).contains(where: { $0.id == id }) {
                selectedID = nil
            }
        }
    }
}
