# 存储采用 Codable + JSON 文件，而非 SwiftData

原计划使用 SwiftData 持久化，但开发机仅有 Command Line Tools（无 Xcode），SDK 未提供 SwiftDataMacros 编译插件，`@Model` 宏无法编译（ADR-0001 的原始假设错误，已修正）。

弃用的替代方案：安装 Xcode（下载体积大，用户明确不想要）；程序化 Core Data（需手写 NSManagedObjectModel 与映射，复杂度与个人工具不匹配）。因此改为：

- `Contact` / `Interaction` 为 `Codable` 结构体，保存在内存数组中
- `ContactStore`（`ObservableObject`，`@Published contacts`）负责加载/保存 Application Support 下的 `contacts.json`，并提供全部增删改操作
- 领域推导逻辑（上次联系时间、待联系、排序）保持不变，只依赖联系人结构体的计算属性，无存储依赖
- 测试 seam 简化为内存数组 + 临时文件，无需数据库上下文

个人规模（≤1000 联系人）下 JSON 完全够用；日后引入 Xcode 工程时可平滑迁移到 Core Data / SwiftData。
