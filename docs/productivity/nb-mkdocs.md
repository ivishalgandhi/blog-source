---
id: nb-mkdocs
title: Setting up MkDocs with NB Notes
sidebar_label: NB with MkDocs
sidebar_position: 2
---

# Setting up MkDocs with NB Notes

This tutorial shows how to install MkDocs using `uv` to browse your NB notes through a web interface with proper tree navigation.

## Overview

[NB](https://github.com/xwmx/nb) is a powerful command-line note-taking tool that allows you to create, edit, and manage your notes directly from the terminal. When combined with a static site generator like MkDocs or Docusaurus, it creates a powerful knowledge management system that brings your terminal notes to the web.

The key benefits of this combination:
- **Command-line efficiency**: Capture notes quickly with NB's terminal interface
- **Web accessibility**: Browse, search, and share your notes through a beautiful web interface
- **Markdown support**: Write in Markdown and see it beautifully rendered
- **Version control**: NB uses Git under the hood, giving you full history of your notes

## Prerequisites

- Linux-based system
- NB notes stored at `~/.nb/work` (or any other path)
- `uv` package manager installed

## Step 1: Install UV (if not already installed)

```bash
curl -LsSf https://astral.sh/uv/install.sh | sh
source $HOME/.cargo/env
```

## Step 2: Create MkDocs Project Directory

```bash
# Create a project directory for MkDocs configuration
mkdir ~/mkdocs-nb
cd ~/mkdocs-nb

# Initialize uv project
uv init
```

## Step 3: Install MkDocs with Material Theme

```bash
# Use uv to install MkDocs and the Material theme
uv pip install mkdocs mkdocs-material
```

If you prefer using a virtual environment:

```bash
# Create and activate a virtual environment
uv venv
source .venv/bin/activate
uv pip install mkdocs mkdocs-material
```

## Step 4: Create Symlink to Your Notes

```bash
# From your mkdocs project directory
cd ~/mkdocs-nb

# Create symlink to your NB notes directory
ln -s ~/.nb/work docs
```

If your notes are in a different location, replace `~/.nb/work` with your actual notes path:
```bash
ln -s /path/to/your/notes docs
```

## Step 5: Configure MkDocs

Create the `mkdocs.yml` configuration file:

```bash
cat > mkdocs.yml << 'EOF'
site_name: My NB Work Notes
docs_dir: docs

theme:
  name: material
  features:
    - navigation.sections
    - navigation.expand
    - navigation.indexes
    - navigation.instant
    - navigation.tracking
    - search.highlight
    - search.share
    - toc.follow
    - toc.integrate
  palette:
    - scheme: default
      primary: indigo
      accent: indigo

markdown_extensions:
  - toc:
      permalink: true
  - codehilite
  - admonition
  - pymdownx.details
  - pymdownx.superfences

dev_addr: '0.0.0.0:8000'

plugins:
  - search
EOF
```

### Key Configuration Features:

- **`navigation.sections`**: Groups pages into sections
- **`navigation.expand`**: Expands all navigation sections by default  
- **`navigation.indexes`**: Allows folders to have index pages
- **`toc.integrate`**: Integrates table of contents into navigation
- **`dev_addr: '0.0.0.0:8000'`**: Allows access from other devices on your network

## Step 6: Run MkDocs Server

```bash
mkdocs serve --dev-addr 0.0.0.0:8000
```

You should see output like:
```
INFO     -  Building documentation...
INFO     -  Cleaning site directory
INFO     -  Documentation built in 0.XX seconds
INFO     -  [HH:MM:SS] Serving on http://0.0.0.0:8000/
```

## Step 7: Access Your Notes

- **From your machine**: `http://localhost:8000`
- **From other devices on network**: 
  1. Find your IP address: `ip addr show` or `hostname -I`
  2. Access: `http://YOUR_IP:8000`

## Features You Get

✅ **Tree Navigation**: Folders appear as expandable sections in left sidebar  
✅ **Live Reload**: Changes to notes automatically refresh the page  
✅ **Search**: Full-text search across all your notes  
✅ **Material Design**: Modern, responsive interface  
✅ **Syntax Highlighting**: Code blocks are properly highlighted  

## Troubleshooting

### UV Command Not Found

```bash
# Make sure you've sourced the environment
source $HOME/.cargo/env

# Or use full path
$HOME/.cargo/bin/uv pip install mkdocs mkdocs-material
```

### Permission Denied Errors

Use virtual environment instead of system-wide installation:
```bash
uv venv
source .venv/bin/activate
uv pip install mkdocs mkdocs-material
```

### Navigation Showing as Tabs Instead of Tree

Make sure you **don't** have `navigation.tabs` in your theme features. The configuration above excludes this intentionally.

## Optional: Enhanced Plugins

For more advanced navigation control, install additional plugins:

```bash
# Install awesome-pages plugin for better folder organization
uv pip install mkdocs-awesome-pages-plugin
```

Then add to your `mkdocs.yml`:
```yaml
plugins:
  - search
  - awesome-pages:
      filename: .pages
      collapse_single_pages: false
      strict: false
```

## Project Structure

Your final project structure should look like:
```
~/mkdocs-nb/
├── docs -> ~/.nb/work (symlink)
├── mkdocs.yml
└── site/ (generated when building)
```

## Alternative: Using Docusaurus

MkDocs is excellent for documentation, but if you need a more blog-like experience, [Docusaurus](https://docusaurus.io/) is an excellent alternative:

```bash
# Install Node.js if not already installed
# Create a new Docusaurus site
npx create-docusaurus@latest my-nb-site classic

# Create symlink to your notes
cd my-nb-site
ln -s ~/.nb/work docs

# Configure Docusaurus to use your notes directory
# Edit docusaurus.config.js to point to your notes
```

## Usage Tips

1. **Continue using NB**: Keep taking notes with NB as usual - changes will appear automatically in the web interface
2. **Organize with folders**: Your folder structure in NB will be reflected in the navigation tree
3. **Search everything**: Use the search box to quickly find content across all notes
4. **Mobile friendly**: The Material theme works well on mobile devices too
5. **Deploy to the web**: Consider deploying your MkDocs site to GitHub Pages or Netlify to access your notes from anywhere

---

**Next time you need this setup**: Just run `mkdocs serve --dev-addr 0.0.0.0:8000` from your `~/mkdocs-nb` directory!
