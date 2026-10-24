# String concatenation in a loop

**Dimension:** perf
**Java baseline:** 8+
**Risk:** low

## Before

```java
String result = "";
for (String item : items) {
    result += item + ",";
}
```

## After

```java
String result = String.join(",", items);
```

Or, when the separator logic is more complex:

```java
StringBuilder sb = new StringBuilder();
for (String item : items) {
    if (sb.length() > 0) sb.append(',');
    sb.append(item);
}
String result = sb.toString();
```

## Why

`+=` in a loop creates a new `String` each iteration, which is O(n²) copying.
`StringBuilder` and `String.join` build the result in one pass.

## Evidence

For large collections this is measurable with a simple JMH benchmark. For tiny
collections (a handful of items) the difference is negligible, but the rewrite is
still acceptable because it does not hurt readability.

## When not to apply

- The loop runs at most a few times and the code is clearer as-is.
- The project already uses a formatter that prefers a different idiom.
- The values require per-item formatting that `String.join` cannot express.

## Verification

Output must be byte-for-byte identical. Watch for a trailing separator in the
original loop — `String.join` does not add one, so remove the trailing comma
from expectations if present.
