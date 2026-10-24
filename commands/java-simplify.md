---
description: Simplify and optimize Java code (default scope: git diff HEAD)
agent: build
---

Use the `java-simplify` skill to analyze and improve Java code.

Arguments: $ARGUMENTS

Rules:

- Parse mode flags from the arguments: `--simplify`, `--arch`, `--perf`, `--all`.
- Default mode is `--all` when no flag is present. Flags may be combined.
- Treat the remaining natural-language text as the scope.
- Default scope is `git diff HEAD` (staged + unstaged uncommitted changes).
- Resolve natural-language scope (module, feature, or git range) before dispatching explorers.
- Launch three read-only explorers in parallel: simplify, architecture, performance.
- Merge findings and apply changes automatically in simplify -> arch -> perf order.
- Verify with module-level Maven tests; full regression belongs in CI.
- Stop and report on any red flag instead of applying a risky change.
- If the target is not Java, stop and say it is out of scope.
- Report only significant changes, not a full line-by-line diff.
