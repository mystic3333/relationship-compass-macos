import SwiftUI

struct SidebarView: View {
    @Binding var selection: SidebarSection?
    @EnvironmentObject private var store: ContactStore

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
    }
}
