# MCP Quick Reference

## Context7 HTTP Configuration

Context7 is now configured to use the **remote HTTP endpoint** instead of running locally. This means:
- ✅ **No local resources consumed** - Server runs on Context7's infrastructure
- ✅ **No Node.js/npm processes** on your machine
- ✅ **Faster startup** - No package installation needed
- ✅ **Always up-to-date** - Using latest version automatically

### Current Configuration
```json
{
    "servers": {
        "context7": {
            "type": "http",
            "url": "https://mcp.context7.com/mcp",
            "headers": {
                "CONTEXT7_API_KEY": "YOUR_API_KEY"
            }
        }
    }
}
```

### View API Key
```bash
security find-generic-password -s "Context7_API_Key" -w
```

### Update API Key in Config
After rotating your API key in the Keychain, update the config file:
```bash
# Get new key from Keychain
NEW_KEY=$(security find-generic-password -s "Context7_API_Key" -w)

# Update mcp.json with new key (edit manually or use sed)
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

### Check Logs
```bash
tail -f ~/Library/Logs/GitHubCopilot/MCPRuntimeLogs/Nestory-Pro-*.log
```

### Restart Xcode
After updating configuration, restart Xcode for changes to take effect.

## Configuration Files

- **MCP Config**: `~/.config/github-copilot/xcode/mcp.json`
- **MCP Runtime Logs**: `~/Library/Logs/GitHubCopilot/MCPRuntimeLogs/`
- **Documentation**: `.github/MCP-SETUP.md`

## Common Issues

| Issue | Solution |
|-------|----------|
| "API key not found" | Update the API key in `~/.config/github-copilot/xcode/mcp.json` headers |
| Server not loading | Restart Xcode, check logs with `tail -f ~/Library/Logs/GitHubCopilot/MCPRuntimeLogs/Nestory-Pro-*.log` |
| "Connection refused" | Check internet connection, verify URL is `https://mcp.context7.com/mcp` |
| "Unauthorized" | API key is invalid or expired, get new key from [context7.com/dashboard](https://context7.com/dashboard) |

## Security Status

- ✅ API key stored in macOS Keychain (encrypted)
- ⚠️ API key referenced in mcp.json (stored in headers)
- ✅ No local processes running
- ✅ HTTPS encrypted communication
- ✅ Minimal local resource usage

## Active MCP Servers

1. **context7** - Context management ✅ (remote HTTP, hosted by Upstash)
