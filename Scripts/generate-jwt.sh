#!/bin/bash
set -e

#===============================================================================
# Generate JWT for App Store Connect API
#===============================================================================
# Generates a JSON Web Token for authenticating with App Store Connect API
# using ES256 signature algorithm (ECDSA with P-256 and SHA-256)
#===============================================================================

# Load credentials from environment or Keychain
if [ -z "$ASC_KEY_ID" ] || [ -z "$ASC_ISSUER_ID" ]; then
    echo "Error: ASC_KEY_ID and ASC_ISSUER_ID must be set" >&2
    exit 1
fi

if [ -z "$ASC_PRIVATE_KEY_PATH" ]; then
    echo "Error: ASC_PRIVATE_KEY_PATH must be set" >&2
    exit 1
fi

if [ ! -f "$ASC_PRIVATE_KEY_PATH" ]; then
    echo "Error: Private key file not found: $ASC_PRIVATE_KEY_PATH" >&2
    exit 1
fi

# JWT Header (base64url encoded)
HEADER=$(echo -n "{\"alg\":\"ES256\",\"kid\":\"$ASC_KEY_ID\",\"typ\":\"JWT\"}" | \
    openssl base64 -e | \
    tr -d '=' | \
    tr '/+' '_-' | \
    tr -d '\n')

# JWT Payload (base64url encoded)
ISSUED_AT=$(date +%s)
EXPIRES_AT=$((ISSUED_AT + 1200))  # 20 minutes from now

PAYLOAD=$(echo -n "{\"iss\":\"$ASC_ISSUER_ID\",\"iat\":$ISSUED_AT,\"exp\":$EXPIRES_AT,\"aud\":\"appstoreconnect-v1\"}" | \
    openssl base64 -e | \
    tr -d '=' | \
    tr '/+' '_-' | \
    tr -d '\n')

# JWT Signature (ES256)
SIGNATURE=$(echo -n "$HEADER.$PAYLOAD" | \
    openssl dgst -sha256 -sign "$ASC_PRIVATE_KEY_PATH" | \
    openssl base64 -e | \
    tr -d '=' | \
    tr '/+' '_-' | \
    tr -d '\n')

# Complete JWT
JWT="$HEADER.$PAYLOAD.$SIGNATURE"

echo "$JWT"
