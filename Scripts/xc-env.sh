#!/bin/bash
# Source this file to load Xcode Cloud credentials into environment
# Usage: source ./Scripts/xc-env.sh

export ASC_KEY_ID="ACR4LF383U"
export ASC_ISSUER_ID="f144f0a6-1aff-44f3-974e-183c4c07bc46"
export ASC_PRIVATE_KEY_PATH="/Users/griffin/Downloads/AuthKey_ACR4LF383U.p8"
export NESTORY_PRODUCT_ID="B6CFF695-FAF8-4D64-9C16-8F46A73F76EF"

echo "✅ Xcode Cloud credentials loaded"
echo "   Key ID: $ASC_KEY_ID"
echo "   Issuer ID: ${ASC_ISSUER_ID:0:8}..."
echo "   Product ID: ${NESTORY_PRODUCT_ID:0:8}..."
echo ""
echo "Available commands:"
echo "  make xc-cloud-workflows"
echo "  make xc-cloud-pr-validate"
echo "  ./Scripts/xcodecloud.sh list-workflows"
