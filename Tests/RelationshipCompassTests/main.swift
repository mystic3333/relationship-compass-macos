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

// MARK: - 互动记录删除联动（T6）

func testDeleteInteractionRecalculatesDue() {
    let url = FileManager.default.temporaryDirectory
        .appendingPathComponent(UUID().uuidString, isDirectory: true)
        .appendingPathComponent("contacts.json")
    let store = ContactStore(seedIfEmpty: false, fileURL: url)

    let newContact = Contact(name: "甲", importance: .important, interactions: [])
    store.addContact(newContact)
    let id = store.contacts[0].id

    store.addInteraction(Interaction(date: Date.now, method: .phone), to: id)
    let afterAdd = store.contact(id: id)!
    expect(afterAdd.isDue == false, "添加互动后不再待联系")

    let interactionID = afterAdd.interactions[0].id
    store.deleteInteraction(id: interactionID, from: id)
    let afterDelete = store.contact(id: id)!
    expect(afterDelete.isDue == true, "删除唯一互动后回到待联系")
    expect(afterDelete.interactions.isEmpty, "互动记录应被移除")
}

// MARK: - CSV 解析（T7）

func testCSVParsing_basic() {
    let csv = """
    姓名,公司,职位,电话,邮箱,备注,重要度,联系频率
    张三,某某公司,经理,13812345678,zhang@x.com,备注,重要,每月
    "李,四",,主管,,,含逗号,一般,每季
    ,,职位,,,缺姓名,普通,每周
    """
    let result = CSVImporter.parse(csv)
    expectEqual(result.contacts.count, 2, "应导入 2 条，跳过缺姓名行")
    expectEqual(result.skippedRows, 1, "缺姓名行应被跳过")

    let zhang = result.contacts[0]
    expectEqual(zhang.name, "张三", "姓名")
    expectEqual(zhang.company, "某某公司", "公司")
    expectEqual(zhang.position, "经理", "职位")
    expectEqual(zhang.importance, .important, "重要度映射")
    expectEqual(zhang.cadenceDays, 30, "每月 → 30 天")

    let li = result.contacts[1]
    expectEqual(li.name, "李,四", "引号包裹的逗号")
    expectEqual(li.notes, "含逗号", "备注列")
    expectEqual(li.importance, .normal, "一般 → normal")
    expectEqual(li.cadenceDays, 90, "每季 → 90 天")
}

func testCSVParsing_noHeaderAndCustomDays() {
    let result = CSVImporter.parse("王五,公司,,,,,普通,14")
    expectEqual(result.contacts.count, 1, "无表头也能导入")
    expectEqual(result.contacts[0].name, "王五", "姓名")
    expectEqual(result.contacts[0].importance, .ordinary, "普通 → ordinary")
    expectEqual(result.contacts[0].cadenceDays, 14, "数字频率解析为自定义天数")
}

func testCSVParsing_escapedQuoteAndEmptyCadence() {
    // 标准 CSV：字段整体用引号包裹，内部双引号以 "" 转义
    let result = CSVImporter.parse("赵六,公司,职位,,,\"他说\"\"好的\"\"\",重要,")
    expectEqual(result.contacts.count, 1, "转义引号行应导入")
    expectEqual(result.contacts[0].notes, "他说\"好的\"", "双引号转义")
    expectEqual(result.contacts[0].cadenceDays, nil, "留空频率 → 按重要度默认")
}

func testCSVParsing_invalidImportanceDefaultsNormal() {
    let result = CSVImporter.parse("钱七,公司,,,,,超级重要,每周")
    expectEqual(result.contacts.count, 1, "非法重要度容错")
    expectEqual(result.contacts[0].importance, .normal, "非法重要度回退为一般")
    expectEqual(result.contacts[0].cadenceDays, 7, "每周 → 7 天")
}

// MARK: - 待联系推导边界（T8）

func testDueDerivation() {
    let cal = Calendar.current
    let now = Date.now
    func days(_ d: Int) -> Date {
        cal.date(byAdding: .day, value: d, to: now) ?? now
    }

    // 从未联系 → 待联系
    let never = Contact(name: "从未", importance: .normal, interactions: [])
    expect(never.isDue == true, "从未联系应待联系")
    expect(never.lastContactDate == nil, "从未联系无上次联系时间")
    expectEqual(never.dueLabel, "从未联系", "从未联系文案")

    // 默认频率：重要→30，一般→90，普通→180
    let important = Contact(name: "重要", importance: .important,
                            interactions: [Interaction(date: days(-1), method: .phone)])
    let normal = Contact(name: "一般", importance: .normal,
                         interactions: [Interaction(date: days(-1), method: .phone)])
    let ordinary = Contact(name: "普通", importance: .ordinary,
                           interactions: [Interaction(date: days(-1), method: .phone)])
    expectEqual(important.effectiveCadenceDays, 30, "重要默认 30 天")
    expectEqual(normal.effectiveCadenceDays, 90, "一般默认 90 天")
    expectEqual(ordinary.effectiveCadenceDays, 180, "普通默认 180 天")

    // 自定义频率覆盖默认
    let custom = Contact(name: "自定义", importance: .ordinary, cadenceDays: 21,
                         interactions: [Interaction(date: days(-1), method: .phone)])
    expectEqual(custom.effectiveCadenceDays, 21, "自定义 21 天覆盖默认")

    // 逾期边界：90 天频率，91 天前联系 → 逾期 1 天；89 天前联系 → 未到期
    let overdue = Contact(name: "逾期", importance: .normal,
                          interactions: [Interaction(date: days(-91), method: .phone)])
    expect(overdue.isDue == true, "逾期应待联系")
    expect(overdue.dueLabel != nil, "逾期应有文案")

    let upcoming = Contact(name: "未到期", importance: .normal,
                           interactions: [Interaction(date: days(-89), method: .phone)])
    expect(upcoming.isDue == false, "未逾期不应待联系")
    expect(upcoming.dueLabel == nil, "未到期无逾期文案")

    // 上次联系时间取最新一条
    let multi = Contact(name: "多条", importance: .normal,
                        interactions: [Interaction(date: days(-300), method: .phone),
                                       Interaction(date: days(-10), method: .email)])
    expectEqual(multi.lastContactDate, multi.interactions.map(\.date).max(), "上次联系取最新")
    expect(multi.isDue == false, "近期联系过不应待联系")
}

testSeedData()
testStore()
testListOrder()
testStoreContactsInSection()
testCountsUpdateAfterMutations()
testUpdateContact()
testDeleteInteractionRecalculatesDue()
testCSVParsing_basic()
testCSVParsing_noHeaderAndCustomDays()
testCSVParsing_escapedQuoteAndEmptyCadence()
testCSVParsing_invalidImportanceDefaultsNormal()
testDueDerivation()

print("")
print("通过 \(passed) / \(passed + failed)")
if failed > 0 {
    print("失败 \(failed) 项")
    exit(1)
}
