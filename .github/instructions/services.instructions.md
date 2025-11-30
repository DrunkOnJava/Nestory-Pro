---
applyTo: "**/Services/**/*.swift"
---

# Service Guidelines

When working with Services in Nestory Pro:

## Actor Isolation

Services with state MUST be `actor`-isolated:

```swift
actor PhotoStorageService: PhotoStorageProtocol {
    func savePhoto(_ image: UIImage, for itemId: UUID) async throws -> String {
        // Thread-safe photo operations
    }
}
```

**MainActor services** (UI-bound):
- `SettingsManager` (AppStorage)
- `IAPValidator` (observable state)
- `AppLockService` (UI coordination)

## Protocol-Based Design

All services expose protocols for dependency injection:

```swift
protocol PhotoStorageProtocol {
    func savePhoto(_ image: UIImage, for itemId: UUID) async throws -> String
    func loadPhoto(identifier: String) async throws -> UIImage?
}

actor PhotoStorageService: PhotoStorageProtocol {
    // Implementation
}
```

## Dependency Management

- Services access other services via AppEnvironment
- No `.shared` singletons
- Use protocols for testability
- Mock services for unit tests

## Error Handling

- Throw specific errors (create custom Error enums)
- Log errors for debugging (DEBUG builds only)
- Provide user-friendly error messages
- Handle offline scenarios gracefully

## Testing

- Create mock implementations conforming to protocols
- Test error paths thoroughly
- Use in-memory resources (never real files/network in tests)
- Test concurrent access for actors
