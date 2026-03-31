# Complete Git + GitLab + SSO Setup Tutorial

This tutorial addresses the complete setup of Git with GitLab using Single Sign-On (SSO). We'll explore SSH key authentication, credential management, and common troubleshooting scenarios.

## Prerequisites

- Git installed on your system
- Access to a GitLab instance
- Basic command line familiarity
- Administrative access to add SSH keys to your GitLab account

## The Authentication Challenge

GitLab environments with SSO present unique challenges. Traditional username/password authentication becomes cumbersome when combined with multi-factor authentication and session timeouts. SSH keys provide a more elegant solution - but the setup requires methodical attention to detail.

## Part 1: SSH Key Setup

### Step 1: Generate SSH Key Pair

First, let's generate a modern, secure SSH key. The choice of algorithm matters here - ED25519 offers better security and performance than older RSA keys.

```bash
# Generate ED25519 key (recommended)
ssh-keygen -t ed25519 -C "your.email@example.com"

# Alternative: RSA key (if ED25519 not supported)
ssh-keygen -t rsa -b 4096 -C "your.email@example.com"
```

**Interactive prompts:**
- **File location**: Press Enter for default (`~/.ssh/id_ed25519`)
- **Passphrase**: Choose a secure passphrase or leave empty for convenience

### Step 2: Configure SSH Agent

The SSH agent manages your keys and handles authentication automatically.

```bash
# Start SSH agent (if not running)
eval "$(ssh-agent -s)"

# Add your private key to the agent
ssh-add ~/.ssh/id_ed25519

# Verify keys are loaded
ssh-add -l
```

**For persistent SSH agent (optional):**

```bash
# Add to your shell profile (.bashrc, .zshrc, etc.)
if [ -z "$SSH_AUTH_SOCK" ]; then
   eval "$(ssh-agent -s)"
   ssh-add ~/.ssh/id_ed25519
fi
```

### Step 3: Add Public Key to GitLab

```bash
# Copy public key to clipboard
# On Windows:
clip < ~/.ssh/id_ed25519.pub

# On macOS:
pbcopy < ~/.ssh/id_ed25519.pub

# On Linux:
cat ~/.ssh/id_ed25519.pub
# Copy the output manually
```

**In GitLab:**
1. Navigate to **Profile Settings** → **SSH Keys**
2. Paste your public key
3. Add a descriptive title (e.g., "Work Laptop - 2025")
4. Set expiration date (optional but recommended)
5. Click **Add Key**

### Step 4: Test SSH Connection

```bash
# Test connection to GitLab
ssh -T git@gitlab.example.com

# Expected response:
# Welcome to GitLab, @username!
```

## Part 2: Repository Configuration

### Convert Existing Repository from HTTPS to SSH

If you already have a repository using HTTPS authentication:

```bash
# Check current remote URL
git remote -v

# Change to SSH URL
git remote set-url origin git@gitlab.example.com:username/repository.git

# Verify the change
git remote -v
```

### Clone New Repository with SSH

```bash
# Clone using SSH URL
git clone git@gitlab.example.com:username/repository.git

# Navigate to repository
cd repository
```

### Global Git Configuration for SSH

Set SSH as default for your GitLab instance:

```bash
# Replace HTTPS URLs with SSH automatically
git config --global url."git@gitlab.example.com:".insteadOf "https://gitlab.example.com/"

# Set your identity
git config --global user.name "Your Name"
git config --global user.email "your.email@example.com"
```

## Part 3: Handling Divergent Branches

### Understanding Divergent Branches

Divergent branches occur when:
- Local and remote branches have different commit histories
- Both branches contain commits the other lacks
- Git cannot determine how to merge them automatically

### Configure Pull Strategy

```bash
# Set default merge strategy (recommended for most workflows)
git config --global pull.rebase false

# Alternative: Set rebase strategy (creates linear history)
git config --global pull.rebase true

# Alternative: Fast-forward only (strict, prevents divergence)
git config --global pull.ff only
```

### Resolving Divergent Branches

**Scenario 1: Safe Merge Approach**
```bash
# Merge remote changes with local changes
git pull origin main --no-rebase

# If histories are unrelated (common with new repositories)
git pull origin main --no-rebase --allow-unrelated-histories
```

**Scenario 2: Linear History with Rebase**
```bash
# Rebase local commits onto remote
git pull origin main --rebase

# Handle conflicts if they arise
git rebase --continue  # after resolving conflicts
git rebase --abort     # to cancel rebase
```

**Scenario 3: Reset to Remote (Destructive)**
```bash
# WARNING: This discards local commits
git fetch origin
git reset --hard origin/main
```

## Part 4: Workflow Best Practices

### Branch Strategy Recommendations

**For Individual Development:**
- Use merge strategy (`pull.rebase = false`)
- Preserves complete history
- Safer for beginners

