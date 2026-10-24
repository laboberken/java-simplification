# Stream vs traditional loop

**Dimension:** simplify
**Java baseline:** 8+
**Risk:** low

## Before

```java
List<String> activeNames = new ArrayList<>();
for (User user : users) {
    if (user.isActive()) {
        activeNames.add(user.getName());
    }
}
```

## After

```java
List<String> activeNames = users.stream()
    .filter(User::isActive)
    .map(User::getName)
    .toList();
```

## Why

The Stream form states the intent — filter, then map — instead of describing the
mechanics of iteration. It removes the mutable accumulator and the manual `add`.

## When not to apply

- The loop contains checked exceptions or complex control flow (`break`, labeled
  `continue`, early `return` with cleanup).
- You need to debug step-by-step inside the loop.
- The project targets Java 8/11 and does not allow `Stream.toList()` (Java 16+);
  use `collect(Collectors.toList())` instead.
- The collection is performance-critical and profiling shows the Stream overhead
  matters.

## Verification

Existing tests must pass without modification. Behavior is identical for the
same input list.
