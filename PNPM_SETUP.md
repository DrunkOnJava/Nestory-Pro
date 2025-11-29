# pnpm Setup - Best Practices Implementation

## Summary of Changes

### ✅ Fixed Issues

1. **PNPM_HOME Configuration**
   - **Issue**: `PNPM_HOME` environment variable was not set
   - **Fix**: Added proper `PNPM_HOME` export in `.zshrc`
   - **Location**: `~/.zshrc` lines 135-139

2. **Duplicate PATH Entries**
   - **Issue**: `$HOME/Library/pnpm` was in PATH but outdated
   - **Fix**: Removed from `.zshenv`, using proper `PNPM_HOME` path instead
   - **Result**: Clean PATH with no duplicates

3. **pnpm Configuration**
   - **Issue**: Minimal configuration with only `only-built-dependencies=png-img`
   - **Fix**: Created comprehensive best practices configuration
   - **Location**: `~/.config/pnpm/rc`

4. **Version Updates**
   - **Copilot CLI**: `0.0.354` → `0.0.365` ✅
   - **pnpm**: `10.23.0` → `10.24.0` ✅

### 📝 Configuration Files

#### `~/.config/pnpm/rc` (pnpm configuration)

```ini
# PERFORMANCE & SPEED
side-effects-cache=true                  # Build deps once per machine
modules-cache-max-age=10080              # Keep orphaned packages 7 days
enable-global-virtual-store=true         # Faster installs with warm cache

# DEPENDENCY MANAGEMENT
auto-install-peers=true                  # Auto-install missing peer deps
strict-peer-dependencies=false           # Don't fail on peer dep issues
resolution-mode=time-based               # Speed + security optimization

# NODE_MODULES STRUCTURE
shamefully-hoist=false                   # Use pnpm's efficient layout

# REGISTRIES
registry=https://registry.npmjs.org/     # npm registry
@jsr:registry=https://npm.jsr.io/       # JSR (Deno) registry

# SECURITY
verify-store-integrity=true              # Verify package integrity

# BUILD CONFIGURATION
only-built-dependencies[]=png-img        # Selective builds

# OUTPUT
progress=true                            # Show progress bars
color=true                               # Colorful output
```

#### `~/.zshrc` (shell configuration)

pnpm section now properly organized in the PNPM section (lines 132-147):

```bash
# ----------------------------------------------------------------------------
# PNPM (preferred package manager)
# ----------------------------------------------------------------------------
# Environment setup
export PNPM_HOME="/Users/griffin/.local/share/pnpm"
case ":$PATH:" in
  *":$PNPM_HOME:"*) ;;
  *) export PATH="$PNPM_HOME:$PATH" ;;
esac

# Convenient aliases
alias pn='pnpm'
alias pni='pnpm install'
alias pna='pnpm add'
alias pnr='pnpm run'
alias pnx='pnpm dlx'
```

## Best Practices Implemented

### 🚀 Performance Optimizations

1. **Side Effects Cache** (`side-effects-cache=true`)
   - Dependencies with build scripts are built only once per machine
   - Significantly improves installation speed in projects with native deps

2. **Modules Cache** (`modules-cache-max-age=10080`)
   - Keeps orphaned packages for 7 days
   - Faster branch switching and dependency downgrades
   - Balance between speed and disk usage

3. **Global Virtual Store** (`enable-global-virtual-store=true`)
   - Faster installs with warm cache
   - Automatically disabled in CI environments

4. **Time-Based Resolution** (`resolution-mode=time-based`)
   - Faster installs with warm cache
   - Reduces risk of subdependency hijacking
   - Updates subdeps only when direct deps update

### 🔒 Security & Reliability

1. **Store Integrity Verification** (`verify-store-integrity=true`)
   - Verifies package integrity during operations
   - Catches corruption issues early

2. **Auto-Install Peer Dependencies** (`auto-install-peers=true`)
   - Automatically resolves missing peer deps
   - Safer than ignoring peer dependency warnings
   - Prevents runtime errors from missing peers

3. **Flexible Peer Dependencies** (`strict-peer-dependencies=false`)
   - Don't fail on peer dependency version mismatches
   - More flexible for development
   - Can be overridden per-project if needed

### 📦 Efficient Node Modules

1. **Semistrict Layout** (`shamefully-hoist=false`)
   - Uses pnpm's efficient node_modules structure
   - Hard links to save disk space
   - Prevents phantom dependencies
   - Only hoist if tools require it (add to project `.npmrc`)

### 🎯 Selective Builds

1. **Only Build What's Needed** (`only-built-dependencies[]=png-img`)
   - Speeds up installs by skipping unnecessary builds
   - Add more patterns as needed per project

## Verification

```bash
# Check configuration
pnpm config list

# Verify versions
pnpm --version           # Should show 10.24.0
copilot --version        # Should show 0.0.365

# Check PATH
echo $PNPM_HOME          # Should show /Users/griffin/.local/share/pnpm
which pnpm               # Should show ~/.local/share/pnpm/pnpm
```

## Usage Tips

### Quick Commands

```bash
# Install dependencies
pni                      # alias for 'pnpm install'

# Add packages
pna <package>            # alias for 'pnpm add'
pna -D <package>         # Add as dev dependency
pna -g <package>         # Global install

# Run scripts
pnr <script>             # alias for 'pnpm run'
pnr dev                  # Run dev server
pnr build                # Build project

# Execute packages without installing
pnx <package>            # alias for 'pnpm dlx' (like npx)
pnx create-react-app my-app
```

### Maintenance

```bash
# Update pnpm itself
mise use -g pnpm@latest

# Clean store (occasionally, not too often)
pnpm store prune

# Update all packages
pnpm update --latest

# Check for outdated packages
pnpm outdated
```

### Project-Specific Configuration

Create `.npmrc` in project root for project-specific settings:

```ini
# Example: Enable hoisting for specific tools
public-hoist-pattern[]=*eslint*
public-hoist-pattern[]=*prettier*

# Example: Strict mode for production projects
strict-peer-dependencies=true
```

## Troubleshooting

### Issue: Tool can't find dependency

**Solution**: Add to project `.npmrc`:
```ini
shamefully-hoist=true
```
Or hoist specific packages:
```ini
public-hoist-pattern[]=*package-name*
```

### Issue: Peer dependency warnings

**Solution**: Either install the peer dependency or ignore specific warnings in project `package.json`:
```json
{
  "pnpm": {
    "peerDependencyRules": {
      "allowAny": ["@babel/*", "eslint"]
    }
  }
}
```

### Issue: Slow installs in CI

**Solution**: `enable-global-virtual-store` is automatically disabled in CI. You can also:
```bash
# Use frozen lockfile in CI
pnpm install --frozen-lockfile
```

## References

- [pnpm Documentation](https://pnpm.io/)
- [pnpm Configuration](https://pnpm.io/npmrc)
- [pnpm CLI](https://pnpm.io/cli/install)
- [Best Practices from Context7](https://github.com/pnpm/pnpm.io)

## Migration from npm/yarn

If you have existing projects using npm or yarn:

```bash
# Remove old lock files
rm package-lock.json yarn.lock

# Generate pnpm lockfile
pnpm install

# Update scripts if needed (usually no changes needed)
# npm run dev  →  pnpm dev
# npm install  →  pnpm install
```

## Additional Notes

- **mise** manages pnpm versions globally
- Global packages installed to: `~/.local/share/pnpm/global/5/node_modules`
- Store location: `~/.local/share/pnpm/store/v10`
- Configuration is XDG-compliant: `~/.config/pnpm/rc`
