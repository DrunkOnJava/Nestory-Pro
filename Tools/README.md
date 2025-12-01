# Tools Directory

This directory contains command-line tools and utilities for Nestory-Pro development.

## xcodecloud-cli

Swift command-line tool for managing Xcode Cloud via App Store Connect API.

### Features

- **List Products**: Discover Xcode Cloud products
- **List Workflows**: View all configured workflows
- **Trigger Builds**: Start builds programmatically
- **Monitor Status**: Check build progress

### Quick Start

```bash
# Build the CLI tool
cd xcodecloud-cli
swift build -c release

# Or use Make
make xc-cloud-setup

# Run commands
./scripts/xcodecloud.sh list-products
./scripts/xcodecloud.sh list-workflows
```

### Requirements

- Swift 5.9+
- macOS 13.0+
- App Store Connect API key

### Documentation

See [docs/XCODE_CLOUD_CLI_SETUP.md](../docs/XCODE_CLOUD_CLI_SETUP.md) for complete setup and usage instructions.

### Dependencies

- [swift-argument-parser](https://github.com/apple/swift-argument-parser): Command-line argument parsing
- [swift-crypto](https://github.com/apple/swift-crypto): ES256 JWT signing

### Architecture

```
xcodecloud-cli/
├── Package.swift              # Swift Package Manager manifest
└── Sources/
    └── xcodecloud-cli/
        └── main.swift        # CLI implementation
```

The CLI tool:
1. Reads credentials from environment variables or macOS Keychain
2. Generates JWT tokens for App Store Connect API authentication
3. Makes HTTPS requests to App Store Connect endpoints
4. Parses and displays responses in human-readable format

### Environment Variables

| Variable | Description |
|----------|-------------|
| `ASC_KEY_ID` | App Store Connect API Key ID |
| `ASC_ISSUER_ID` | App Store Connect Issuer ID |
| `ASC_PRIVATE_KEY_PATH` | Path to `.p8` private key file |
| `ASC_PRIVATE_KEY` | Base64-encoded private key content (alternative to path) |
| `XC_CLOUD_DRY_RUN` | Print API calls without executing |
| `XC_CLOUD_VERBOSE` | Enable verbose logging |

### Examples

```bash
# List all products
xcodecloud-cli list-products

# List workflows (with JSON output)
xcodecloud-cli list-workflows --product <id> --json

# Trigger build
xcodecloud-cli trigger-build --workflow <id> --branch main

# Check build status
xcodecloud-cli get-build --build <id>

# Dry run mode
XC_CLOUD_DRY_RUN=1 xcodecloud-cli trigger-build --workflow <id> --branch main
```

### Development

```bash
# Build
swift build

# Run
swift run xcodecloud-cli list-products

# Release build
swift build -c release

# Install locally
cp .build/release/xcodecloud-cli /usr/local/bin/
```

---

**Last Updated:** November 30, 2025
