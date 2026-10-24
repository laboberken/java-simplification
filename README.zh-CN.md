# java-simplification

一个专为 Java 设计的 OpenCode 代码简化技能。它审查最近修改的 Java
代码，从三个维度改进——清晰度、包内结构、性能——同时保持可观察行为不变。

灵感来自 [Claude Code 的 `code-simplifier`](https://github.com/anthropics/claude-code/blob/main/plugins/pr-review-toolkit/agents/code-simplifier.md)
和 [Addy Osmani 的 `code-simplification`](https://github.com/addyosmani/agent-skills/tree/main/skills/code-simplification)，
针对 Java 17+ 改编，并增加了并行只读探索子 Agent。

## 为什么还要一个简化技能？

大多数“简化这段代码”的提示词要么改变了行为，要么把代码压缩成难以阅读的单行，
要么顺手重构了无关文件。这个技能把流程约束得更严格：

- **行为优先**——现有测试必须无需修改即可通过。
- **三个维度、三个探索者**——简化、架构、性能由只读子 Agent 并行分析，
  再按安全顺序应用。
- **默认限定范围**——默认处理 `git diff HEAD`，除非你明确指定模块、特性
  或 git 修订范围。
- **懂 Java**——了解 Java 17/21 特性边界、Spring 和 Lombok。
- **诚实验证**——本地跑模块级测试，全量回归交给 CI。

## 安装

克隆本仓库，并作为全局技能安装：

```bash
git clone https://github.com/<your-name>/java-simplification.git
cd java-simplification
```

把技能和命令复制到 OpenCode 全局配置：

```bash
# 技能（OpenCode 会自动发现）
mkdir -p ~/.agents/skills/java-simplify
cp SKILL.md ~/.agents/skills/java-simplify/SKILL.md

# 自定义命令（让 /java-simplify 支持参数）
mkdir -p ~/.config/opencode/commands
cp commands/java-simplify.md ~/.config/opencode/commands/java-simplify.md
```

Windows PowerShell：

```powershell
New-Item -ItemType Directory -Force "$env:USERPROFILE\.agents\skills\java-simplify"
Copy-Item SKILL.md "$env:USERPROFILE\.agents\skills\java-simplify\SKILL.md"

New-Item -ItemType Directory -Force "$env:USERPROFILE\.config\opencode\commands"
Copy-Item commands\java-simplify.md "$env:USERPROFILE\.config\opencode\commands\java-simplify.md"
```

重启 OpenCode，或在 TUI 里执行 `/reload`。

## 使用

```bash
/java-simplify                              # 三个维度全跑，范围 git diff HEAD
/java-simplify --simplify                   # 只做简化
/java-simplify --arch --perf                # 架构 + 性能
/java-simplify 只看 order-service 模块
/java-simplify 登录功能的待提交改动
/java-simplify 优化 HEAD~3..HEAD
```

### 工作方式

1. 命令解析模式参数和自然语言范围。
2. 主 Agent 确定范围（默认 `git diff HEAD`）。
3. 三个**只读**探索子 Agent 并行运行：
   - `simplify-explorer`
   - `arch-explorer`
   - `perf-explorer`
4. 合并 findings，去重，按风险排序。
5. 按 `simplify -> arch -> perf` 顺序自动应用修改。
6. 运行模块级测试；全量回归留给 CI。
7. 只报告重大变更。

### 模式

| 参数 | 范围 | 保证 |
|------|------|------|
| `--simplify` | 方法/类内 | 保持行为；Java 17/21 模式 |
| `--arch` | **包内** | 不跨包、不跨模块移动 |
| `--perf` | 性能审查 | 清单 + 可选 JMH 证据 |
| `--all`（默认） | 三者 | 按 simplify -> arch -> perf 顺序应用 |

## 范围解析

| 输入 | 解析结果 |
|------|---------|
| 无参数 | `git diff HEAD` |
| `只看 order-service 模块` | 匹配的 Maven 模块 |
| `登录功能` | 该功能相关的改动文件 |
| `HEAD~3..HEAD` | `git diff HEAD~3..HEAD` |

如果无法解析，技能会回退到 `git diff HEAD`，并明确说明。

## 验证

```bash
# 多模块 Maven 项目
./mvnw -pl <module> -am test -DskipITs

# 单模块
mvn test -DskipITs
```

或使用辅助脚本：

```bash
scripts/verify-maven.sh order-service
```

```powershell
scripts\verify-maven.ps1 order-service
```

全量回归交给 CI。本地验证尽量窄，简化才能持续做下去。

## 安全阀

遇到以下情况，技能会停止并报告，而不是强行修改：

- 需要修改测试才能通过。
- 要删除错误处理或 null 检查。
- 要跨包或跨模块移动类。
- 性能改动缺少基准证据且可能改变行为。
- 探索子 Agent 对同一段代码意见冲突。
- 改动会触及范围外的文件。

## 仓库结构

```text
.
├── SKILL.md                  # 技能定义（name: java-simplify）
├── commands/
│   └── java-simplify.md      # OpenCode 自定义命令
├── examples/
│   ├── simplify/             # 保持行为的简化模式
│   ├── arch/                 # 包内重构
│   └── perf/                 # 性能反模式
├── scripts/
│   ├── verify-maven.sh
│   └── verify-maven.ps1
├── .github/workflows/
│   └── validate.yml
├── LICENSE
└── README.zh-CN.md
```

## Java 版本支持

- 基线：**Java 17**
- Java 21 特性（虚拟线程、有序集合、switch 模式匹配）仅在项目目标为 21+ 时建议。
- 不处理 Kotlin、Groovy、Scala。

## 许可证

MIT。见 [LICENSE](LICENSE)。
