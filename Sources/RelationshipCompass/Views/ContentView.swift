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
    }
}
