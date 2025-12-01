#!/bin/bash
set -e

#===============================================================================
# Test App Store Connect API Access
#===============================================================================
# Quick health check to verify credentials and API connectivity
#===============================================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo "Testing App Store Connect API Access"
echo "====================================="
echo ""

# Check environment variables
echo "1. Checking credentials..."
if [ -z "$ASC_KEY_ID" ] || [ -z "$ASC_ISSUER_ID" ]; then
    echo -e "${RED}❌ Missing credentials${NC}"
    echo "   Set ASC_KEY_ID and ASC_ISSUER_ID"
    exit 1
fi
echo -e "${GREEN}✅ Credentials found${NC}"
echo "   Key ID: $ASC_KEY_ID"
echo "   Issuer ID: ${ASC_ISSUER_ID:0:8}..."
echo ""

# Check private key
echo "2. Checking private key..."
if [ -n "$ASC_PRIVATE_KEY_PATH" ]; then
    if [ -f "$ASC_PRIVATE_KEY_PATH" ]; then
        echo -e "${GREEN}✅ Private key file found${NC}"
        echo "   Path: $ASC_PRIVATE_KEY_PATH"
    else
        echo -e "${RED}❌ Private key file not found${NC}"
        echo "   Path: $ASC_PRIVATE_KEY_PATH"
        exit 1
    fi
elif [ -n "$ASC_PRIVATE_KEY" ]; then
    echo -e "${GREEN}✅ Private key content found${NC}"
else
    echo -e "${RED}❌ No private key configured${NC}"
    echo "   Set ASC_PRIVATE_KEY_PATH or ASC_PRIVATE_KEY"
    exit 1
fi
echo ""

# Generate JWT
echo "3. Generating JWT..."
JWT=$("$SCRIPT_DIR/generate-jwt.sh" 2>&1) || {
    echo -e "${RED}❌ JWT generation failed${NC}"
    echo "$JWT"
    exit 1
}
echo -e "${GREEN}✅ JWT generated${NC}"
echo "   Length: ${#JWT} characters"
echo ""

# Test API call
echo "4. Testing API connectivity..."
RESPONSE=$(curl -s -w "\n%{http_code}" \
    -H "Authorization: Bearer $JWT" \
    -H "Content-Type: application/json" \
    "https://api.appstoreconnect.apple.com/v1/ciProducts")

HTTP_CODE=$(echo "$RESPONSE" | tail -n1)
BODY=$(echo "$RESPONSE" | head -n-1)

if [ "$HTTP_CODE" = "200" ]; then
    echo -e "${GREEN}✅ API call successful${NC}"
    echo "   HTTP $HTTP_CODE"
    echo ""

    # Parse products
    PRODUCT_COUNT=$(echo "$BODY" | jq '.data | length')
    echo "   Found $PRODUCT_COUNT Xcode Cloud product(s)"

    # Check for Nestory-Pro
    NESTORY_PRODUCT=$(echo "$BODY" | jq -r '.data[] | select(.attributes.name == "Nestory-Pro") | .id')
    if [ -n "$NESTORY_PRODUCT" ]; then
        echo -e "   ${GREEN}✅ Nestory-Pro product found${NC}"
        echo "      Product ID: $NESTORY_PRODUCT"
    else
        echo -e "   ${YELLOW}⚠️  Nestory-Pro product not found${NC}"
        echo "      Ensure Xcode Cloud is enabled for the app in App Store Connect"
    fi
else
    echo -e "${RED}❌ API call failed${NC}"
    echo "   HTTP $HTTP_CODE"
    echo ""
    echo "Response:"
    echo "$BODY" | jq '.' 2>/dev/null || echo "$BODY"
    exit 1
fi

echo ""
echo "====================================="
echo -e "${GREEN}All tests passed! ✅${NC}"
echo ""
echo "Next steps:"
echo "  • List workflows: make xc-cloud-workflows"
echo "  • Trigger build: make xc-cloud-pr-validate"
echo "  • Read docs: docs/XCODE_CLOUD_CLI_SETUP.md"
