fastlane documentation
----

# Installation

Make sure you have the latest version of the Xcode command line tools installed:

```sh
xcode-select --install
```

For _fastlane_ installation instructions, see [Installing _fastlane_](https://docs.fastlane.tools/#installing-fastlane)

# Available Actions

## iOS

### ios ensure_app_exists

```sh
[bundle exec] fastlane ios ensure_app_exists
```

Ensure app exists in App Store Connect (creates if missing)

### ios test

```sh
[bundle exec] fastlane ios test
```

Run all tests (unit + UI) on simulator

### ios test_unit

```sh
[bundle exec] fastlane ios test_unit
```

Run unit tests only (faster, for CI)

### ios beta

```sh
[bundle exec] fastlane ios beta
```

Build and upload to TestFlight

### ios release

```sh
[bundle exec] fastlane ios release
```

Build and submit to App Store (manual gating: submit_for_review is false)

### ios upload_archive

```sh
[bundle exec] fastlane ios upload_archive
```

Upload existing archive to TestFlight

### ios bump_version

```sh
[bundle exec] fastlane ios bump_version
```

Bump version (patch/minor/major)

### ios icons

```sh
[bundle exec] fastlane ios icons
```

Generate app icons from source image

----

This README.md is auto-generated and will be re-generated every time [_fastlane_](https://fastlane.tools) is run.

More information about _fastlane_ can be found on [fastlane.tools](https://fastlane.tools).

The documentation of _fastlane_ can be found on [docs.fastlane.tools](https://docs.fastlane.tools).