**For Team Development:**
- Consider rebase strategy (`pull.rebase = true`)
- Creates cleaner, linear history
- Requires more Git knowledge

### Common Commands Reference

```bash
# Daily workflow
git status              # Check repository status
git add .               # Stage all changes
git commit -m "message" # Commit with message
git push origin main    # Push to remote
git pull origin main    # Pull from remote

# Branch management
git branch              # List branches
git checkout -b feature # Create and switch to branch
git merge feature       # Merge branch into current
git branch -d feature   # Delete branch

# Troubleshooting
git log --oneline --graph --all  # Visualize commit history
git remote -v                    # Check remote URLs
git config --list                # View all Git configuration
```

## Part 5: Troubleshooting Common Issues

### SSH Connection Failures

**Problem**: `Permission denied (publickey)`

**Solutions**:
```bash
# Verify SSH agent is running
ssh-add -l

# Re-add key to agent
ssh-add ~/.ssh/id_ed25519

# Test with verbose output
ssh -vT git@gitlab.example.com

# Check key permissions
chmod 700 ~/.ssh
chmod 600 ~/.ssh/id_ed25519
chmod 644 ~/.ssh/id_ed25519.pub
```

### Network Issues

**Problem**: SSH blocked by firewall

**Solutions**:
```bash
# Try SSH over HTTPS port (443)
ssh -T -p 443 git@ssh.gitlab.example.com

# Configure SSH to use HTTPS port
# Add to ~/.ssh/config:
Host gitlab.example.com
    Hostname ssh.gitlab.example.com
    Port 443
    User git
```

### Authentication Still Prompting

**Problem**: Git still asks for username/password

**Causes & Solutions**:
1. **Repository still using HTTPS URL**
   ```bash
   git remote set-url origin git@gitlab.example.com:user/repo.git
   ```

2. **SSH key not in agent**
   ```bash
   ssh-add ~/.ssh/id_ed25519
   ```

3. **Wrong remote URL format**
   ```bash
   # Correct format:
git@gitlab.example.com:username/repository.git
# Not:
https://gitlab.example.com/username/repository.git
   ```

## Part 6: Advanced Configuration

### SSH Config File

Create `~/.ssh/config` for advanced SSH settings:

```bash
# Primary GitLab
Host gitlab.example.com
    HostName gitlab.example.com
    User git
    IdentityFile ~/.ssh/id_ed25519_primary
    IdentitiesOnly yes

# Personal GitLab
Host gitlab.com
    HostName gitlab.com
    User git
    IdentityFile ~/.ssh/id_ed25519_personal
    IdentitiesOnly yes
```

### Multiple SSH Keys Management

```bash
# Generate separate keys for different accounts
ssh-keygen -t ed25519 -f ~/.ssh/id_ed25519_primary -C "primary@example.com"
ssh-keygen -t ed25519 -f ~/.ssh/id_ed25519_personal -C "personal@example.com"

# Add both keys to agent
ssh-add ~/.ssh/id_ed25519_primary
ssh-add ~/.ssh/id_ed25519_personal
```

### Git Aliases for Efficiency

```bash
# Useful Git aliases
git config --global alias.st status
git config --global alias.co checkout
git config --global alias.br branch
git config --global alias.cm commit
git config --global alias.pl "pull origin"
git config --global alias.ps "push origin"
git config --global alias.lg "log --oneline --graph --all"
```

## Security Considerations

### Key Security Best Practices

1. **Use passphrases** on SSH keys when possible
2. **Set expiration dates** on GitLab SSH keys
3. **Regularly rotate keys** (annually recommended)
4. **Remove old keys** from GitLab when no longer needed
5. **Use separate keys** for different accounts and services
6. **Store keys securely** and never share private keys

### Backup and Recovery

```bash
# Backup SSH keys (store securely)
cp ~/.ssh/id_ed25519* /secure/backup/location/

# Restore SSH keys
cp /secure/backup/location/id_ed25519* ~/.ssh/
chmod 600 ~/.ssh/id_ed25519
chmod 644 ~/.ssh/id_ed25519.pub
```

## Conclusion

This tutorial provides a systematic approach to Git and GitLab authentication with an emphasis on:

- **Security-first approach** with SSH key authentication
- **Workflow optimization** through proper configuration
- **Troubleshooting preparedness** for common scenarios
- **Scalable practices** for team environments

Each organization has unique requirements, network configurations, and security policies. The approaches outlined here should be adapted to fit your specific context.

### Next Steps

1. Implement SSH key authentication
2. Configure your preferred pull strategy
3. Establish consistent workflow patterns
4. Document your team's specific procedures
5. Regularly review and update security practices

Remember: these configurations are starting points for exploration, not rigid prescriptions. Your specific environment may require adaptations or alternative approaches.
