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

// MARK: - 列表排序与视图过滤（T2）

func testListOrder() {
    let now = Date.now
    func days(_ d: Int) -> Date {
        Calendar.current.date(byAdding: .day, value: -d, to: now) ?? now
    }
    let importantOld = Contact(name: "重要旧", importance: .important,
                               interactions: [Interaction(date: days(100), method: .phone)])
    let importantNew = Contact(name: "重要新", importance: .important,
                               interactions: [Interaction(date: days(2), method: .phone)])
    let importantNever = Contact(name: "重要从未", importance: .important, interactions: [])
    let normal = Contact(name: "一般", importance: .normal,
                         interactions: [Interaction(date: days(5), method: .phone)])

    let sorted = [normal, importantOld, importantNever, importantNew].sorted(by: Contact.listOrder)
    expectEqual(sorted.map(\.name), ["重要从未", "重要新", "重要旧", "一般"],
                "排序：重要度优先，同级从未联系在前，其次最近联系在前")
}

func testStoreContactsInSection() {
    let url = FileManager.default.temporaryDirectory
        .appendingPathComponent(UUID().uuidString, isDirectory: true)
        .appendingPathComponent("contacts.json")
    let store = ContactStore(seedIfEmpty: false, fileURL: url)
    store.addContact(Contact(name: "重要A", importance: .important,
                             interactions: [Interaction(date: Date.now, method: .phone)]))
    store.addContact(Contact(name: "普通B", importance: .ordinary, interactions: []))
    store.addContact(Contact(name: "重要C", importance: .important, interactions: []))

    expectEqual(store.contacts(in: .important).map(\.name), ["重要C", "重要A"], "重要视图只含重要联系人且按列表序")
    expectEqual(store.contacts(in: .due).map(\.name), ["重要C", "普通B"], "待联系视图含从未联系者，重要度优先")
    expectEqual(store.contacts(in: .all).count, 3, "全部视图含所有联系人")
}

// MARK: - 侧边栏计数随变更联动（T3）

func testCountsUpdateAfterMutations() {
    let url = FileManager.default.temporaryDirectory
        .appendingPathComponent(UUID().uuidString, isDirectory: true)
        .appendingPathComponent("contacts.json")
    let store = ContactStore(seedIfEmpty: false, fileURL: url)

    expectEqual(store.count(in: .all), 0, "空库全部 0")
    store.addContact(Contact(name: "甲", importance: .important, interactions: []))
    store.addContact(Contact(name: "乙", importance: .ordinary,
                             interactions: [Interaction(date: Date.now, method: .phone)]))
    expectEqual(store.count(in: .all), 2, "全部 2")
    expectEqual(store.count(in: .important), 1, "重要 1")
    expectEqual(store.count(in: .due), 1, "待联系 1（从未联系的甲）")

    store.deleteContact(id: store.contacts[0].id)
    expectEqual(store.count(in: .all), 1, "删除后全部 1")
    expectEqual(store.count(in: .due), 0, "删除后待联系 0")
}

// MARK: - 联系人更新（T5）

func testUpdateContact() {
    let url = FileManager.default.temporaryDirectory
        .appendingPathComponent(UUID().uuidString, isDirectory: true)
        .appendingPathComponent("contacts.json")
    let store = ContactStore(seedIfEmpty: false, fileURL: url)

    var c = Contact(name: "甲", importance: .normal)
    store.addContact(c)
    c = store.contact(id: c.id)!
    c.importance = .important
    c.cadenceDays = 7
    c.company = "新公司"
    store.updateContact(c)

    let reloaded = store.contact(id: c.id)!
    expectEqual(reloaded.importance, .important, "重要度应更新")
    expectEqual(reloaded.cadenceDays, 7, "频率应更新")
    expectEqual(reloaded.company, "新公司", "公司应更新")
    expectEqual(reloaded.name, "甲", "姓名保持不变")
}

testSeedData()
testStore()
testListOrder()
testStoreContactsInSection()
testCountsUpdateAfterMutations()
testUpdateContact()

print("")
print("通过 \(passed) / \(passed + failed)")
if failed > 0 {
    print("失败 \(failed) 项")
    exit(1)
}
