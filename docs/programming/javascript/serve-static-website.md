---
sidebar_position: 1
---

# Publishing Static Websites with npm serve

This guide explains how to use npm's `serve` package to publish static websites, including Docker configuration for containerized deployment.

## What is npm serve?

[serve](https://github.com/vercel/serve) is a lightweight static server with simplified configuration, developed by Vercel. It's designed for serving static websites, single-page applications, and other static content.

Key features:
- Zero configuration by default
- Customizable through CLI options or a configuration file
- HTTPS support
- Compression
- CORS support
- Directory listing

## Basic Usage

### Installation

```bash
# Install globally
npm install -g serve

# Or use npx without installing
npx serve
```

### Serving a Static Site

```bash
# Basic usage (serves current directory on port 3000)
serve

# Specify directory and port
serve -s build -l 5000

# Specify host (for network access)
serve -s build -l 3000 --host 0.0.0.0
```

Common options:
- `-s, --single`: Rewrite all not-found requests to `index.html` (for SPAs)
- `-l, --listen`: Specify port to listen on (default: 3000)
- `--host`: Specify host to bind to (default: localhost)
- `-d, --debug`: Show debugging information

## Dockerizing Static Websites with serve

### Dockerfile Example

Here's a basic Dockerfile for serving a static website:

```dockerfile
FROM node:22-alpine

WORKDIR /app

# Install serve globally
RUN npm install -g serve

# Expose port 3000
EXPOSE 3000

# Command to serve static content
CMD ["serve", "-s", "/app/build"]
```

For more control over the server configuration:

```dockerfile
FROM node:22-alpine

WORKDIR /app

# Install serve globally
RUN npm install -g serve

# Expose port 3000
EXPOSE 3000

# Command to serve static content with specific options
CMD ["serve", "-s", "/app/build", "-l", "3000", "--host", "0.0.0.0"]
```

### Docker Compose Configuration

Here's a docker-compose.yml example for running a containerized static website:

```yaml
services:
  static-site:
    container_name: static-site
    build: .
    ports:
      - "3000:3000"
    volumes:
      - ./build:/app/build
    restart: unless-stopped
```

For host network mode (useful for internal network deployment):

```yaml
services:
  static-site:
    container_name: static-site
    build: .
    network_mode: "host"
    volumes:
      - ./build:/app/build
    restart: unless-stopped
    hostname: static-site
```

## Build and Deploy Workflow

### 1. Building the Static Content

For React applications:
```bash
npm run build
```

For other frameworks (Next.js, Vue, Angular, etc.), use their specific build commands.

### 2. Building the Docker Image

```bash
# Build the image
docker build -t static-site .

# Run the container manually
docker run -p 3000:3000 -v ./build:/app/build static-site
```

### 3. Using Docker Compose

```bash
# Start the service
docker-compose up -d

# View logs
docker-compose logs -f

# Stop the service
docker-compose down
```

## Performance Considerations

- Enable compression with `--compress` for faster content delivery
- Use a CDN for production deployments
- Consider cache headers for optimal performance
- For large sites, consider a more robust server like nginx or a dedicated hosting solution

## Common Issues and Solutions

### Port Binding Issues
If you encounter "port already in use" errors:
- Change the exposed port in your docker-compose.yml
- Check for other services using port 3000

### CORS Issues
If you have CORS issues when accessing the site from other origins:
- Use the `--cors` flag to enable CORS support
- Or specify allowed origins with `--cors-origin`

### 404 Errors in Single Page Applications
If you get 404s when refreshing or accessing routes directly:
- Use the `-s` or `--single` flag to redirect all requests to index.html
