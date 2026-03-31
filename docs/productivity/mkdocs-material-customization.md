---
id: mkdocs-material-customization
title: Customizing MkDocs Material Theme
sidebar_label: MkDocs Customization
sidebar_position: 4
---

# Customizing MkDocs Material Theme

This tutorial explains how to customize your MkDocs Material theme to implement full-width layout, integrate FontAwesome icons, and apply GitLab's exact font styling and branding.

## Full-Width Layout

By default, MkDocs Material has a fixed-width layout. Here's how to make it full-width:

### Method 1: Using Theme Overrides (Recommended)

1. Create a directory structure for overrides:

```bash
mkdir -p overrides
```

2. Create a `main.html` file in the overrides directory:

```bash
touch overrides/main.html
```

3. Add the following content to `main.html`:

```html
{% extends "base.html" %}

{% block styles %}
    {{ super() }}
    <style>
        /* Full-width layout */
        .md-grid {
            max-width: 100% !important;
        }
        .md-main__inner {
            max-width: none !important;
        }
        .md-content {
            max-width: none !important;
        }
        .md-sidebar {
            width: 12.1rem;
        }
        .md-sidebar--secondary {
            margin-left: 0;
            transform: none;
        }
    </style>
{% endblock %}
```

4. Update your `mkdocs.yml` file to use the custom theme directory:

```yaml
theme:
  name: material
  custom_dir: overrides
```

### Method 2: Using Custom CSS

1. Create a directory for custom stylesheets:

```bash
mkdir -p stylesheets
```

2. Create a CSS file:

```bash
touch stylesheets/extra.css
```

3. Add the following CSS rules:

```css
.md-grid {
    max-width: 100% !important;
}
.md-main__inner {
    max-width: none !important;
}
.md-content {
    max-width: none !important;
}
.md-sidebar {
    width: 12.1rem;
}
.md-sidebar--secondary {
    margin-left: 0;
    transform: none;
}
```

4. Update your `mkdocs.yml` file to include the custom CSS:

```yaml
theme:
  name: material
  custom_dir: overrides
extra_css:
  - stylesheets/extra.css
```

## FontAwesome Integration

### Method 1: Using CDN (Recommended)

1. Update your `overrides/main.html` file to include FontAwesome:

```html
{% extends "base.html" %}

{% block styles %}
    {{ super() }}
    <style>
        /* Full-width layout styles here */
    </style>
{% endblock %}

{% block extrahead %}
    {{ super() }}
    <!-- FontAwesome integration - using the newer version from CDN -->
    <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.4.2/css/all.min.css" 
          integrity="sha512-z3gLpd7yknf1YoNbCzqRKc4qyor8gaKU1qmn+CShxbuBusANI9QpRohGBreCFkKxLhei6S9CQXFEbbKuqLg0DA==" 
          crossorigin="anonymous" referrerpolicy="no-referrer" />
{% endblock %}
```

2. Now you can use FontAwesome icons in your markdown files:

```markdown
<i class="fas fa-check"></i> This is a checked item
<i class="fab fa-gitlab"></i> GitLab icon
```

### Method 2: Using Material's Built-in Emoji Support

1. Update your `mkdocs.yml` file:

```yaml
markdown_extensions:
  - pymdownx.emoji:
      emoji_index: !!python/name:material.extensions.emoji.twemoji
      emoji_generator: !!python/name:material.extensions.emoji.to_svg
      options:
        custom_icons:
          - overrides/.icons
```

2. Create a directory for custom icons:

```bash
mkdir -p overrides/.icons
```

3. Download FontAwesome SVG icons and place them in the `.icons` directory.

4. Use the icons in your markdown:

```markdown
:fontawesome-solid-check: This is a checked item
:fontawesome-brands-gitlab: GitLab icon
```

## Custom Fonts and Branding (Exact GitLab Style)

