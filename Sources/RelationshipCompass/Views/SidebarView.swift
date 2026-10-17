import SwiftUI

struct SidebarView: View {
    @Binding var selection: SidebarSection?
    @EnvironmentObject private var store: ContactStore
    @State private var showAddSheet = false

    var body: some View {
        List(SidebarSection.allCases, selection: $selection) { section in
            HStack {
                Label(section.rawValue, systemImage: section.icon)
                Spacer()
                Text("\(store.count(in: section))")
                    .foregroundStyle(.secondary)
                    .monospacedDigit()
            }
            .tag(section)
        }
        .navigationTitle("视图")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    showAddSheet = true
                } label: {
                    Label("新增联系人", systemImage: "plus")
                }
            }
        }
        .sheet(isPresented: $showAddSheet) {
            ContactFormView()
                .environmentObject(store)
        }
    }
}
