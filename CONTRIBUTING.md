# 贡献指南

感谢你对 AlloyPlayer 项目的关注！本文档提供了贡献的准则和说明。

## 行为准则

在所有交流中保持尊重、建设性和包容性。

## 如何贡献

### 报告 Bug

1. 先搜索[已有 issue](../../issues)，避免重复。
2. 使用 [Bug 报告模板](.github/ISSUE_TEMPLATE/bug_report.md) 提交新 issue。
3. 包含复现步骤、预期行为和环境信息。

### 功能建议

1. 先搜索[已有 issue](../../issues)，确认是否已有相同提案。
2. 使用[功能建议模板](.github/ISSUE_TEMPLATE/feature_request.md) 提交新 issue。
3. 说明使用场景以及该功能如何使其他用户受益。

### 提交 Pull Request

1. **Fork** 仓库并从 `main` 创建功能分支：
   ```bash
   git checkout -b feature/your-feature main
   ```

2. **遵循代码规范**，详见 [AGENTS.md](AGENTS.md)：
   - 文件头包含版权信息块
   - 注释使用简体中文
   - 对每个修改的 `.swift` 文件执行 `swiftformat <file>`（禁止目录级格式化）
   - UIKit 代码使用 `#if canImport(UIKit)` 包裹

3. **为新功能编写测试**：
   - 纯逻辑使用单元测试
   - 遵循 TDD：先写测试、验证失败、实现功能、验证通过

4. **运行测试套件**，确保所有测试通过：
   ```bash
   swift test
   ```

5. **提交** commit，使用简体中文编写清晰的提交信息：
   ```
   添加新功能的简要描述

   Signed-off-by: Your Name <your@email.com>
   ```

6. **推送**到你的 fork 并向 `main` 发起 Pull Request。

## Pull Request 准则

- **每个 PR 只包含一个逻辑变更** — 避免捆绑不相关的修改。
- **保持 PR 聚焦且精小** — 更容易审查，减少冲突。
- **更新 CHANGELOG.md** — 如适用，在 `[Unreleased]` 部分添加记录。
- **确保 CI 通过** — 合并前所有测试必须通过。

## 开发环境搭建

```bash
git clone https://github.com/nicklasundell/AlloyPlayer.git
cd AlloyPlayer
swift build
swift test
```

### 环境要求

- macOS 13.0+（开发主机）
- Xcode 16.0+
- Swift 6.0+

## 模块结构

AlloyPlayer 分为四个 SPM target：

| 模块 | 描述 |
|------|------|
| `AlloyCore` | 协议、枚举和 `Player` 控制器 |
| `AlloyAVPlayer` | 基于 AVFoundation 的 `PlaybackEngine` |
| `AlloyControlView` | 默认 `ControlOverlay` UI 组件 |
| `AlloyPlayer` | 重新导出以上所有模块的 umbrella 模块 |

添加代码时，请放入对应的模块。如不确定，请先提 issue 讨论。

## 许可证

参与贡献即表示你同意你的贡献将以 [MIT 许可证](LICENSE) 授权。
