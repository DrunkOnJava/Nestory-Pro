# Fastlane Setup - 100% CLI

All configuration done from terminal, no GUI clicking.

## What's Configured

**Files:**
```
fastlane/
├── Appfile          # App ID, Apple ID, Team ID
├── Fastfile         # Lanes: test, beta, release, bump_version
├── .env             # Environment variables (NOT committed)
└── AuthKey_*.p8     # App Store Connect API key (NOT committed)

.github/workflows/
└── beta.yml         # GitHub Actions workflow for TestFlight
```

**GitHub Secrets** (set via `gh secret set`):
- FASTLANE_APPLE_ID
- APP_STORE_CONNECT_KEY_ID
- APP_STORE_CONNECT_ISSUER_ID
- APP_STORE_CONNECT_API_KEY_CONTENT

## Usage

### Run tests
```bash
bundle exec fastlane test
```

### Deploy to TestFlight
```bash
bundle exec fastlane beta
```

### Deploy to App Store
```bash
bundle exec fastlane release
```

### Version management
```bash
# Patch: 1.0.0 → 1.0.1
bundle exec fastlane bump_version

# Minor: 1.0.0 → 1.1.0
bundle exec fastlane bump_version type:minor

# Major: 1.0.0 → 2.0.0
bundle exec fastlane bump_version type:major
```

## CI/CD

Push to `main` branch triggers automatic TestFlight upload via GitHub Actions.

## Security

- `fastlane/.env` - excluded from Git
- `fastlane/*.p8` - excluded from Git
- All secrets in GitHub Secrets for CI

## Signing

Uses **Xcode automatic signing** (already configured in Xcode project).
No Match required since you're using automatic signing.

---

**Setup Date:** 2025-11-28  
**Method:** 100% Terminal/CLI (no GUI)
