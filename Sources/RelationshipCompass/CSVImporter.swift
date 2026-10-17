import Foundation

/// CSV 导入：固定模板 8 列（姓名,公司,职位,电话,邮箱,备注,重要度,联系频率）
enum CSVImporter {
    struct ParsedResult {
        var contacts: [Contact] = []
        var skippedRows = 0
    }

    static func parse(_ text: String) -> ParsedResult {
        var result = ParsedResult()
        var rows = text.replacingOccurrences(of: "\r\n", with: "\n")
            .replacingOccurrences(of: "\r", with: "\n")
            .split(separator: "\n", omittingEmptySubsequences: false)
            .map(String.init)

        // 表头行跳过：首行首列恰为"姓名"
        if let first = rows.first, parseFields(first).first?.trimmingCharacters(in: .whitespaces) == "姓名" {
            rows.removeFirst()
        }

        for row in rows where !row.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            var fields = parseFields(row)
            guard let name = fields.first,
                  !name.trimmingCharacters(in: .whitespaces).isEmpty else {
                result.skippedRows += 1
                continue
            }
            while fields.count < 8 { fields.append("") }

            result.contacts.append(Contact(
                name: name,
                company: fields[1],
                position: fields[2],
                phone: fields[3],
                email: fields[4],
                notes: fields[5],
                importance: ImportanceLevel(rawValue: fields[6]) ?? .normal,
                cadenceDays: cadenceDays(from: fields[7])
            ))
        }
        return result
    }

    /// 频率映射：每周/每月/每季/每半年，留空 → nil（按重要度默认），数字 → 自定义天数
    static func cadenceDays(from raw: String) -> Int? {
        let value = raw.trimmingCharacters(in: .whitespaces)
        if value.isEmpty { return nil }
        switch value {
        case "每周": return 7
        case "每月": return 30
        case "每季": return 90
        case "每半年": return 180
        default: return Int(value)
        }
    }

    /// 解析一行 CSV，支持引号包裹与双引号转义（""）
    private static func parseFields(_ line: String) -> [String] {
        var fields: [String] = []
        var current = ""
        var inQuotes = false
        let chars = Array(line)
        var i = 0
        while i < chars.count {
            let ch = chars[i]
            if inQuotes {
                if ch == "\"" {
                    if i + 1 < chars.count && chars[i + 1] == "\"" {
                        current.append("\"")
                        i += 2
                        continue
                    }
                    inQuotes = false
                    i += 1
                } else {
                    current.append(ch)
                    i += 1
                }
            } else {
                if ch == "\"" {
                    inQuotes = true
                    i += 1
                } else if ch == "," {
                    fields.append(current)
                    current = ""
                    i += 1
                } else {
                    current.append(ch)
                    i += 1
                }
            }
        }
        fields.append(current)
        return fields.map { $0.trimmingCharacters(in: .whitespaces) }
    }
}
