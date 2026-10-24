# Extract class within the same package

**Dimension:** arch (in-package)
**Java baseline:** 8+
**Risk:** medium

## Before

```java
package com.example.order;

public class OrderService {
    public BigDecimal calculateTotal(Order order) {
        // pricing logic
        BigDecimal total = BigDecimal.ZERO;
        for (Item item : order.getItems()) {
            total = total.add(item.getPrice().multiply(BigDecimal.valueOf(item.getQuantity())));
        }
        return total.add(order.getShippingFee());
    }

    public String renderInvoice(Order order) {
        // rendering logic
        StringBuilder sb = new StringBuilder();
        sb.append("Order ").append(order.getId()).append("\n");
        for (Item item : order.getItems()) {
            sb.append(item.getName()).append(" x").append(item.getQuantity()).append("\n");
        }
        return sb.toString();
    }
}
```

## After

```java
package com.example.order;

public class OrderService {
    private final PricingCalculator pricing = new PricingCalculator();
    private final InvoiceRenderer renderer = new InvoiceRenderer();

    public BigDecimal calculateTotal(Order order) {
        return pricing.calculate(order);
    }

    public String renderInvoice(Order order) {
        return renderer.render(order);
    }
}
```

Plus two new classes **in the same package**:

```java
package com.example.order;

class PricingCalculator {
    BigDecimal calculate(Order order) {
        BigDecimal total = BigDecimal.ZERO;
        for (Item item : order.getItems()) {
            total = total.add(item.getPrice().multiply(BigDecimal.valueOf(item.getQuantity())));
        }
        return total.add(order.getShippingFee());
    }
}
```

```java
package com.example.order;

class InvoiceRenderer {
    String render(Order order) {
        StringBuilder sb = new StringBuilder();
        sb.append("Order ").append(order.getId()).append("\n");
        for (Item item : order.getItems()) {
            sb.append(item.getName()).append(" x").append(item.getQuantity()).append("\n");
        }
        return sb.toString();
    }
}
```

## Why

`OrderService` had two unrelated responsibilities. Each new class is
package-private and stays in the same package, so the module boundary and public
API are unchanged.

## When not to apply

- The two responsibilities are small and likely to stay together.
- Extracting the class would require moving it to another package to be useful.
- The class is part of a public API and the extraction would change visibility.

## Verification

Existing tests must pass. If tests reference `OrderService` internals, keep the
public methods as delegating wrappers.
