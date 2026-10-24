---
name: java-simplify
description: >
  Simplify and optimize recently modified Java code while preserving behavior.
  Use after implementing a Java feature, fixing a bug, or completing a refactor.
  Defaults to the current uncommitted diff (`git diff HEAD`); supports natural-language
  scope such as "only the order-service module", "the login feature", or "HEAD~3..HEAD".
  Runs three parallel read-only explorers (simplify, architecture, performance), then
  applies changes automatically in simplify -> architecture -> performance order.
  Triggered manually via `/java-simplify`; never auto-invoked.
license: MIT
compatibility: opencode
metadata:
  audience: java-developers
  workflow: coding
  language: java
  java-baseline: "17"
  opencode/slash: "false"
  opencode/autoinvoke: "false"
---

# Java Simplify

> Inspired by Claude Code's `code-simplifier` agent and Addy Osmani's
> `code-simplification` skill. Adapted for Java 17+ (with Java 21 notes) and
> extended with an in-package architecture pass and a performance review pass.

## Overview

Improve recently modified Java code along three dimensions — clarity, in-package
structure, and performance — without changing observable behavior unless a
performance change is explicitly justified and verified.

The goal is not fewer lines. The goal is code that a new team member can read, a
reviewer can trust, and a future maintainer can change safely.

## When to Use

- After implementing a Java feature, fixing a bug, or completing a refactor.
- During code review when readability, duplication, or complexity is flagged.
- When you want a focused pass over the current uncommitted diff.
- When you explicitly name a module, feature, or git range to optimize.

**When NOT to use:**

- The code is already clean — don't simplify for the sake of it.
- You don't understand the code yet — comprehend before you simplify.
- The code is performance-critical and the "simpler" version would be measurably slower.
- The module is about to be rewritten — simplifying throwaway code wastes effort.
- The target is not Java (`.kt`, `.groovy`, `.scala`) — this skill is Java-only.

## Five Principles

### 1. Preserve Behavior Exactly

Never change what the code does — only how it expresses it. Inputs, outputs,
side effects, exception types, null handling, and edge cases must remain
identical. If you are not sure a change preserves behavior, don't make it.

Before every change, answer:

- Does this produce the same output for every input?
- Does this keep the same exception behavior and error messages?
- Does this preserve null handling and side effects?
- Do all existing tests pass without modification?

### 2. Follow Java Project Standards

Read the project's conventions before touching code:

- `AGENTS.md`, `CLAUDE.md`, `CONTRIBUTING.md`
- Checkstyle / Spotless / PMD configuration
- `pom.xml` or `build.gradle` for Java version and compiler settings

Match the project's existing style for:

- Import order and wildcard imports
- Naming: `PascalCase` classes, `camelCase` methods and fields, `UPPER_SNAKE_CASE` constants
- Exception handling: checked vs unchecked, no swallowed exceptions
- Null handling: `Optional`, `@Nullable` / `@NonNull`, or explicit guards
- Logging: framework and parameterized messages (`log.info("x={}", x)`)
- Lombok usage boundaries
- Visibility: prefer the narrowest access modifier

Simplification that breaks project consistency is churn, not simplification.

### 3. Prefer Clarity Over Cleverness

Explicit code is better than compact code when the compact version requires a
mental pause to parse. A one-line nested ternary is not simpler than a readable
`if`/`else` chain.

### 4. Maintain Balance

Avoid over-simplification that:

- Reduces clarity or maintainability
- Creates overly clever solutions that are hard to debug
- Combines unrelated concerns into one method or class
- Removes helpful abstractions that improve organization
- Prioritizes fewer lines over readability (nested ternaries, dense one-liners)
- Makes the code harder to extend

### 5. Stay in Scope

Default to the code in the resolved scope (normally `git diff HEAD`). Do not
perform drive-by refactors of unrelated code. Unscoped simplification creates
noisy diffs and risks regressions you did not intend to introduce.

## Java Project Standards

Use this checklist when the project does not document its conventions:

- Prefer constructor injection over field injection.
- Keep methods short and single-purpose; extract when a block has a clear name.
- Use guard clauses to flatten nesting instead of deep `if` pyramids.
- Do not swallow exceptions or catch `Exception` without a concrete reason.
- Prefer `Optional` for return values that may be absent; do not use it for fields
  or method parameters without a project convention.
- Use parameterized logging (`log.info("id={}", id)`), never string concatenation.
- Prefer `StringBuilder` or `String.join` over `+=` in loops.
- Size collections when the expected size is known.
- Prefer interfaces for variable declarations (`List<String>`, `Map<K, V>`).
- Remove dead code, unused imports, redundant casts, and comments that restate code.
- Keep comments that explain *why*, delete comments that explain *what*.

## Scope Resolution

Default scope: `git diff HEAD` (staged + unstaged changes — the current
uncommitted work).

