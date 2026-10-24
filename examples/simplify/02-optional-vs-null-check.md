# Optional vs verbose null checks

**Dimension:** simplify
**Java baseline:** 8+
**Risk:** medium

## Before

```java
String name = "";
if (user != null && user.getProfile() != null) {
    name = user.getProfile().getName();
}
if (name.isEmpty()) {
    name = "Unknown";
}
```

## After

```java
String name = Optional.ofNullable(user)
    .map(User::getProfile)
    .map(Profile::getName)
    .orElse("Unknown");
```

## Why

The `Optional` chain makes the "possibly absent" path explicit and removes the
temporary variable plus the second `isEmpty` check.

## When not to apply

- The original treats `null` and `""` differently. The rewrite above collapses
  both into `"Unknown"`; if that changes behavior, keep the explicit checks.
- The project style forbids `Optional` in certain layers (some teams ban it in
  entities and DTO fields).
- The null checks have side effects (logging, metrics, lazy initialization).

## Verification

Add or keep a test for the empty-string case before applying. The rewrite is
only behavior-preserving when `null` and empty are equivalent for this value.
