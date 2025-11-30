---
applyTo: "**/Models/**/*.swift"
---

# SwiftData Model Guidelines

When working with SwiftData models in Nestory Pro:

## Required Patterns

- Always use `@Model` macro
- Define relationships with `@Relationship(deleteRule: .cascade | .nullify)`
- Computed properties for derived values (e.g., `documentationScore`)
- No complex business logic - use Services instead
- All public computed properties must have unit tests

## Documentation Score

This project uses 6-field weighted scoring:
- Photo: 30%, Value: 25%, Room: 15%, Category: 10%, Receipt: 10%, Serial: 10%

## Relationship Rules

- Item → ItemPhoto: cascade delete
- Item → Receipt: nullify on delete
- Item → Category: required, immutable
- Item → Room: required, immutable

## Testing

- Use `TestFixtures` for model creation
- Use `TestContainer.withSampleData()` for in-memory persistence
- Test all computed properties
- Test relationship cascades