Resolve natural-language scope before dispatching explorers:

1. Run `git status --short` and `git diff HEAD --stat`.
2. If the user names a module, map it to a Maven module path or `artifactId`
   using the root `pom.xml` `<modules>` list.
3. If the user names a feature, map it to the files changed for that feature.
4. If the user names a git range (e.g. `HEAD~3..HEAD`), use `git diff <range>`.
5. If the scope cannot be resolved, fall back to `git diff HEAD` and say so.

Never expand scope silently. If the user asks for "the whole project", confirm
that the scope is larger than the default before proceeding.

## Three Modes

Modes are flags passed to `/java-simplify`. Default is `--all` (all three).
Flags may be combined. Without flags, run all three in order.

### `--simplify`

Behavior-preserving clarity improvements:

- Replace traditional loops with Streams only when it improves readability.
- Replace verbose null checks with `Optional` only when it clarifies intent.
- Use `switch` expressions (Java 14+) for multi-branch assignment.
- Use `record` (Java 16+) for immutable data carriers.
- Use `var` (Java 10+) only when the type is obvious from the right-hand side.
- Apply guard clauses to flatten nesting.
- Use `try-with-resources` for `AutoCloseable`.
- Remove dead code, redundant casts, and comments that restate the code.
- Keep comments that explain *why*.

### `--arch` (in-package only)

Structural improvements **within a package**:

- Extract a method when a block has a clear responsibility.
- Extract a class when a class has multiple unrelated responsibilities.
- Remove duplication by introducing a private helper in the same package.
- Reduce coupling between classes in the same package.
- Do **not** move classes across packages or modules.
- Do **not** change public APIs of packages.

### `--perf`

Performance review with evidence:

- Flag obvious anti-patterns: string concatenation in loops, N+1 queries,
  unnecessary boxing, repeated collection resizing, logging in hot loops.
- Prefer `StringBuilder` / `String.join` in loops.
- Size collections when the expected size is known.
- Avoid Stream overhead in tight numeric loops when a plain loop is clearer and faster.
- If a change could alter behavior or has unclear impact, require a benchmark
  (JMH or equivalent) or leave it as a recommendation.
- Never trade readability for unmeasured micro-optimization.

## Java 17/21 Feature Matrix

| Feature | Minimum version | Notes |
|---------|-----------------|-------|
| `var` | 10 | Use only when the type is obvious |
| `switch` expressions | 14 | Arrow syntax, no fall-through |
| `record` | 16 | Immutable data carriers |
| Pattern matching for `instanceof` | 16 | Avoid casts after `instanceof` |
| Sealed classes | 17 | Use when the hierarchy is closed |
| Virtual threads | 21 | Do not introduce unless the project targets 21+ |
| Sequenced collections | 21 | `getFirst()` / `getLast()` |
| Pattern matching for `switch` | 21 | Use only on 21+ |

If the project targets Java 17, do not suggest 21-only features. If it targets
Java 21, the 17 features are also available.

## Simplification Patterns

### Stream vs loop

```java
// BEFORE
List<String> activeNames = new ArrayList<>();
for (User user : users) {
    if (user.isActive()) {
        activeNames.add(user.getName());
    }
}

// AFTER
List<String> activeNames = users.stream()
    .filter(User::isActive)
    .map(User::getName)
    .toList();
```

Use the Stream form only when it is clearly more readable. A plain loop is fine
when it involves complex control flow, checked exceptions, or debugging.

### Optional vs null checks

```java
// BEFORE
String name = "";
if (user != null && user.getProfile() != null) {
    name = user.getProfile().getName();
}
if (name.isEmpty()) {
    name = "Unknown";
}

// AFTER
String name = Optional.ofNullable(user)
    .map(User::getProfile)
    .map(Profile::getName)
    .orElse("Unknown");
```

### Switch expression (Java 14+)

```java
// BEFORE
String status;
switch (code) {
    case 200: status = "OK"; break;
    case 404: status = "Not Found"; break;
    default: status = "Unknown"; break;
}

// AFTER
String status = switch (code) {
    case 200 -> "OK";
    case 404 -> "Not Found";
    default -> "Unknown";
};
```

### Record (Java 16+)

```java
// BEFORE
public class UserDto {
    private final String id;
    private final String name;

    public UserDto(String id, String name) {
        this.id = id;
        this.name = name;
    }

    public String getId() { return id; }
    public String getName() { return name; }
    // equals, hashCode, toString omitted
}

// AFTER
public record UserDto(String id, String name) {}
```

### Guard clauses

```java
// BEFORE
public void process(Order order) {
    if (order != null) {
        if (order.isValid()) {
            if (order.getCustomer() != null) {
                if (order.getCustomer().isActive()) {
                    doWork(order);
                }
            }
        }
    }
}

// AFTER
public void process(Order order) {
    if (order == null || !order.isValid()) return;
    if (order.getCustomer() == null || !order.getCustomer().isActive()) return;
    doWork(order);
}
```

