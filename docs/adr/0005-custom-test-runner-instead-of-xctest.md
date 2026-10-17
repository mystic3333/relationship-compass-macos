# 测试使用自建断言 runner，而非 XCTest

Command Line Tools SDK 不包含 XCTest（`System/Library/Frameworks/XCTest.framework` 仅随 Xcode 提供），`swift test` 无法工作。为保证 TDD 流程在纯 CLT 环境下可用，改为：

- 新增可执行目标 `RelationshipCompassTests`（`swift run RelationshipCompassTests`），内置极简断言（`expect` / `expectEqual`），失败时非零退出
- 主目标以 `-enable-testing` 编译，测试目标 `@testable import RelationshipCompass`
- 被测内容不变：种子数据、持久化、待联系推导、CSV 解析

日后引入 Xcode 后可平滑迁移回 XCTest / Swift Testing。
