# Extract method

**Dimension:** arch (in-package)
**Java baseline:** 8+
**Risk:** low

## Before

```java
public void createOrder(OrderRequest request) {
    // validate
    if (request.getItems().isEmpty()) {
        throw new IllegalArgumentException("order must contain at least one item");
    }
    if (request.getCustomerId() == null) {
        throw new IllegalArgumentException("customerId is required");
    }

    // price
    BigDecimal total = BigDecimal.ZERO;
    for (Item item : request.getItems()) {
        total = total.add(item.getPrice().multiply(BigDecimal.valueOf(item.getQuantity())));
    }
    total = total.add(request.getShippingFee());

    // persist
    Order order = new Order(request.getCustomerId(), request.getItems(), total);
    orderRepository.save(order);
}
```

## After

```java
public void createOrder(OrderRequest request) {
    validate(request);
    BigDecimal total = calculateTotal(request);
    orderRepository.save(new Order(request.getCustomerId(), request.getItems(), total));
}

private void validate(OrderRequest request) {
    if (request.getItems().isEmpty()) {
        throw new IllegalArgumentException("order must contain at least one item");
    }
    if (request.getCustomerId() == null) {
        throw new IllegalArgumentException("customerId is required");
    }
}

private BigDecimal calculateTotal(OrderRequest request) {
    BigDecimal total = BigDecimal.ZERO;
    for (Item item : request.getItems()) {
        total = total.add(item.getPrice().multiply(BigDecimal.valueOf(item.getQuantity())));
    }
    return total.add(request.getShippingFee());
}
```

## Why

The public method now reads as three named steps. The extracted methods live in
the **same class** and stay private, so no public API changes and no cross-package
moves.

## When not to apply

- The extracted block depends on many local variables; a method with ten
  parameters is worse than the original.
- The method is performance-critical and inlining matters (rare; verify first).
- The block is a one-off with no meaningful name.

## Verification

Existing tests must pass. Since visibility is `private`, no other class needs to
change.
