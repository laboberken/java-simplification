# Guard clauses instead of nested ifs

**Dimension:** simplify
**Java baseline:** 8+
**Risk:** low

## Before

```java
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
```

## After

```java
public void process(Order order) {
    if (order == null || !order.isValid()) return;
    if (order.getCustomer() == null || !order.getCustomer().isActive()) return;
    doWork(order);
}
```

## Why

Each guard clause handles one precondition and exits early. The happy path stays
at the top level instead of being buried four indentation levels deep.

## When not to apply

- The branches have different side effects (e.g. logging a specific reason,
  throwing different exception types) that the flattening would lose.
- The method must return different values per branch rather than simply return.
- The project style requires a single return at the end of the method.

## Verification

Existing tests must pass. If the original silently ignored invalid input, the
guard-clause version must also ignore it rather than throw.
