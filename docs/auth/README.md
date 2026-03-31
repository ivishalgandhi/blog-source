# Authentication Demo with OIDC and Dex

This project demonstrates modern authentication using OpenID Connect (OIDC) with Dex as an identity provider and a Python Flask application.

## Project Structure

- **app/** - Python Flask application that authenticates users via OIDC
- **dex/** - Configuration files for the Dex identity provider
- **docs/** - Documentation explaining authentication concepts and implementation

## Quick Start

1. Start the Dex identity provider:
   ```bash
   cd dex
   docker-compose up -d
   ```

2. Start the Python application:
   ```bash
   cd app
   pip install -r requirements.txt
   python app.py
   ```

3. Visit http://localhost:8000 in your browser

4. Login with the test credentials:
   - Email: admin@example.com
   - Password: password

## Documentation

For detailed information, check the following documentation:

- [Modern Authentication Overview](modern-authentication-overview.md)
- [OpenID Connect Deep Dive](oidc-deep-dive.md)
- [SAML Deep Dive](saml-deep-dive.md)
- [Implementation Tutorial](implementation-tutorial.md)

## Learning Objectives

This project will help you understand:

1. How modern authentication protocols (OIDC and SAML) work
2. How to implement OIDC authentication in a Python application
3. How to set up an identity provider (Dex)
4. The flow of authentication in a real-world scenario

## Requirements

- Docker and Docker Compose
- Python 3.8+
- macOS environment (can be adapted for other platforms)