To exactly match GitLab's font style, we'll use the actual GitLab Sans and GitLab Mono fonts directly from GitLab's font repository:

1. Update your `overrides/main.html` file with these exact typography settings:

```html
{% extends "base.html" %}

{% block styles %}
    {{ super() }}
    <style>
        /* Full-width layout styles */
        
        /* GitLab Font Integration */
        :root {
            --md-text-font: "GitLab Sans", "Inter", "Helvetica Neue", Helvetica, Arial, sans-serif;
            --md-code-font: "GitLab Mono", "SFMono-Regular", Consolas, "Liberation Mono", Menlo, Courier, monospace;
            --gitlab-purple: #6e49cb;
            --gitlab-heading-color: #292961;
            --gitlab-link-color: #1068bf;
        }
        
        body {
            font-family: var(--md-text-font);
            font-size: 16px;
            -webkit-font-smoothing: antialiased;
            -moz-osx-font-smoothing: grayscale;
            color: #1f1e25;
        }
        
        h1, h2, h3, h4, h5, h6 {
            font-family: var(--md-text-font);
            font-weight: 700;
            letter-spacing: -0.025em; /* Matches GitLab's heading spacing */
            line-height: 1.2; /* Matches GitLab's heading line height */
            color: var(--gitlab-heading-color);
        }
        
        .md-typeset h1 {
            font-weight: 700;
            font-size: 2.5rem;
            margin-bottom: 1.5rem;
        }
        
        .md-typeset h2 {
            font-weight: 700;
            font-size: 1.75rem;
            margin-top: 2rem;
            margin-bottom: 1rem;
        }
        
        .md-typeset h3 {
            font-weight: 600;
            font-size: 1.375rem;
        }
        
        .md-typeset p, .md-typeset ul, .md-typeset ol {
            font-weight: 400;
            line-height: 1.6; /* Matches GitLab's body text line height */
            letter-spacing: -0.01em;
            margin-bottom: 1rem;
        }
        
        .md-typeset a {
            font-weight: 500; /* Medium for links */
            color: var(--gitlab-link-color);
            text-decoration: none;
        }
        
        .md-typeset a:hover {
            text-decoration: underline;
        }
        
        .md-nav__link {
            font-weight: 500;
        }
        
        .md-typeset button, .md-typeset .md-button {
            font-weight: 600; /* SemiBold for buttons */
        }
        
        code, pre, .md-typeset code {
            font-family: var(--md-code-font);
            font-size: 0.9em;
            background-color: #fafafa;
            border-radius: 3px;
            padding: 0.2em 0.4em;
        }
        
        .md-typeset pre > code {
            padding: 1em;
            background-color: #f5f5f5;
            border: 1px solid #e1e4e8;
        }

        /* Match GitLab's primary color for theme elements */
        .md-header {
            background-color: var(--gitlab-purple);
        }

        .md-tabs {
            background-color: var(--gitlab-purple);
        }

        /* Improve navigation styling */
        .md-nav__title {
            font-family: var(--md-text-font);
            font-weight: 600;
        }
    </style>
{% endblock %}

{% block extrahead %}
    {{ super() }}
    <!-- Theme color meta tags (from GitLab handbook) -->
    <meta name="theme-color" content="#6e49cb">
    <meta name="theme-color" content="#6e49cb" media="(prefers-color-scheme: light)">
    <meta name="theme-color" content="#6e49cb" media="(prefers-color-scheme: dark)">
    
    <!-- Favicon configuration (matching GitLab handbook) -->
    <link rel="shortcut icon" href="{{ base_url }}/assets/images/favicon-32x32.ico">
    <link rel="icon" type="image/png" href="{{ base_url }}/assets/images/favicon-16x16.png" sizes="16x16">
    <link rel="icon" type="image/png" href="{{ base_url }}/assets/images/favicon-32x32.png" sizes="32x32">
    <link rel="apple-touch-icon" href="{{ base_url }}/assets/images/favicon-192x192.png">
    
    <!-- FontAwesome integration - using the newer version from CDN -->
    <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.4.2/css/all.min.css" 
          integrity="sha512-z3gLpd7yknf1YoNbCzqRKc4qyor8gaKU1qmn+CShxbuBusANI9QpRohGBreCFkKxLhei6S9CQXFEbbKuqLg0DA==" 
          crossorigin="anonymous" referrerpolicy="no-referrer" />
    
    <!-- GitLab Sans font - direct from GitLab's font repository -->
    <link rel="stylesheet" href="https://gitlab-org.gitlab.io/frontend/fonts/dist/gitlab-sans.css">
    
    <!-- GitLab Mono font -->
    <link rel="stylesheet" href="https://gitlab-org.gitlab.io/frontend/fonts/dist/gitlab-mono.css">
    
    <!-- Add Inter font as fallback for GitLab Sans -->
    <link rel="preconnect" href="https://fonts.googleapis.com">
    <link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
    <link href="https://fonts.googleapis.com/css2?family=Inter:wght@400;500;600;700&display=swap" rel="stylesheet">
{% endblock %}
```

