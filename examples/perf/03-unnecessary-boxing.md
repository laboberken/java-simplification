# Unnecessary boxing in hot paths

**Dimension:** perf
**Java baseline:** 8+
**Risk:** medium

## Before

```java
Long total = 0L;
for (long value : values) {
    total += value;
}
```

## After

```java
long total = 0L;
for (long value : values) {
    total += value;
}
```

## Why

Using `Long` as an accumulator forces boxing and unboxing on every iteration.
A primitive `long` keeps the loop allocation-free.

## When not to apply

- The value can legitimately be `null` (for example, a nullable database column).
- The result must be stored in a boxed type for an API boundary.
- The loop is cold and readability is higher with the boxed type.

## Evidence

This is only worth changing in a hot path. If the loop runs a handful of times
per request, the allocation cost is irrelevant. Use JMH or a profiler before
claiming a win.

## Verification

Behavior is identical for non-null inputs. If the original could produce `null`,
keep the boxed type or handle the null case explicitly.
