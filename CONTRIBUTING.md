# Contributing to AlloyPlayer

Thank you for your interest in contributing to AlloyPlayer! This document provides guidelines and instructions for contributing.

## Code of Conduct

Be respectful, constructive, and inclusive in all interactions.

## How to Contribute

### Reporting Bugs

1. Search [existing issues](../../issues) to avoid duplicates.
2. Use the [Bug Report template](.github/ISSUE_TEMPLATE/bug_report.md) to file a new issue.
3. Include reproduction steps, expected behavior, and environment details.

### Suggesting Features

1. Search [existing issues](../../issues) to check if it has been proposed.
2. Use the [Feature Request template](.github/ISSUE_TEMPLATE/feature_request.md) to file a new issue.
3. Explain the use case and how it benefits other users.

### Submitting Pull Requests

1. **Fork** the repository and create a feature branch from `main`:
   ```bash
   git checkout -b feature/your-feature main
   ```

2. **Follow the code conventions** described in [AGENTS.md](AGENTS.md):
   - File headers with copyright block
   - Comments in Simplified Chinese
   - `swiftformat <file>` on each modified `.swift` file (never directory-level)
   - UIKit code wrapped in `#if canImport(UIKit)`

3. **Write tests** for new functionality:
   - Unit tests for pure logic
   - Follow TDD: write test first, verify failure, implement, verify pass

4. **Run the test suite** and ensure all tests pass:
   ```bash
   swift test
   ```

5. **Commit** with a clear message in Simplified Chinese:
   ```
   添加新功能的简要描述

   Signed-off-by: Your Name <your@email.com>
   ```

6. **Push** to your fork and open a Pull Request against `main`.

## Pull Request Guidelines

- **One PR per logical change** — avoid bundling unrelated modifications.
- **Keep PRs focused and small** — easier to review and less likely to conflict.
- **Update CHANGELOG.md** under an `[Unreleased]` section if applicable.
- **Ensure CI passes** — all tests must be green before merge.

## Development Setup

```bash
git clone https://github.com/nicklasundell/AlloyPlayer.git
cd AlloyPlayer
swift build
swift test
```

### Requirements

- macOS 13.0+ (development host)
- Xcode 16.0+
- Swift 6.0+

## Module Structure

AlloyPlayer is split into four SPM targets:

| Module | Description |
|--------|-------------|
| `AlloyCore` | Protocols, enums, and the `Player` controller |
| `AlloyAVPlayer` | AVFoundation-based `PlaybackEngine` |
| `AlloyControlView` | Default `ControlOverlay` UI components |
| `AlloyPlayer` | Umbrella module re-exporting all above |

When adding code, place it in the appropriate module. If unsure, open an issue to discuss first.

## License

By contributing, you agree that your contributions will be licensed under the [MIT License](LICENSE).
