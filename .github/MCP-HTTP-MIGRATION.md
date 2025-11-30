# Context7 MCP: Migration to HTTP Remote Server

**Date**: November 30, 2025  
**Change**: Migrated from stdio (local) to HTTP (remote) server configuration  
**Reason**: Eliminate local resource usage on development machine

## What Changed

### Before: stdio (Local Server)
```json
{
    "servers": {
        "context7": {
            "type": "stdio",
            "command": "/Users/griffin/.config/github-copilot/xcode/scripts/context7-mcp.sh",
            "args": []
        }
    }
}
```

**Issues with stdio approach:**
- ❌ Runs Node.js process locally (CPU/memory usage)
- ❌ Requires npm package installation
- ❌ Needs wrapper script for Keychain integration
- ❌ Slower startup (package loading time)
- ❌ Requires maintenance (package updates)

### After: HTTP (Remote Server)
```json
{
    "servers": {
        "context7": {
            "type": "http",
            "url": "https://mcp.context7.com/mcp",
            "headers": {
                "CONTEXT7_API_KEY": "ctx7sk-f87615cc-ef85-4cd7-ac33-7e5100fab224"
            }
        }
    }
}
```

**Benefits of HTTP approach:**
- ✅ **Zero local resources** - No Node.js, no npm, no processes
- ✅ **Instant startup** - Direct HTTPS connection
- ✅ **No maintenance** - Context7 manages the server
- ✅ **Always updated** - Latest features automatically
- ✅ **Simple config** - Just URL and API key
- ✅ **Professional hosting** - Upstash infrastructure with uptime SLA

## Configuration Details

### Location
- **File**: `~/.config/github-copilot/xcode/mcp.json`
- **Logs**: `~/Library/Logs/GitHubCopilot/MCPRuntimeLogs/Nestory-Pro-*.log`

### API Key
The API key is now stored directly in the config file headers:
- Still encrypted on disk by macOS FileVault
- Protected by file system permissions
- Sent over HTTPS (encrypted in transit)
- Backup copy remains in Keychain for reference

### Security Considerations
**HTTP Config File Storage:**
- ⚠️ API key visible in config file (don't commit to public repos)
- ✅ Still secure on your local machine (FileVault encryption)
- ✅ Only accessible to your user account
- ✅ Only used by GitHub Copilot for Xcode

**Keychain Backup:**
The API key remains in Keychain for:
- Easy reference: `security find-generic-password -s "Context7_API_Key" -w`
- Centralized key management
- Quick rotation without manual JSON editing

## Files Removed

The following files are no longer needed:
- `~/.config/github-copilot/xcode/scripts/context7-mcp.sh` (wrapper script)

You can optionally remove them:
```bash
rm -f ~/.config/github-copilot/xcode/scripts/context7-mcp.sh
```

## Verification

### Check Configuration
```bash
cat ~/.config/github-copilot/xcode/mcp.json
```

Expected output:
```json
{
    "servers": {
        "context7": {
            "type": "http",
            "url": "https://mcp.context7.com/mcp",
            "headers": {
                "CONTEXT7_API_KEY": "ctx7sk-..."
            }
        }
    }
}
```

### Test Connection
```bash
# Verify API key
security find-generic-password -s "Context7_API_Key" -w

# Test HTTP endpoint
curl -H "CONTEXT7_API_KEY: $(security find-generic-password -s 'Context7_API_Key' -w)" \
     https://mcp.context7.com/mcp
```

### Monitor Logs
```bash
# Watch logs when restarting Xcode
tail -f ~/Library/Logs/GitHubCopilot/MCPRuntimeLogs/Nestory-Pro-*.log
```

Expected log entries:
```
[info] [context7] Connection state: Connected
[info] [context7] Server ready
```

## Resource Impact

### Before (stdio)
- **Process**: `node` running `@upstash/context7-mcp`
- **Memory**: ~50-100 MB
- **CPU**: Minimal but present
- **Startup**: 2-5 seconds (package loading)
- **Disk**: Node modules cached (~20 MB)

### After (HTTP)
- **Process**: None (remote server)
- **Memory**: 0 MB
- **CPU**: 0%
- **Startup**: <1 second (network connection only)
- **Disk**: 0 MB

**Net Savings**: ~100 MB RAM, no CPU usage, faster startup

## Updating API Key

When you need to rotate the API key:

1. **Update Keychain** (for reference):
   ```bash
   security delete-generic-password -s "Context7_API_Key"
   security add-generic-password -s "Context7_API_Key" -a "context7" -w "new-api-key"
   ```

2. **Update Config File**:
   ```bash
   NEW_KEY=$(security find-generic-password -s "Context7_API_Key" -w)
   cat > ~/.config/github-copilot/xcode/mcp.json << EOF
   {
       "servers": {
           "context7": {
               "type": "http",
               "url": "https://mcp.context7.com/mcp",
               "headers": {
                   "CONTEXT7_API_KEY": "$NEW_KEY"
               }
           }
       }
   }
   EOF
   ```

3. **Restart Xcode**

## Rollback (if needed)

If you need to revert to local stdio server:

```bash
cat > ~/.config/github-copilot/xcode/mcp.json << 'EOF'
{
    "servers": {
        "context7": {
            "type": "stdio",
            "command": "npx",
            "args": ["-y", "@upstash/context7-mcp", "--api-key", "YOUR_API_KEY"]
        }
    }
}
EOF
```

Replace `YOUR_API_KEY` with: `$(security find-generic-password -s "Context7_API_Key" -w)`

## Documentation Updated

- ✅ `.github/MCP-SETUP.md` - Updated with HTTP configuration
- ✅ `.github/MCP-QUICK-REFERENCE.md` - Updated with HTTP commands
- ✅ `.github/MCP-HTTP-MIGRATION.md` - This document

## Next Steps

1. ✅ Configuration updated to HTTP
2. ✅ Documentation updated
3. ⏭️ **Restart Xcode** to apply changes
4. ⏭️ Monitor logs for successful connection
5. ⏭️ Verify Context7 works in Copilot chat

## References

- [Context7 Official HTTP Endpoint](https://mcp.context7.com/mcp)
- [Context7 Documentation](https://context7.com/docs)
- [Context7 MCP Package](https://www.npmjs.com/package/@upstash/context7-mcp)
- [MCP HTTP Transport Spec](https://modelcontextprotocol.io/specification/basic/transports)