## Favicon Configuration

To match GitLab's favicon setup:

1. Create a directory for your favicon files:

```bash
mkdir -p assets/images
```

2. Download the GitLab favicon files from the GitLab handbook or use your own brand's favicons:

```bash
# Download favicon files (example using curl)
curl -s https://handbook.gitlab.com/favicons/favicon-16x16.png --output assets/images/favicon-16x16.png
curl -s https://handbook.gitlab.com/favicons/favicon-32x32.png --output assets/images/favicon-32x32.png
curl -s https://handbook.gitlab.com/favicons/favicon-32x32.ico --output assets/images/favicon-32x32.ico
curl -s https://handbook.gitlab.com/favicons/favicon-192x192.png --output assets/images/favicon-192x192.png
```

3. The favicon configuration is already included in the `main.html` template shown above.

## Theme Color Configuration

To match GitLab's theme color in browsers:

1. Add the following meta tags to your `main.html` file in the `extrahead` block (already included in the template above):

```html
<!-- Theme color meta tags (from GitLab handbook) -->
<meta name="theme-color" content="#6e49cb">
<meta name="theme-color" content="#6e49cb" media="(prefers-color-scheme: light)">
<meta name="theme-color" content="#6e49cb" media="(prefers-color-scheme: dark)">
```

## Navigation Collapse Configuration

By default, MkDocs Material might automatically expand some navigation sections, especially if you're using features like `navigation.indexes` or `navigation.sections`. To ensure all navigation folders are collapsed by default:

1. Update your `mkdocs.yml` file to control the navigation collapse state:

```yaml
theme:
  name: material
  features:
    - navigation.instant
    - navigation.tracking
    # Remove navigation.sections and navigation.indexes to prevent auto-expansion
    - content.code.annotate
    - content.tabs.link
  
  # Control navigation collapse state explicitly
  collapse_navigation: true
```

2. If you have index files in your documentation folders (like `index.md` or similar), they can sometimes cause automatic expansion. Consider using standard naming conventions for your index files.

3. For more granular control, you can define a custom navigation structure using the `nav` section in your `mkdocs.yml` file.

## Complete Example

Here's a complete example of `mkdocs.yml`:

```yaml
site_name: My Documentation
site_url: https://example.com/
docs_dir: docs

theme:
  name: material
  custom_dir: overrides
  icon:
    logo: fontawesome/brands/gitlab
  palette:
    primary: indigo
    accent: indigo

markdown_extensions:
  - pymdownx.emoji:
      emoji_index: !!python/name:material.extensions.emoji.twemoji
      emoji_generator: !!python/name:material.extensions.emoji.to_svg

extra_css:
  - stylesheets/extra.css

extra_javascript:
  - javascripts/extra.js
```

