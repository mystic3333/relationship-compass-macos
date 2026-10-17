import Foundation
import Combine

/// 联系人数据仓库：内存数组 + JSON 持久化（ADR-0004）
final class ContactStore: ObservableObject {
    @Published private(set) var contacts: [Contact] = []

    private let fileURL: URL

    /// - Parameters:
    ///   - seedIfEmpty: 存储为空时是否写入种子数据
    ///   - fileURL: 覆盖默认存储位置（测试注入临时文件用）
    init(seedIfEmpty: Bool = true, fileURL: URL? = nil) {
        let url = fileURL ?? Self.defaultFileURL()
        self.fileURL = url
        try? FileManager.default.createDirectory(
            at: url.deletingLastPathComponent(),
            withIntermediateDirectories: true
        )
        load()
        if seedIfEmpty && contacts.isEmpty {
            contacts = SeedData.make()
            save()
        }
    }

    static func defaultFileURL() -> URL {
        FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("RelationshipCompass", isDirectory: true)
            .appendingPathComponent("contacts.json")
    }

    // MARK: 持久化

    func load() {
        guard let data = try? Data(contentsOf: fileURL),
              let decoded = try? JSONDecoder().decode([Contact].self, from: data) else { return }
        contacts = decoded
    }

    func save() {
        guard let data = try? JSONEncoder().encode(contacts) else { return }
        try? data.write(to: fileURL, options: .atomic)
    }

    // MARK: 查询

    func contact(id: UUID) -> Contact? {
        contacts.first { $0.id == id }
    }

    func contacts(in section: SidebarSection) -> [Contact] {
        let base: [Contact]
        switch section {
        case .all: base = contacts
        case .important: base = contacts.filter { $0.importance == .important }
        case .due: base = contacts.filter(\.isDue)
        }
        return base.sorted(by: Contact.listOrder)
    }

    func count(in section: SidebarSection) -> Int {
        switch section {
        case .all: return contacts.count
        case .important: return contacts.filter { $0.importance == .important }.count
        case .due: return contacts.filter(\.isDue).count
        }
    }

    // MARK: 变更

    func addContact(_ contact: Contact) {
        contacts.append(contact)
        save()
    }

    func updateContact(_ contact: Contact) {
        guard let index = contacts.firstIndex(where: { $0.id == contact.id }) else { return }
        contacts[index] = contact
        save()
    }

    func deleteContact(id: UUID) {
        contacts.removeAll { $0.id == id }
        save()
    }

    func addInteraction(_ interaction: Interaction, to contactID: UUID) {
        guard let index = contacts.firstIndex(where: { $0.id == contactID }) else { return }
        contacts[index].interactions.append(interaction)
        save()
    }

    func deleteInteraction(id: UUID, from contactID: UUID) {
        guard let index = contacts.firstIndex(where: { $0.id == contactID }) else { return }
        contacts[index].interactions.removeAll { $0.id == id }
        save()
    }

    func importContacts(_ newContacts: [Contact]) {
        contacts.append(contentsOf: newContacts)
        save()
    }
}
