# Remove duplication with a package-private helper

**Dimension:** arch (in-package)
**Java baseline:** 8+
**Risk:** low

## Before

```java
package com.example.customer;

class CustomerValidator {
    boolean isValid(Customer customer) {
        return customer != null
            && customer.getEmail() != null
            && customer.getEmail().contains("@")
            && customer.getName() != null
            && !customer.getName().isBlank();
    }
}

class CustomerImporter {
    void importCustomer(Customer customer) {
        if (customer == null
            || customer.getEmail() == null
            || !customer.getEmail().contains("@")
            || customer.getName() == null
            || customer.getName().isBlank()) {
            throw new IllegalArgumentException("invalid customer");
        }
        // persist
    }
}
```

## After

```java
package com.example.customer;

class CustomerValidator {
    boolean isValid(Customer customer) {
        return customer != null
            && customer.getEmail() != null
            && customer.getEmail().contains("@")
            && customer.getName() != null
            && !customer.getName().isBlank();
    }
}

class CustomerImporter {
    private final CustomerValidator validator = new CustomerValidator();

    void importCustomer(Customer customer) {
        if (!validator.isValid(customer)) {
            throw new IllegalArgumentException("invalid customer");
        }
        // persist
    }
}
```

## Why

The validation rule existed twice. Reusing the existing package-private
`CustomerValidator` removes the duplication without adding a new utility class in
another package.

## When not to apply

- The two checks only look similar today but are expected to diverge (different
  messages, different rules per context).
- Reuse would create a dependency from a lower layer to a higher layer.
- The validator lives in another package and the move would break boundaries.

## Verification

Existing tests must pass. Add a test that pins the shared validation behavior if
one does not already exist.
