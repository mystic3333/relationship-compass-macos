# 使用 Swift Package + 命令行构建 macOS 应用，而非 Xcode 工程

开发机未安装 Xcode（仅有 Command Line Tools，Swift 6.3.2）。因此采用 Swift Package 可执行目标构建 SwiftUI 应用，通过 `swift build` / `swift run` 运行，不生成 .xcodeproj。SwiftUI 在 CLT 自带 SDK 中可正常编译运行。

**修正（原假设有误）**：SwiftData 的 `@Model` 宏依赖 SDK 提供的 SwiftDataMacros 编译插件，而该插件目录（`usr/lib/swift/host/plugins`）未随 Command Line Tools 提供，宏无法编译。因此存储层弃用 SwiftData，改用 Codable + JSON（见 ADR-0004）。

转换回正式 Xcode 工程（打包、签名、上架）是后期可做的事，但当前阶段不为此阻塞开发。
