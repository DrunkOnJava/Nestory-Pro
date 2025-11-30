# GitHub Copilot Instructions for Nestory Pro

## Project Context

This is Nestory Pro, an iOS 17+ home inventory app built with Swift 5, SwiftUI, and SwiftData.

**Current Status:** v1.0 shipped, v1.1 planning (Swift 6 migration)

## Coding Standards

### Swift Style
- Use `@Observable` macro for ViewModels (not `@StateObject`)
- Services are `actor`-isolated for thread safety
- All SwiftData operations on `@MainActor`
- No `.shared` singletons - use AppEnvironment DI

### Testing Requirements
- Test naming: `test<What>_<Condition>_<ExpectedResult>()`
- Use `TestFixtures` for predictable data
- In-memory containers only (never production data)
- Unit tests < 0.1s, Integration < 1s

### Simulator
**Always use iPhone 17 Pro Max** for builds and tests.

## Task Management

Before implementing features:
1. Check [TODO.md](TODO.md) for existing tasks
2. Follow checkout procedure if taking a task
3. Don't modify pricing, roadmap, or strategic docs without approval

## Governance

**Strategic changes require approval:**
- Pricing tiers or feature mappings
- Release roadmap modifications
- Product behavior changes
- Governance document edits

See [CLAUDE.md](CLAUDE.md) § Agent Collaboration Rules for complete governance model.

## Quick References

- [PRODUCT-SPEC.md](PRODUCT-SPEC.md) - Product requirements
- [WARP.md](WARP.md) - Extended development guide
- [TestingStrategy.md](TestingStrategy.md) - Testing architecture
- [PreviewExamples.md](PreviewExamples.md) - SwiftUI preview patterns
