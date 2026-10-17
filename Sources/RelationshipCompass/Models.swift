import Foundation

// MARK: - 重要度（3 级）

enum ImportanceLevel: String, Codable, CaseIterable, Identifiable {
    case important = "重要"
    case normal = "一般"
    case ordinary = "普通"

    var id: String { rawValue }

    /// 列表排序依据：重要 → 一般 → 普通
    var sortOrder: Int {
        switch self {
        case .important: return 0
        case .normal: return 1
        case .ordinary: return 2
        }
    }

    /// 未设频率时的默认联系间隔（天）：重要→每月，一般→每季，普通→每半年
    var defaultCadenceDays: Int {
        switch self {
        case .important: return 30
        case .normal: return 90
        case .ordinary: return 180
        }
    }

    var color: (red: Double, green: Double, blue: Double) {
        switch self {
        case .important: return (0.86, 0.18, 0.15) // 红
        case .normal: return (0.95, 0.62, 0.10)    // 橙
        case .ordinary: return (0.55, 0.55, 0.58)  // 灰
        }
    }
}

// MARK: - 互动方式

enum InteractionMethod: String, Codable, CaseIterable, Identifiable {
    case phone = "电话"
    case wechat = "微信"
    case email = "邮件"
    case meeting = "见面"
    case other = "其他"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .phone: return "phone"
        case .wechat: return "message"
        case .email: return "envelope"
        case .meeting: return "person.2"
        case .other: return "ellipsis"
        }
    }
}

// MARK: - 联系频率选项

enum CadenceOption: String, CaseIterable, Identifiable {
    case `default` = "按重要度默认"
    case weekly = "每周"
    case monthly = "每月"
    case quarterly = "每季"
    case custom = "自定义"

    var id: String { rawValue }

    var days: Int? {
        switch self {
        case .default: return nil
        case .weekly: return 7
        case .monthly: return 30
        case .quarterly: return 90
        case .custom: return nil
        }
    }

    static func option(forDays days: Int?) -> CadenceOption {
        guard let days else { return .default }
        switch days {
        case 7: return .weekly
        case 30: return .monthly
        case 90: return .quarterly
        default: return .custom
        }
    }
}

// MARK: - 互动记录

struct Interaction: Identifiable, Codable, Hashable {
    var id: UUID = UUID()
    var date: Date
    var method: InteractionMethod
    var notes: String

    init(id: UUID = UUID(), date: Date, method: InteractionMethod, notes: String = "") {
        self.id = id
        self.date = date
        self.method = method
        self.notes = notes
    }
}

// MARK: - 联系人

struct Contact: Identifiable, Codable, Hashable {
    var id: UUID = UUID()
    var name: String
    var company: String
    var position: String
    var phone: String
    var email: String
    var notes: String
    var importance: ImportanceLevel
    /// 联系间隔天数；nil 表示按重要度默认
    var cadenceDays: Int?
    var createdAt: Date
    var interactions: [Interaction]

    init(
        id: UUID = UUID(),
        name: String,
        company: String = "",
        position: String = "",
        phone: String = "",
        email: String = "",
        notes: String = "",
        importance: ImportanceLevel = .normal,
        cadenceDays: Int? = nil,
        createdAt: Date = Date.now,
        interactions: [Interaction] = []
    ) {
        self.id = id
        self.name = name
        self.company = company
        self.position = position
        self.phone = phone
        self.email = email
        self.notes = notes
        self.importance = importance
        self.cadenceDays = cadenceDays
        self.createdAt = createdAt
        self.interactions = interactions
    }

    /// 上次联系时间：由互动记录中最新的日期推导（ADR-0002），不单独存储
    var lastContactDate: Date? {
        interactions.map(\.date).max()
    }

    /// 生效的联系间隔天数
    var effectiveCadenceDays: Int {
        cadenceDays ?? importance.defaultCadenceDays
    }

    /// 本次联系的截止日期 = 上次联系 + 频率
    var dueDate: Date? {
        guard let last = lastContactDate else { return nil }
        return Calendar.current.date(byAdding: .day, value: effectiveCadenceDays, to: last)
    }

    /// 从未联系过，或超过频率期限 → 待联系
    var isDue: Bool {
        guard let due = dueDate else { return true }
        return due < Date.now
    }

    /// 逾期状态文案
    var dueLabel: String? {
        if lastContactDate == nil { return "从未联系" }
        guard let due = dueDate else { return nil }
        if due < Date.now {
            let days = Calendar.current.dateComponents([.day], from: due, to: Date.now).day ?? 0
            return "逾期 \(days) 天"
        }
        return nil
    }

    /// 列表排序：重要度优先，同级内从未联系者排前，其次按上次联系时间倒序
    static func listOrder(_ a: Contact, _ b: Contact) -> Bool {
        if a.importance.sortOrder != b.importance.sortOrder {
            return a.importance.sortOrder < b.importance.sortOrder
        }
        switch (a.lastContactDate, b.lastContactDate) {
        case (nil, nil): return a.name < b.name
        case (nil, _): return true
        case (_, nil): return false
        case let (x?, y?): return x > y
        }
    }
}

// MARK: - 侧边栏视图区

enum SidebarSection: String, CaseIterable, Identifiable, Hashable {
    case all = "全部"
    case important = "重要"
    case due = "待联系"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .all: return "person.2"
        case .important: return "star"
        case .due: return "bell"
        }
    }
}
