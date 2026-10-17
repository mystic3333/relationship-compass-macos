@testable import RelationshipCompass
import Foundation

// MARK: - 极简断言（CLT 无 XCTest，见 ADR-0005）

private var passed = 0
private var failed = 0

func expect(_ condition: @autoclosure () -> Bool, _ name: String, file: String = #file, line: Int = #line) {
    if condition() {
        passed += 1
    } else {
        failed += 1
        print("FAIL: \(name) (\((file as NSString).lastPathComponent):\(line))")
    }
}

func expectEqual<T: Equatable>(_ actual: T, _ expected: T, _ name: String, file: String = #file, line: Int = #line) {
    if actual == expected {
        passed += 1
    } else {
        failed += 1
        print("FAIL: \(name) — 期望 \(expected)，实际 \(actual) (\((file as NSString).lastPathComponent):\(line))")
    }
}

// MARK: - 种子数据（T1）

func testSeedData() {
    let contacts = SeedData.make()
    expectEqual(contacts.count, 20, "种子应为 20 个联系人")
    expectEqual(contacts.filter { $0.importance == .important }.count, 6, "重要应 6 个")
    expectEqual(contacts.filter { $0.importance == .normal }.count, 7, "一般应 7 个")
    expectEqual(contacts.filter { $0.importance == .ordinary }.count, 7, "普通应 7 个")
    for contact in contacts {
        expect(!contact.interactions.isEmpty, "\(contact.name) 应有互动记录")
    }
    expectEqual(contacts.filter(\.isDue).count, 8, "待联系应 8 个")
}

// MARK: - 存储（T1）

func testStore() {
    let seedURL = FileManager.default.temporaryDirectory
        .appendingPathComponent(UUID().uuidString, isDirectory: true)
        .appendingPathComponent("contacts.json")

    let first = ContactStore(seedIfEmpty: true, fileURL: seedURL)
    expectEqual(first.contacts.count, 20, "空文件首次应写入种子")
    let second = ContactStore(seedIfEmpty: true, fileURL: seedURL)
    expectEqual(second.contacts.count, 20, "再次加载不应重复写入种子")

    let persistURL = FileManager.default.temporaryDirectory
        .appendingPathComponent(UUID().uuidString, isDirectory: true)
        .appendingPathComponent("contacts.json")
    let writer = ContactStore(seedIfEmpty: false, fileURL: persistURL)
    writer.addContact(Contact(name: "测试联系人", company: "测试公司", importance: .important))
    let reader = ContactStore(seedIfEmpty: false, fileURL: persistURL)
    expectEqual(reader.contacts.count, 1, "变更应持久化")
    expectEqual(reader.contacts.first?.name, "测试联系人", "姓名应持久化")
    expectEqual(reader.contacts.first?.importance, .important, "重要度应持久化")

    let dueURL = FileManager.default.temporaryDirectory
        .appendingPathComponent(UUID().uuidString, isDirectory: true)
        .appendingPathComponent("contacts.json")
    let store = ContactStore(seedIfEmpty: false, fileURL: dueURL)
    let newContact = Contact(name: "某人", importance: .important)
    store.addContact(newContact)
    let id = store.contacts[0].id
    expect(store.contact(id: id)?.isDue == true, "从未联系应视为待联系")
    store.addInteraction(Interaction(date: Date.now, method: .phone), to: id)
    expect(store.contact(id: id)?.isDue == false, "刚联系过不应待联系")
    expectEqual(store.count(in: .due), 0, "待联系计数应随之更新")
}

testSeedData()
testStore()

print("")
print("通过 \(passed) / \(passed + failed)")
if failed > 0 {
    print("失败 \(failed) 项")
    exit(1)
}