### try-with-resources

```java
// BEFORE
BufferedReader reader = new BufferedReader(new FileReader("file.txt"));
try {
    String line = reader.readLine();
    // ...
} finally {
    reader.close();
}

// AFTER
try (BufferedReader reader = new BufferedReader(new FileReader("file.txt"))) {
    String line = reader.readLine();
    // ...
}
```

## Architecture Patterns (in-package)

### Extract method

When a block has a clear responsibility, extract it into a private method with a
name that explains *why* it exists. Keep the extracted method in the same class.

### Extract class

When a class holds two unrelated responsibilities, extract one into a new class
in the **same package**. Do not move existing classes to other packages.

### Remove duplication

When the same 5+ lines appear in multiple places in the same package, introduce
a package-private helper and call it from both places. Do not create a utility
class in another package.

## Performance Checklist

- [ ] String concatenation inside loops
- [ ] N+1 database queries
- [ ] Unnecessary boxing/unboxing in hot paths
- [ ] Collection without initial capacity when the size is known
- [ ] Logging with string concatenation instead of parameterized messages
- [ ] Repeated `stream()` creation in a loop
- [ ] `Optional` used in hot paths where a nullable reference is cheaper
- [ ] Synchronization on a hot path without contention evidence

## Spring Appendix

Only apply these when the project already uses Spring / Lombok.

### Lombok

- Prefer `@RequiredArgsConstructor` over `@Autowired` field injection.
- Do not use `@Data` on JPA entities with relationships.
- Use `@Value` only for immutable DTOs.
- Remove boilerplate only when Lombok is already a project dependency.

### Spring annotations

- Keep `@Transactional` on public methods of Spring beans.
- Do not move `@Configuration` classes across packages.
- Prefer constructor injection over field injection.
- Keep `@Service` / `@Repository` / `@Controller` responsibilities aligned with
  their stereotype.

## Subagent Orchestration

When the skill is invoked:

1. Resolve scope (see **Scope Resolution**).
2. Dispatch three **read-only** `explore` subagents in parallel:
   - `simplify-explorer`: clarity opportunities.
   - `arch-explorer`: in-package structural opportunities.
   - `perf-explorer`: performance issues.
3. Each explorer receives:
   - The resolved scope (files, diff, or module).
   - The Java version baseline.
   - The project standards summary.
   - The instruction: **do not modify files; return findings only.**
4. Each explorer returns a table:

   | File | Lines | Dimension | Problem | Suggested change | Risk |
   |------|-------|-----------|---------|------------------|------|

5. Merge findings, remove duplicates, and sort by risk (low -> high).
6. Apply changes automatically in `simplify -> arch -> perf` order.
7. Verify with module-level tests.
8. Report significant changes only.

### Explorer prompt template

```text
You are a read-only Java code explorer. Do not modify any files.

Scope: <resolved scope>
Java baseline: <17 or 21>
Project standards: <summary>

Find <simplify|architecture|performance> opportunities in the scope.
For each finding, return:
- file path
- line range
- problem
- suggested change (before/after snippet if useful)
- risk (low/medium/high)

Return only the findings table. Do not edit files. Skip non-Java files.
```

## Execution & Verification

Apply changes one dimension at a time:

1. `simplify` — behavior-preserving.
2. `arch` — in-package structural.
3. `perf` — evidence-based.

After each dimension, run the narrowest useful verification:

```bash
# Multi-module Maven project (preferred)
./mvnw -pl <module> -am test -DskipITs

# Single-module or no wrapper
mvn test -DskipITs
```

Use `scripts/verify-maven.sh` or `scripts/verify-maven.ps1` for a reusable
wrapper. Full regression belongs in CI, not in every local simplification step.

If tests fail, revert the last change and reconsider. Do not "fix" tests to make
a refactor pass.

## Red Flags & Safety Valves

Stop and report instead of applying a change when:

- Tests would need modification to pass.
- Error handling or null checks would be removed.
- A class would move across packages or modules.
- A performance change has no benchmark evidence and may alter behavior.
- Explorers disagree about the same code.
- The change would touch unrelated files outside the resolved scope.

## Report Format

Report only significant changes:

```text
## Scope
- <resolved scope>

## Changed
- <file>: <what changed and why>

## Verification
- <command> -> <result>

## Remaining risks
- <items not changed, with reason>
```

Do not dump every line-level diff. The user can review the diff separately.

## Out of Scope

- Kotlin, Groovy, Scala, or other JVM languages.
- Cross-package or cross-module moves.
- Behavior-changing performance rewrites without benchmarks.
- Framework migrations (Spring Boot 2 -> 3, JUnit 4 -> 5, etc.).
- Code style enforcement that the project's formatter already handles.
