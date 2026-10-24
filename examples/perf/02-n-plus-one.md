# N+1 queries in a loop

**Dimension:** perf
**Java baseline:** 8+
**Risk:** medium

## Before

```java
List<Order> orders = orderRepository.findAll();
for (Order order : orders) {
    Customer customer = customerRepository.findById(order.getCustomerId()).orElseThrow();
    order.setCustomerName(customer.getName());
}
```

## After

```java
List<Order> orders = orderRepository.findAll();
Set<Long> customerIds = orders.stream()
    .map(Order::getCustomerId)
    .collect(Collectors.toSet());

Map<Long, String> namesById = customerRepository.findAllById(customerIds).stream()
    .collect(Collectors.toMap(Customer::getId, Customer::getName));

for (Order order : orders) {
    order.setCustomerName(namesById.getOrDefault(order.getCustomerId(), "Unknown"));
}
```

## Why

The original issues one query per order (N+1). The rewrite issues two queries in
total regardless of the number of orders.

## When not to apply

- The list is tiny and bounded (for example, a fixed enum-driven list).
- A join or `@EntityGraph` in the repository is the project's preferred fix.
- `findAllById` would exceed database parameter limits; batch the IDs instead.

## Evidence

N+1 is usually visible in query logs or APM traces. If you cannot observe the
query count, do not guess — leave it as a recommendation.

## Verification

Results must be identical, including the fallback for missing customers. If the
original threw on a missing customer, preserve that behavior instead of using
`"Unknown"`.
