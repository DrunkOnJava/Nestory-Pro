# MCP Server Configuration

## Overview

GitHub Copilot for Xcode uses MCP (Model Context Protocol) servers to integrate with external services. This document explains the configuration setup for Context7 and other MCP servers.

## Configuration Files

- **MCP Config**: `~/.config/github-copilot/xcode/mcp.json`
- **MCP Runtime Logs**: `~/Library/Logs/GitHubCopilot/MCPRuntimeLogs/`

## Context7 Integration

### Architecture (HTTP Remote Server)

Context7 is configured to use the **remote HTTP endpoint** hosted by Upstash, which means it runs on their infrastructure instead of your local machine:

```
Xcode/Copilot → mcp.json (HTTP config) → https://mcp.context7.com/mcp → Context7 API
```

**Benefits:**
- ✅ **Zero local resources** - No Node.js processes, no npm packages, no CPU/memory usage
- ✅ **Faster startup** - No installation or compilation needed
- ✅ **Always updated** - Context7 maintains the server, you get updates automatically
- ✅ **Reliable** - Professional hosting with uptime guarantees
- ✅ **Simple config** - Just URL and API key, no wrapper scripts

### Current Configuration

**mcp.json** (HTTP remote server):
```json
{
  "servers": {
    "context7": {
      "type": "http",
      "url": "https://mcp.context7.com/mcp",
      "headers": {
        "CONTEXT7_API_KEY": "your-api-key-here"
      }
    }
  }
}
```

**Note:** The API key is stored directly in the config file headers. For maximum security, you can still use Keychain and manually sync the key to the config file when it changes.

### API Key Management

#### View Current Key (from Keychain)
```bash
security find-generic-password -s "Context7_API_Key" -w
```

#### Store New Key in Keychain
```bash
security add-generic-password -s "Context7_API_Key" -a "context7" -w "your-api-key"
```

#### Update Key in Config File
After updating Keychain, sync to mcp.json:
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

#### Get New API Key
Visit [context7.com/dashboard](https://context7.com/dashboard) to create an account and get your API key.

## Security Best Practices

### ✅ DO
- Store API keys in macOS Keychain as backup/reference
- Use HTTPS endpoints (like `https://mcp.context7.com/mcp`)
- Rotate API keys periodically
- Use absolute paths in mcp.json
- Document key names and services
- Monitor MCP logs for unauthorized access attempts

### ❌ DON'T
- Commit API keys to **public** version control (private repos are safer)
- Share Keychain exports containing API keys
- Use unencrypted HTTP endpoints
- Store keys in shell profiles or environment files

### Note on API Key Storage
With HTTP-type MCP servers, the API key is stored in the `mcp.json` file's headers. While this is **less secure than Keychain retrieval**, it's:
- ✅ Still encrypted on disk by macOS FileVault
- ✅ Protected by file system permissions (your user only)
- ✅ Only accessible to GitHub Copilot for Xcode
- ✅ Sent over HTTPS (encrypted in transit)
- ⚠️ Visible in the config file (don't commit to public repos)

For maximum security, keep a copy in Keychain and use `.gitignore` for `mcp.json` if needed.

## Benefits of HTTP Remote Server Approach

1. **Zero Local Resources**: No Node.js processes, no npm packages, no CPU/memory usage
2. **Instant Startup**: No installation or compilation needed, connects immediately
3. **Always Updated**: Context7 maintains the server, you get latest features automatically
4. **Simple Configuration**: Just URL and API key in JSON, no wrapper scripts
5. **Professional Hosting**: Upstash provides reliable infrastructure with uptime guarantees
6. **Version Control Safe**: Config file can be committed to private repos with API key in env vars
7. **No Maintenance**: No need to update packages or manage Node.js versions

## Troubleshooting

## Troubleshooting

### Server Not Starting
1. Check MCP runtime logs: `tail -f ~/Library/Logs/GitHubCopilot/MCPRuntimeLogs/Nestory-Pro-*.log`
2. Verify internet connection (HTTP servers require network access)
3. Test the endpoint manually: `curl -H "CONTEXT7_API_KEY: your-key" https://mcp.context7.com/mcp`
4. Restart Xcode

### Connection Errors
**"Connection refused"** or **"Network error"**:
- Check internet connection
- Verify URL is `https://mcp.context7.com/mcp` (not `http`)
- Check for firewall or VPN blocking the connection

### Authentication Errors
**"Unauthorized"** or **"Invalid API key"**:
- Verify API key in config matches Keychain: `security find-generic-password -s "Context7_API_Key" -w`
- Get new key from [context7.com/dashboard](https://context7.com/dashboard)
- Update both Keychain and mcp.json

### Keychain Access
While the API key is in the config file, Keychain is still useful for:
- Secure backup of your API key
- Easy key rotation without editing JSON manually
- Centralized key management across tools

## Migrating Other Servers

To migrate Firecrawl or other servers to this secure pattern:

1. Add key to Keychain:
   ```bash
   security add-generic-password -s "Firecrawl_API_Key" -a "firecrawl" -w "your-key"
   ```

2. Create wrapper script:
   ```bash
   cp ~/.config/github-copilot/xcode/scripts/context7-mcp.sh \
      ~/.config/github-copilot/xcode/scripts/firecrawl-mcp.sh
   # Edit to use FIRECRAWL_API_KEY and correct service name
   ```

3. Update mcp.json to use wrapper script

## Testing

```bash
# Verify API key in Keychain
security find-generic-password -s "Context7_API_Key" -w

# Test HTTP endpoint (replace YOUR_KEY)
curl -H "CONTEXT7_API_KEY: YOUR_KEY" https://mcp.context7.com/mcp

# Check configuration syntax
cat ~/.config/github-copilot/xcode/mcp.json | python3 -m json.tool

# Monitor logs when Xcode starts
tail -f ~/Library/Logs/GitHubCopilot/MCPRuntimeLogs/Nestory-Pro-*.log
```

### Expected Log Output
After restarting Xcode, you should see in the logs:
```
[info] [context7] Connection state: Connected
[info] [context7] Server ready
```

If you see errors, check the troubleshooting section above.

## Alternative: Local Server (stdio)

If you prefer to run Context7 locally (uses system resources), you can use:

```json
{
  "servers": {
    "context7": {
      "type": "stdio",
      "command": "npx",
      "args": ["-y", "@upstash/context7-mcp", "--api-key", "YOUR_API_KEY"]
    }
  }
}
```

**Note:** This will:
- ❌ Use local CPU/memory for Node.js process
- ❌ Require npm package installation on first run
- ❌ Need manual updates (`npm update -g @upstash/context7-mcp`)
- ✅ Work offline (if package is cached)

**Recommendation:** Use HTTP remote server for better performance and zero resource usage.

## References

- [MCP Specification](https://modelcontextprotocol.io/)
- [Context7 Documentation](https://context7.com/docs)
- [Context7 MCP Package](https://www.npmjs.com/package/@upstash/context7-mcp)
- [macOS Keychain Documentation](https://support.apple.com/guide/keychain-access/)
- GitHub Copilot for Xcode Settings