## GitLab Repository Integration

Integrating your MkDocs site with GitLab allows users to view repository information and edit documents directly from the documentation site. This creates a seamless workflow between documentation and code.

### Adding GitLab Repository Link

1. First, add your GitLab repository URL to the `mkdocs.yml` configuration:

```yaml
repo_url: https://gitlab.com/your-username/your-repository
repo_name: your-username/your-repository
```

2. Customize the repository icon to use the GitLab logo:

```yaml
theme:
  name: material
  icon:
    repo: fontawesome/brands/gitlab
```

### Enable Edit Button Integration

To enable the "Edit this page" button that links directly to the GitLab editor:

1. Configure the edit URI in your `mkdocs.yml` file:

```yaml
edit_uri: edit/main/docs/
```

Note: If your default branch is not `main`, replace it with your branch name (e.g., `master`). Also ensure the path to your documentation directory is correct.

2. Enable the edit button feature:

```yaml
theme:
  name: material
  features:
    - content.action.edit
```

3. Optionally customize the edit icon:

```yaml
theme:
  icon:
    edit: material/pencil
```

### Document Revision Information

To display when documents were last updated and who contributed to them:

1. Install the git revision date plugin:

```bash
pip install mkdocs-git-revision-date-localized-plugin
```

2. Configure the plugin in your `mkdocs.yml`:

```yaml
plugins:
  - git-revision-date-localized:
      enable_creation_date: true
      type: date
```

3. For showing contributors, install the git committers plugin:

```bash
pip install mkdocs-git-committers-plugin-2
```

4. Add to your configuration:

```yaml
plugins:
  - git-committers:
      repository: your-username/your-repository
      branch: main
```

### Complete Example with GitLab Integration

Here's a comprehensive example for GitLab integration:

```yaml
site_name: Your Documentation
site_url: https://your-documentation-url.com/
docs_dir: docs

# GitLab repository configuration
repo_url: https://gitlab.com/your-username/your-repository
repo_name: your-username/your-repository
edit_uri: edit/main/docs/

theme:
  name: material
  custom_dir: overrides
  features:
    - navigation.instant
    - navigation.tracking
    - content.action.edit  # Enable edit button
  icon:
    repo: fontawesome/brands/gitlab
    edit: material/pencil

plugins:
  - search
  - git-revision-date-localized:
      enable_creation_date: true
      type: date
  - git-committers:
      repository: your-username/your-repository
      branch: main
```

This configuration creates a fully integrated documentation site with GitLab, showing repository information, enabling direct editing of pages, and displaying document history.

> **Further Reading:** For an in-depth tutorial on building and deploying a centralized documentation site using MkDocs and GitLab, see [Documentation as Code: How to Build & Deploy a Centralised Documentation Site using MkDocs & GitLab](https://medium.com/@harryalexdunn/documentation-as-code-how-to-build-deploy-a-centralised-documentation-site-using-mkdocs-gitlab-2dc86e071bd0).

## Troubleshooting

### CSS Not Loading

If your custom CSS is not loading:

1. Check browser console for 404 errors
2. Verify file paths are correct
3. Make sure `mkdocs.yml` has the correct paths
4. Try clearing browser cache

### FontAwesome Icons Not Showing

1. Check if the FontAwesome CSS is loading (browser console)
2. Verify icon class names are correct (e.g., `fa-solid fa-check` instead of just `fa-check`)
3. Make sure you're using the correct icon prefix (`fa-solid`, `fa-regular`, `fa-brands`, etc.)

### Full-Width Layout Not Working

1. Make sure the theme override is correctly set up
2. Check if CSS specificity is sufficient (add `!important` if needed)
3. Restart the MkDocs server to ensure changes are applied

### GitLab Edit Links Not Working

1. Verify your `edit_uri` path is correct and points to the right branch
2. Ensure your repository permissions allow editing
3. Check that the document path in your repository matches the documentation structure
