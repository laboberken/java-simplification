# java-simplification

A Java-specific code simplification skill for OpenCode. It reviews recently
modified Java code and improves it along three dimensions — clarity, in-package
structure, and performance — while preserving observable behavior.

Inspired by [Claude Code's `code-simplifier`](https://github.com/anthropics/claude-code/blob/main/plugins/pr-review-toolkit/agents/code-simplifier.md)
and [Addy Osmani's `code-simplification`](https://github.com/addyosmani/agent-skills/tree/main/skills/code-simplification),
adapted for Java 17+ and extended with parallel read-only explorers.

## Why another simplification skill?

Most "simplify this code" prompts either change behavior, over-compress code
into unreadable one-liners, or refactor unrelated files. This skill encodes a
stricter process:

- **Behavior first** — existing tests must pass without modification.
- **Three dimensions, three explorers** — simplify, architecture, and
  performance are analyzed in parallel by read-only subagents, then applied in
  a safe order.
- **Scoped by default** — operates on `git diff HEAD` unless you name a module,
  feature, or git range explicitly.
- **Java-aware** — knows Java 17/21 feature boundaries, Spring, and Lombok.
- **Honest verification** — module-level tests locally, full regression in CI.

## Installation

Clone this repository and install it as a global skill:

```bash
git clone https://github.com/<your-name>/java-simplification.git
cd java-simplification
```

Copy the skill and command into your OpenCode global config:

```bash
# Skill (auto-discovered by OpenCode)
mkdir -p ~/.agents/skills/java-simplify
cp SKILL.md ~/.agents/skills/java-simplify/SKILL.md

# Custom command (enables /java-simplify with arguments)
mkdir -p ~/.config/opencode/commands
cp commands/java-simplify.md ~/.config/opencode/commands/java-simplify.md
```

Windows PowerShell:

```powershell
New-Item -ItemType Directory -Force "$env:USERPROFILE\.agents\skills\java-simplify"
Copy-Item SKILL.md "$env:USERPROFILE\.agents\skills\java-simplify\SKILL.md"

New-Item -ItemType Directory -Force "$env:USERPROFILE\.config\opencode\commands"
Copy-Item commands\java-simplify.md "$env:USERPROFILE\.config\opencode\commands\java-simplify.md"
```

Restart OpenCode, or run `/reload` in the TUI.

## Usage

```bash
/java-simplify                              # all three dimensions, git diff HEAD
/java-simplify --simplify                   # clarity only
/java-simplify --arch --perf                # architecture + performance
/java-simplify only the order-service module
/java-simplify the login feature's uncommitted changes
/java-simplify optimize HEAD~3..HEAD
```

### How it works

1. The command parses mode flags and natural-language scope.
2. The main agent resolves the scope (`git diff HEAD` by default).
3. Three **read-only** explorers run in parallel:
   - `simplify-explorer`
   - `arch-explorer`
   - `perf-explorer`
4. Findings are merged, de-duplicated, and sorted by risk.
5. Changes are applied automatically in `simplify -> arch -> perf` order.
6. Module-level tests run; full regression is left to CI.
7. Only significant changes are reported.

### Modes

| Flag | Scope | Guarantees |
|------|-------|------------|
| `--simplify` | Method/class level | Behavior preserved; Java 17/21 patterns |
| `--arch` | **Within a package** | No cross-package or cross-module moves |
| `--perf` | Performance review | Checklist + optional JMH evidence |
| `--all` (default) | All three | Applied in simplify -> arch -> perf order |

## Scope resolution

| Input | Resolved scope |
|-------|----------------|
| no argument | `git diff HEAD` |
| `only the order-service module` | the matching Maven module |
| `the login feature` | files changed for that feature |
| `HEAD~3..HEAD` | `git diff HEAD~3..HEAD` |

If the scope cannot be resolved, the skill falls back to `git diff HEAD` and
says so.

## Verification

```bash
# Multi-module Maven project
./mvnw -pl <module> -am test -DskipITs

# Single module
mvn test -DskipITs
```

Or use the helper scripts:

```bash
scripts/verify-maven.sh order-service
```

```powershell
scripts\verify-maven.ps1 order-service
```

Full regression belongs in CI. Local runs should stay narrow so simplification
stays cheap.

## Safety valves

The skill stops and reports instead of applying a change when:

- Tests would need modification to pass.
- Error handling or null checks would be removed.
- A class would move across packages or modules.
- A performance change lacks benchmark evidence and may alter behavior.
- Explorers disagree about the same code.
- The change would touch files outside the resolved scope.

## Repository layout

```text
.
├── SKILL.md                  # skill definition (name: java-simplify)
├── commands/
│   └── java-simplify.md      # OpenCode custom command
├── examples/
│   ├── simplify/             # behavior-preserving patterns
│   ├── arch/                 # in-package refactors
│   └── perf/                 # performance anti-patterns
├── scripts/
│   ├── verify-maven.sh
│   └── verify-maven.ps1
├── .github/workflows/
│   └── validate.yml
├── LICENSE
└── README.md
```

## Java version support

- Baseline: **Java 17**
- Java 21 features (virtual threads, sequenced collections, switch pattern
  matching) are only suggested when the project targets 21+.
- The skill does not handle Kotlin, Groovy, or Scala.

## License

MIT. See [LICENSE](LICENSE).
