---
applyTo: "**/ViewModels/**/*.swift"
---

# ViewModel Guidelines

When working with ViewModels in Nestory Pro:

## Required Patterns

- Use `@Observable` macro (Swift 5.9+, not `@StateObject`)
- All ViewModels receive `AppEnvironment` or specific services in `init()`
- No `@MainActor` unless absolutely necessary for UI updates
- Keep business logic in Services - ViewModels coordinate only
- Public methods must have unit tests

## Dependency Injection

```swift
@Observable
class InventoryTabViewModel {
    private let settings: SettingsManager
    private let photoStorage: PhotoStorageProtocol

    init(settings: SettingsManager, photoStorage: PhotoStorageProtocol) {
        self.settings = settings
        self.photoStorage = photoStorage
    }
}
```

## Testing

- Create mock services conforming to protocols
- Test ViewModel logic in isolation
- Use `AppEnvironment.mock()` for dependencies
- Never test UI rendering in ViewModel tests
