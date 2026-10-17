import SwiftUI
import UniformTypeIdentifiers

/// CSV 导入面板：模板说明 + 文件选择 + 导入结果
struct CSVImportView: View {
    @EnvironmentObject private var store: ContactStore
    @Environment(\.dismiss) private var dismiss

    @State private var showFileImporter = false
    @State private var result: CSVImporter.ParsedResult?
    @State private var errorMessage: String?

    private let templateColumns = [
        "姓名", "公司", "职位", "电话", "邮箱", "备注", "重要度", "联系频率"
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("导入联系人（CSV）")
                .font(.headline)

            Text("请按固定模板准备 CSV 文件，每行一位联系人。模板列为：")
                .font(.callout)
                .foregroundStyle(.secondary)

            Text(templateColumns.joined(separator: " , "))
                .font(.system(.callout, design: .monospaced))
                .padding(8)
                .background(Color.secondary.opacity(0.1), in: RoundedRectangle(cornerRadius: 6))

            Text("示例行：")
                .font(.caption)
                .foregroundStyle(.secondary)
            Text("张三,某某公司,经理,13812345678,zhang@x.com,老客户,重要,每月")
                .font(.system(.caption, design: .monospaced))
                .foregroundStyle(.secondary)

            Text("重要度：重要 / 一般 / 普通（留空为一般）· 联系频率：每周 / 每月 / 每季 / 每半年 / 数字天数（留空按重要度默认）")
                .font(.caption2)
                .foregroundStyle(.secondary)

            if let errorMessage {
                Label(errorMessage, systemImage: "exclamationmark.triangle")
                    .foregroundStyle(.red)
                    .font(.callout)
            }

            if let result {
                Label("导入完成：成功 \(result.contacts.count) 条，跳过 \(result.skippedRows) 行",
                      systemImage: "checkmark.circle")
                    .foregroundStyle(.green)
                    .font(.callout)
            }

            HStack {
                Spacer()
                Button("关闭") { dismiss() }
                Button(result == nil ? "选择 CSV 文件" : "再导入一个文件") {
                    showFileImporter = true
                }
                .buttonStyle(.borderedProminent)
            }
        }
        .padding(20)
        .frame(width: 520)
        .fileImporter(
            isPresented: $showFileImporter,
            allowedContentTypes: [.commaSeparatedText, .plainText, .data]
        ) { fileResult in
            switch fileResult {
            case .success(let url):
                importFile(at: url)
            case .failure:
                errorMessage = "无法读取文件"
            }
        }
    }

    private func importFile(at url: URL) {
        do {
            let isAccessing = url.startAccessingSecurityScopedResource()
            defer { if isAccessing { url.stopAccessingSecurityScopedResource() } }
            let text = try String(contentsOf: url, encoding: .utf8)
            let parsed = CSVImporter.parse(text)
            store.importContacts(parsed.contacts)
            result = parsed
            errorMessage = nil
        } catch {
            errorMessage = "文件解析失败：\(error.localizedDescription)"
        }
    }
}
