---
sidebar_position: 1
title: Managing Passwords with Pass
description: A comprehensive guide to using Pass, the standard Unix password manager
---

# Managing Passwords with Pass

Pass is the standard Unix password manager that follows the Unix philosophy: do one thing and do it well. It stores passwords as GPG-encrypted files in a simple directory structure and integrates seamlessly with Git for synchronization across machines.

## Why Pass?

- **Simple and transparent**: Passwords are just encrypted files in a directory
- **Git integration**: Built-in version control and sync across devices
- **GPG encryption**: Industry-standard encryption you can trust
- **Cross-platform**: Works on macOS, Linux, BSD, and Windows (via WSL)
- **CLI-first**: Perfect for terminal users and automation
- **Extensible**: Large ecosystem of extensions and integrations

## Installation

### macOS

```bash
brew install pass gnupg
```

### Linux (Ubuntu/Debian)

```bash
sudo apt install pass gnupg
```

### Linux (Fedora/RHEL)

```bash
sudo dnf install pass gnupg
```

## Initial Setup

### Step 1: Create a GPG Key

If you don't already have a GPG key, create one:

```bash
gpg --full-generate-key
```

Follow the prompts:
- Choose **RSA and RSA** (default)
- Key size: **4096 bits**
- Expiration: **0** (doesn't expire) or your preference
- Enter your **name** and **email**
- Create a **strong passphrase** (this is your master password!)

Verify your key was created:

```bash
gpg --list-keys
```

Note the email address associated with your key.

### Step 2: Initialize Pass

```bash
pass init "your-email@example.com"
```

This creates `~/.password-store/` and initializes it with your GPG key.

### Step 3: Set Up Git Sync (Optional but Recommended)

```bash
# Initialize git in the password store
pass git init

# Add your remote repository
pass git remote add origin git@github.com:yourusername/password-store.git

# Push to remote
pass git push -u origin main
```

:::tip
Create a **private repository** on GitHub, GitLab, or your preferred Git hosting service before adding the remote.
:::

## Basic Usage

### Storing Passwords

```bash
# Add a password (you'll be prompted to enter it)
pass insert personal/github

# Add a password with multiple lines (for notes, security questions, etc.)
pass insert -m work/aws-console

# Generate a random password
pass generate personal/netflix 24
```

### Retrieving Passwords

```bash
# Display a password in the terminal
pass personal/github

# Copy password to clipboard (clears after 45 seconds)
pass -c personal/github

# List all passwords
pass

# Search for passwords
pass find github
```

### Organizing Passwords

Pass uses a hierarchical directory structure:

```
~/.password-store/
├── personal/
│   ├── github.gpg
│   ├── netflix.gpg
│   └── email/
│       └── gmail.gpg
├── work/
│   ├── aws-console.gpg
│   └── slack.gpg
└── banking/
    └── chase.gpg
```

You can organize however makes sense to you!

### Editing and Managing

```bash
# Edit an existing password
pass edit personal/github

# Remove a password
pass rm old/unused-service

# Move/rename a password
pass mv old-name new-name

# Copy a password entry
pass cp personal/github work/github-work
```

## Syncing Across Machines

### On Your First Machine

```bash
# After making changes, push to remote
pass git push
```

Every time you insert, edit, or remove a password, Pass automatically commits the change. You just need to push.

### Setting Up on Additional Machines

1. **Install Pass and GPG** (as shown in Installation section)

2. **Import your GPG key** from your first machine:

   On the first machine, export your key:
   ```bash
   gpg --export-secret-keys your-email@example.com > gpg-private-key.asc
   gpg --export-ownertrust > gpg-ownertrust.asc
   ```

   Transfer these files securely to the new machine, then import:
   ```bash
   gpg --import gpg-private-key.asc
   gpg --import-ownertrust gpg-ownertrust.asc
   
   # Clean up the key files
   rm gpg-private-key.asc gpg-ownertrust.asc
   ```

3. **Clone your password store**:
   ```bash
   git clone git@github.com:yourusername/password-store.git ~/.password-store
   ```

4. **Test it works**:
   ```bash
   pass
   pass -c personal/github
   ```

### Daily Sync Workflow

```bash
# Pull latest changes before working
pass git pull

# After making changes
pass git push
```

## Advanced Features

### Generating Strong Passwords

```bash
# Generate 32-character password with symbols
pass generate service/account 32

# Generate without symbols (alphanumeric only)
pass generate -n service/account 20

# Generate and don't show on screen
pass generate -c service/account 24
```

### Multi-line Entries

Pass supports storing more than just passwords:

```bash
pass insert -m banking/account
```

Then enter:
```
MySecurePassword123
Username: john.doe
Account Number: 1234-5678-9012
Security Question: What is your pet's name?
Answer: Fluffy
```

The first line is always treated as the password, and `pass -c` will only copy that line.

### Using Pass with Multiple GPG Keys

If you want to encrypt for multiple GPG keys (e.g., team password sharing):

```bash
pass init key-id-1 key-id-2 key-id-3
```

### Temporary Password Display

```bash
# Show password for 45 seconds, then clear terminal
pass show -c 45 service/account
```

## Shell Integration

### Bash Completion

Add to `~/.bashrc`:

```bash
source /usr/share/bash-completion/completions/pass
```

### Zsh Completion

Add to `~/.zshrc`:

```bash
autoload -U compinit && compinit
source /usr/share/zsh/site-functions/_pass
```

### Fish Completion

Usually works out of the box. If not:

```bash
cp /usr/share/fish/vendor_completions.d/pass.fish ~/.config/fish/completions/
```

## Security Best Practices

### 1. Strong GPG Passphrase

Your GPG passphrase is your master password. Make it:
- At least 20 characters
- A mix of words, numbers, and symbols
- Something memorable but not guessable

### 2. Backup Your GPG Key

```bash
# Export your private key
gpg --export-secret-keys your-email@example.com > gpg-backup.asc

# Export trust settings
gpg --export-ownertrust > gpg-trust-backup.asc
```

Store these files:
- On an encrypted USB drive
- In a secure cloud storage (encrypted)
- In a physical safe

Then delete them from your computer:
```bash
rm gpg-backup.asc gpg-trust-backup.asc
```

### 3. Use a Private Git Repository

Always use a **private** repository for your password store, even though passwords are encrypted.

### 4. Regular Git Pushes

Push changes regularly to avoid losing passwords:

```bash
# Add an alias for convenience
echo 'alias psync="pass git pull && pass git push"' >> ~/.bashrc
```

### 5. Never Store GPG Keys in Git

Do not commit your GPG private key to your password store repository. Export and store it separately.

## Troubleshooting

### "gpg: decryption failed: No secret key"

Your password was encrypted with a different GPG key. Either:
- Import the correct GPG key
- Re-encrypt with your current key: `pass init your-email@example.com` 

### "fatal: not a git repository"

Initialize git in your password store:

```bash
pass git init
```

### GPG Agent Timeout

If GPG keeps asking for your passphrase, configure the timeout:

Edit `~/.gnupg/gpg-agent.conf`:

```
default-cache-ttl 34560000
max-cache-ttl 34560000
```

Reload the agent:

```bash
gpg-connect-agent reloadagent /bye
```

### Merge Conflicts

If you edit passwords on multiple machines without syncing:

```bash
pass git pull
# If conflicts occur
cd ~/.password-store
git status
# Manually resolve conflicts, then:
git add .
git commit -m "Resolve merge conflicts"
pass git push
```

## Browser Integration

### PassFF (Firefox)

Install the [PassFF extension](https://addons.mozilla.org/en-US/firefox/addon/passff/) and the native host:

```bash
# Install the host application
curl -sSL https://github.com/passff/passff-host/releases/latest/download/install_host_app.sh | bash -s -- firefox
```

### browserpass (Chrome/Firefox)

Install [browserpass](https://github.com/browserpass/browserpass-extension) for auto-fill support.

## Mobile Apps

### Android: Password Store

[Password Store](https://github.com/android-password-store/Android-Password-Store) is the official Android app with Git sync support.

### iOS: Pass for iOS

[Pass for iOS](https://mssun.github.io/passforios/) provides pass functionality on iPhone and iPad.

## Tips and Tricks

### Quick Clipboard Copy

Create an alias for frequently used passwords:

```bash
alias github-pass='pass -c personal/github'
```

### OTP Support

Install the [pass-otp extension](https://github.com/tadfisher/pass-otp) for 2FA codes:

```bash
# Add a TOTP secret
pass otp add service/account

# Generate OTP code
pass otp service/account
```

### Team Password Sharing

Initialize with multiple GPG keys:

```bash
pass init alice@example.com bob@example.com charlie@example.com
```

Everyone with their private key can decrypt the passwords.

### Password History

Since Pass uses Git, you can view password history:

```bash
pass git log personal/github
pass git show <commit-hash>:personal/github.gpg | gpg -d
```

### Import from Other Password Managers

Many import scripts exist in the [pass contrib repository](https://git.zx2c4.com/password-store/tree/contrib/importers).

Example for LastPass:

```bash
./lastpass2pass.rb export.csv
```

## Further Reading

- [Official Pass Website](https://www.passwordstore.org/)
- [Pass GitHub Repository](https://git.zx2c4.com/password-store/)
- [Pass Extensions](https://www.passwordstore.org/#extensions)
- [GPG Documentation](https://gnupg.org/documentation/)

---

Pass follows the Unix philosophy perfectly: simple, composable, and transparent. Once you get used to the workflow, it becomes second nature and integrates beautifully into a terminal-based workflow.
