# 使用 Swift Package + 命令行构建 macOS 应用，而非 Xcode 工程

开发机未安装 Xcode（仅有 Command Line Tools，Swift 6.3.2）。因此采用 Swift Package 可执行目标构建 SwiftUI 应用，通过 `swift build` / `swift run` 运行，不生成 .xcodeproj。SwiftUI 与 SwiftData 在 CLT 自带 SDK 中均可正常编译运行。

转换回正式 Xcode 工程（打包、签名、上架）是后期可做的事，但当前阶段不为此阻塞开发。
