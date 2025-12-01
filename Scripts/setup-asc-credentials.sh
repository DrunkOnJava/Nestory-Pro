#!/bin/bash
#
# setup-asc-credentials.sh
# Interactive setup for App Store Connect API credentials
#

set -e

echo "=================================================="
echo "App Store Connect API Credential Setup"
echo "=================================================="
echo ""

# Check if credentials already exist
if security find-generic-password -a "$USER" -s "ASC_API_KEY_ID" &>/dev/null; then
    echo "⚠️  Existing credentials found in Keychain"
    echo ""
    read -p "Replace existing credentials? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo "Keeping existing credentials."
        exit 0
    fi
fi

echo "Please enter your App Store Connect API credentials:"
echo ""

# Get Key ID
read -p "Key ID (10 characters, e.g., XXXXXXXXXX): " KEY_ID
if [ ${#KEY_ID} -ne 10 ]; then
    echo "❌ Error: Key ID must be exactly 10 characters"
    exit 1
fi

# Get Issuer ID
read -p "Issuer ID (UUID format): " ISSUER_ID
if [[ ! $ISSUER_ID =~ ^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$ ]]; then
    echo "❌ Error: Issuer ID must be a valid UUID"
    exit 1
fi

# Get Private Key Path
read -p "Path to .p8 file: " P8_PATH
P8_PATH="${P8_PATH/#\~/$HOME}"  # Expand ~ to home directory

if [ ! -f "$P8_PATH" ]; then
    echo "❌ Error: File not found: $P8_PATH"
    exit 1
fi

# Verify file is a .p8 key
if ! grep -q "BEGIN PRIVATE KEY" "$P8_PATH"; then
    echo "❌ Error: File does not appear to be a valid .p8 private key"
    exit 1
fi

echo ""
echo "Storing credentials in macOS Keychain..."
echo ""

# Delete old credentials if they exist
security delete-generic-password -a "$USER" -s "ASC_API_KEY_ID" 2>/dev/null || true
security delete-generic-password -a "$USER" -s "ASC_ISSUER_ID" 2>/dev/null || true
security delete-generic-password -a "$USER" -s "ASC_PRIVATE_KEY" 2>/dev/null || true

# Store Key ID
security add-generic-password \
  -a "$USER" \
  -s "ASC_API_KEY_ID" \
  -w "$KEY_ID" \
  -U

# Store Issuer ID
security add-generic-password \
  -a "$USER" \
  -s "ASC_ISSUER_ID" \
  -w "$ISSUER_ID" \
  -U

# Store Private Key (base64 encoded)
BASE64_KEY=$(cat "$P8_PATH" | base64)
security add-generic-password \
  -a "$USER" \
  -s "ASC_PRIVATE_KEY" \
  -w "$BASE64_KEY" \
  -U

echo "✅ Credentials stored successfully!"
echo ""
echo "Verifying credentials..."
echo ""

# Test credentials with CLI tool
if [ ! -f "Tools/xcodecloud-cli/.build/release/xcodecloud-cli" ]; then
    echo "Building CLI tool..."
    cd Tools/xcodecloud-cli
    swift build -c release
    cd ../..
fi

echo "Testing API connection..."
if ./Tools/xcodecloud-cli/.build/release/xcodecloud-cli list-products --json >/dev/null 2>&1; then
    echo "✅ API connection successful!"
else
    echo "❌ API connection failed. Check your credentials."
    exit 1
fi

echo ""
echo "=================================================="
echo "Setup Complete!"
echo "=================================================="
echo ""
echo "You can now use:"
echo "  make xc-cloud-products"
echo "  make xc-cloud-workflows"
echo "  ./Scripts/xc-cloud-create-workflows.sh"
echo ""
