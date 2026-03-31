---
sidebar_position: 10
title: "OAuth 2.0: Authorization Framework"
description: "A comprehensive guide to OAuth 2.0, the industry-standard protocol for authorization"
---

# OAuth 2.0: Authorization Framework

OAuth 2.0 is the industry-standard protocol for authorization. Unlike authentication protocols that verify identity, OAuth 2.0 focuses on delegation of access rights, allowing third-party applications to access resources on behalf of users without exposing credentials.

## The Problem with Sharing Credentials

In the past, when one service needed to access your data or perform actions on your behalf in another service, the common (and insecure) practice was to simply **give the first service your username and password** for the second service. This allowed the service to log in as you and access your account.

However, this approach is highly risky:
*   There's **no guarantee** the organization receiving your credentials will keep them safe.
*   There's **no guarantee** they won't access more personal information than necessary.

Sharing your username and password directly with another service should **never be required**.

## OAuth 2.0: Delegated Authorization

Fortunately, we now have agreed-upon standards to securely allow one service to access data from another. OAuth 2.0 is a **security standard** that allows you to **grant one application permission to access your data or perform actions on your behalf in another application**. Instead of sharing your password, you essentially give the application a **"key"** with **specific, limited permissions**. This process of granting permission is often called **authorization** or **delegated authorization**. A significant advantage is that you can **revoke this "key"** whenever you want.

## Core Concepts

At its foundation, OAuth 2.0 involves several key actors:

- **Resource Owner**: The entity (typically the end-user) that can grant access to a protected resource. That's **you**. You own your identity, data, and account actions.
- **Client**: The application requesting access to protected resources. This is the application that wants to access your data or perform actions on your behalf.
- **Authorization Server**: The server that authenticates the Resource Owner and issues access tokens. This is the application that knows the Resource Owner and where the Resource Owner already has an account. This server is responsible for authenticating the Resource Owner and granting permission.
- **Resource Server**: The server hosting the protected resources, capable of accepting and responding to requests using access tokens. This is the API or service the Client wants to use on your behalf. The Authorization Server and Resource Server can be the same server or different servers/organizations.

Additional important terminology includes:

- **Redirect URI (or Callback URL)**: The specific URL on the Client application where the Authorization Server will redirect the Resource Owner's browser after they grant or deny permission.
- **Response Type**: Indicates the type of information the Client expects back from the Authorization Server. The most common type is **"code"**, signifying the client expects an Authorization Code.
- **Scope**: These are the **granular permissions** the Client requests, such as reading data or performing specific actions. The Authorization Server uses these to ask the Resource Owner for Consent.
- **Consent**: The process where the Authorization Server asks the Resource Owner if they want to grant the Client the requested Scopes (permissions).
- **Client ID**: An ID used to identify the Client application with the Authorization Server.
- **Client Secret**: A **secret password** that only the Client and the Authorization Server know. This is used for secure, private communication between them behind the scenes. It helps the Authorization Server verify the identity of the Client. Sometimes called the App ID and App Secret.
- **Authorization Code**: A **short-lived, temporary code** that the Authorization Server sends back to the Client via the Resource Owner's browser.
- **Access Token**: A **"key"** issued by the Authorization Server to the Client. As far as the Client is concerned, it's just a string of gibberish; the Client doesn't understand its contents. The Resource Server verifies this token.

```mermaid
sequenceDiagram
    autonumber
    box transparent User Side
        participant User as Resource Owner
    end
    box transparent Client Side
        participant App as Client
    end
    box rgba(0,128,255,0.1) Authorization Services
        participant Auth as Authorization Server
        participant API as Resource Server
    end
    
    User->>App: Use Application
    note over App: Client needs resource<br/>access on behalf of user
    
    App->>+Auth: Authorization Request<br/>(client_id, redirect_uri, scope, response_type=code)
    Auth->>+User: Authentication & Authorization
    note right of Auth: Verify user identity<br/>and show consent screen
    User->>-Auth: Consent (Allow Access)
    Auth-->>-App: Redirect with Authorization Code
    note over App, Auth: User's browser redirects to<br/>https://client.example.com/callback?code=abc123
    
    App->>+Auth: Token Request with Auth Code<br/>(code, client_id, client_secret, redirect_uri)
    Auth->>-App: Access Token (+ optional Refresh Token)
    
    note right of App: Client stores tokens securely
    
    App->>+API: API Request with Access Token<br/>(Authorization: Bearer token123)
    API->>+Auth: Validate Token (optional)
    Auth->>-API: Token Valid + Scope Information
    API->>-App: Protected Resource
    
    rect rgb(240,240,240)
        note over App, API: Token lifecycle management includes<br/>refreshing expired tokens and<br/>possible token revocation
    end
```

## Authorization Grant Types

OAuth 2.0 defines four primary authorization grant types, each suited to different use cases:

### 1. Authorization Code Flow

Best for server-side applications. This is the most common and secure flow.

```mermaid
flowchart LR
    A[User] --> B[Client App]
    B --> C[Auth Server]
    C --> D[Authorization Code]
    D --> E[Exchange for Token]
    E --> F[Access Resource]
```

**Implementation details**:
- User is redirected to the authorization server
- After authentication, authorization server redirects back to client with an authorization code
- Client exchanges code for an access token using its client secret
- Client uses the access token to access resources

### The OAuth 2.0 Authorization Code Flow Example

Let's use the example of a website called "Terrible Pun of the Day" that wants to access your email contacts. Here's how the authorization code flow works in detail:

```mermaid
sequenceDiagram
    autonumber
    box transparent User Browser
        participant User as You (Resource Owner)<br>End User
    end
    box rgba(255,230,180,0.2) Client Application
        participant PunApp as Terrible Pun of the Day (Client)<br>e.g., Third-party App, Spotify, Slack
    end
    box rgba(200,230,255,0.2) Identity Provider
        participant EmailAuth as Email Service (Auth Server)<br>e.g., Google, Okta, Auth0, Azure AD, Dex
    end
    box rgba(200,255,200,0.2) Resource Provider
        participant EmailAPI as Email API (Resource Server)<br>e.g., Gmail API, Microsoft Graph API
    end
    
    note over User,PunApp: Authorization Request Phase
    
    User->>+PunApp: Click "Connect to Email"
    PunApp-->>-User: Redirect to Email Service
    
    note over User,EmailAuth: Authentication Phase
    
    User->>+EmailAuth: Arrive at Email Auth page
    EmailAuth->>User: Request login (if needed)
    User->>EmailAuth: Login with credentials
    
    rect rgb(255,250,220)
        note right of EmailAuth: Consent Screen
        EmailAuth->>User: Ask for consent: "Allow Terrible Pun of the Day\nto access your contacts?"
        User-->>EmailAuth: Click "Allow"
        EmailAuth->>-EmailAuth: Process consent
    end
    
    note over User,PunApp: Authorization Code Grant
    
    EmailAuth-->>User: Redirect to https://terrible-pun-app.com/callback?code=abc123
    User->>+PunApp: Return to /callback endpoint with authorization code
    
    note over PunApp,EmailAuth: Token Exchange (Back Channel)
    
    PunApp->>+EmailAuth: Exchange code + client_secret for access token
    note right of PunApp: POST /token\ncode=abc123&\nclient_id=client123&\nclient_secret=secret456&\ngrant_type=authorization_code
    EmailAuth->>-PunApp: Return access token
    
    note over PunApp,EmailAPI: Resource Access
    
    PunApp->>+EmailAPI: Request contacts using access token
    note right of PunApp: GET /contacts\nAuthorization: Bearer eyJhbGci...
    opt Token Validation
        EmailAPI->>+EmailAuth: Validate token
        EmailAuth->>-EmailAPI: Confirm token is valid
    end
    EmailAPI->>-PunApp: Return your contacts
    
    PunApp->>User: Show "Sending puns to your contacts!"
```

1. **Initiate Request:** You (Resource Owner) want "Terrible Pun of the Day" (Client) to access your contacts. The **Client redirects your browser** to the **Authorization Server**. This request includes the **Client ID**, the **Redirect URI**, the desired **Response Type** (e.g., "code"), and the requested **Scopes** (e.g., "read contacts").

2. **Authentication (if needed):** The Authorization Server verifies who you are. If you're not logged in, it prompts you to do so.

3. **Consent:** The Authorization Server presents a form or page showing the Scopes the Client is requesting and asks you (Resource Owner) if you want to grant or deny permission.

4. **Authorization Code Grant:** If you grant permission (Consent), the **Authorization Server redirects your browser back to the Client** using the specified Redirect URI. This redirect includes a temporary **Authorization Code** in the URL.

5. **Code Exchange Request:** The **Client receives the Authorization Code** from the redirect. The **Client then contacts the Authorization Server directly** (this communication is not through your browser). The Client sends its **Client ID, Client Secret**, and the received **Authorization Code** to the Authorization Server.

6. **Token Issuance:** The Authorization Server verifies the received data (Client ID, Client Secret, and Authorization Code). If valid, the Authorization Server issues an **Access Token** and sends it back to the Client.

7. **Resource Access:** The **Client receives the Access Token**. The Client then uses this Access Token to make requests to the **Resource Server** (e.g., an API endpoint for contacts). The request is like: "Here's an access token, please give me the contacts associated with the owner of this token".

8. **Resource Response:** The Resource Server receives the request and the Access Token. It **verifies the Access Token** with the Authorization Server. If the token is valid and has the necessary permissions (Scopes), the Resource Server responds with the requested data (e.g., your contacts).

It's important to note that the Client and Authorization Server establish their relationship (getting the Client ID and Client Secret) *before* the Resource Owner initiates a flow. The Client Secret **must be kept secret**.

### 2. Implicit Flow

Designed for browser-based applications or mobile apps without a backend server (now largely deprecated in favor of Authorization Code Flow with PKCE).

```mermaid
flowchart LR
    A[User] --> B[Client App]
    B --> C[Auth Server]
    C --> D[Access Token]
    D --> E[Access Resource]
```

**Security note**: This flow returns the access token directly in the browser redirect, making it more vulnerable to token leakage.

### 3. Resource Owner Password Credentials

Used when there is a high degree of trust between the user and the client application. The application collects the user's credentials directly.

```mermaid
flowchart LR
    A[Client App] --> B[Collect Username/Password]
    B --> C[Exchange for Token]
    C --> D[Access Resource]
```

**Security note**: This grant type should be avoided when possible as it requires the client to collect the user's credentials directly.

### 4. Client Credentials

Used for server-to-server authentication where no user is involved.

```mermaid
flowchart LR
    A[Server App] --> B[Auth Server]
    B --> C[Access Token]
    C --> D[Access Resource]
```

**Implementation details**:
- Client authenticates with its client ID and secret
- No user interaction required
- Used for accessing resources owned by the client itself

## OAuth 2.0 Tokens

### Access Tokens

The primary credential used to access protected resources. Key characteristics:

- Typically short-lived (minutes to hours)
- Can be any format (though JWT is common)
- Sent with each API request, usually as a Bearer token in the Authorization header

Example usage:
```http
GET /api/resource HTTP/1.1
Host: example.com
Authorization: Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...
```

### Refresh Tokens

Used to obtain new access tokens when the original expires:

- Typically long-lived (days to months)
- Should be stored securely
- Never sent to resource servers
- Can be revoked to terminate access

## Token Validation

Resource servers must validate tokens before granting access to protected resources. Two common approaches:

### 1. Local Validation

If tokens are JWTs with signatures:
```javascript
// Pseudocode for JWT validation
function validateToken(token) {
  const decoded = decodeJWT(token);
  if (!verifySignature(decoded, publicKey)) return false;
  if (isExpired(decoded.exp)) return false;
  if (decoded.aud !== 'my-api') return false;
  return true;
}
```

### 2. Introspection Endpoint

For opaque tokens or additional validation:
```http
POST /introspect HTTP/1.1
Host: auth-server.example.com
Content-Type: application/x-www-form-urlencoded
Authorization: Basic czZCaGRSa3F0MzpnWDFmQmF0M2JW

token=mF_9.B5f-4.1JqM&token_type_hint=access_token
```

Response:
```json
{
  "active": true,
  "client_id": "l238j323ds-23ij4",
  "username": "jsmith",
  "scope": "read write",
  "sub": "Z5O3upPC88QrAjx00dis",
  "exp": 1419356238
}
```

## OAuth 2.0 Scopes

Scopes limit the authorization to specific resources or actions:

- Defined by the resource server
- Requested by the client during authorization
- User consents to specific scopes
- Included in the access token

Example scopes:
```
read:contacts write:contacts read:profile admin:settings
```

## Security Best Practices

### PKCE (Proof Key for Code Exchange)

PKCE enhances security for public clients by preventing authorization code interception attacks:

1. Client generates a random `code_verifier`
2. Client derives a `code_challenge` from the verifier (typically using SHA-256)
3. Authorization request includes the `code_challenge`
4. Token request includes the original `code_verifier` for verification

```javascript
// Generate code_verifier and code_challenge
const codeVerifier = generateRandomString(64);
const codeChallenge = base64UrlEncode(sha256(codeVerifier));

// Authorization request
// GET /authorize?response_type=code&client_id=CLIENT_ID&redirect_uri=REDIRECT_URI&code_challenge=CODE_CHALLENGE&code_challenge_method=S256

// Token request
// POST /token
// code=AUTH_CODE&client_id=CLIENT_ID&code_verifier=CODE_VERIFIER&grant_type=authorization_code
```

### State Parameter

The `state` parameter helps prevent CSRF attacks:

```javascript
// Authorization request
const state = generateRandomString(32);
// Store state in session
sessionStorage.setItem('oauth_state', state);

// GET /authorize?response_type=code&client_id=CLIENT_ID&redirect_uri=REDIRECT_URI&state=STATE

// Verify state in callback
if (receivedState !== sessionStorage.getItem('oauth_state')) {
  // Potential CSRF attack
  throw new Error('Invalid state parameter');
}
```

## Common OAuth 2.0 Extensions

### OpenID Connect (OIDC)

OIDC is built on top of OAuth 2.0, adding authentication capabilities:

- Standardized identity tokens (JWT format)
- UserInfo endpoint for profile information
- Standard claims about the authenticated user
- Discovery and registration protocols

### Token Introspection (RFC 7662)

Allows resource servers to validate tokens with the authorization server:

```http
POST /introspect HTTP/1.1
Host: auth-server.example.com
Content-Type: application/x-www-form-urlencoded
Authorization: Basic czZCaGRSa3F0MzpnWDFmQmF0M2JW

token=mF_9.B5f-4.1JqM&token_type_hint=access_token
```

### Token Revocation (RFC 7009)

Enables clients to signal the authorization server that a token is no longer needed:

```http
POST /revoke HTTP/1.1
Host: auth-server.example.com
Content-Type: application/x-www-form-urlencoded
Authorization: Basic czZCaGRSa3F0MzpnWDFmQmF0M2JW

token=45ghiukldjahdnhzdauz&token_type_hint=refresh_token
```

### OAuth 2.0 for Native Apps (RFC 8252)

Provides guidelines for implementing OAuth in native applications:

- Use system browser for authorization requests
- Use HTTPS redirect URIs with custom schemes
- Implement PKCE
- Securely store tokens

## OAuth 2.0 Implementation Examples

### Client Authorization Request (Authorization Code Flow)

```javascript
// Redirect user to authorization endpoint
function redirectToAuth() {
  const authUrl = new URL('https://auth-server.example.com/authorize');
  authUrl.searchParams.append('response_type', 'code');
  authUrl.searchParams.append('client_id', 'YOUR_CLIENT_ID');
  authUrl.searchParams.append('redirect_uri', 'https://your-app.com/callback');
  authUrl.searchParams.append('scope', 'read write');
  authUrl.searchParams.append('state', generateRandomState());
  
  // Add PKCE parameters
  const codeVerifier = generateCodeVerifier();
  sessionStorage.setItem('code_verifier', codeVerifier);
  const codeChallenge = generateCodeChallenge(codeVerifier);
  authUrl.searchParams.append('code_challenge', codeChallenge);
  authUrl.searchParams.append('code_challenge_method', 'S256');
  
  window.location.href = authUrl.toString();
}
```

### Token Exchange

```javascript
// Exchange authorization code for tokens
async function exchangeCodeForToken(code) {
  const tokenUrl = 'https://auth-server.example.com/token';
  const codeVerifier = sessionStorage.getItem('code_verifier');
  
  const params = new URLSearchParams();
  params.append('grant_type', 'authorization_code');
  params.append('code', code);
  params.append('redirect_uri', 'https://your-app.com/callback');
  params.append('client_id', 'YOUR_CLIENT_ID');
  params.append('client_secret', 'YOUR_CLIENT_SECRET');
  params.append('code_verifier', codeVerifier);
  
  const response = await fetch(tokenUrl, {
    method: 'POST',
    body: params,
    headers: {
      'Content-Type': 'application/x-www-form-urlencoded'
    }
  });
  
  const tokens = await response.json();
  // Store tokens securely
  sessionStorage.setItem('access_token', tokens.access_token);
  sessionStorage.setItem('refresh_token', tokens.refresh_token);
  return tokens;
}
```

### Making Authenticated API Requests

```javascript
// Use access token to call protected API
async function callProtectedApi() {
  const accessToken = sessionStorage.getItem('access_token');
  const apiUrl = 'https://api.example.com/protected-resource';
  
  const response = await fetch(apiUrl, {
    headers: {
      'Authorization': `Bearer ${accessToken}`
    }
  });
  
  if (response.status === 401) {
    // Token expired, refresh it
    await refreshAccessToken();
    return callProtectedApi();
  }
  
  return response.json();
}
```

### Refreshing Access Tokens

```javascript
// Refresh the access token using a refresh token
async function refreshAccessToken() {
  const refreshToken = sessionStorage.getItem('refresh_token');
  const tokenUrl = 'https://auth-server.example.com/token';
  
  const params = new URLSearchParams();
  params.append('grant_type', 'refresh_token');
  params.append('refresh_token', refreshToken);
  params.append('client_id', 'YOUR_CLIENT_ID');
  params.append('client_secret', 'YOUR_CLIENT_SECRET');
  
  const response = await fetch(tokenUrl, {
    method: 'POST',
    body: params,
    headers: {
      'Content-Type': 'application/x-www-form-urlencoded'
    }
  });
  
  const tokens = await response.json();
  sessionStorage.setItem('access_token', tokens.access_token);
  
  // Some servers also return a new refresh token
  if (tokens.refresh_token) {
    sessionStorage.setItem('refresh_token', tokens.refresh_token);
  }
  
  return tokens;
}
```

## Advantages of OAuth 2.0

1. **Delegation without credential sharing**: Users don't need to share their credentials with third-party applications
2. **Limited access**: Scopes restrict what actions third-party applications can perform
3. **Revocable access**: Tokens can be revoked without changing user credentials
4. **Time-limited authorization**: Access tokens expire automatically
5. **Widely adopted**: Industry standard supported by major providers
6. **Extensible**: Framework for building additional security protocols (like OpenID Connect)

## Common Challenges and Solutions

| Challenge | Solution |
|-----------|----------|
| Token storage in browser applications | Use HttpOnly cookies or secure web storage with proper CSRF protection |
| Mobile app security | Follow RFC 8252, use PKCE, avoid WebViews |
| Cross-Origin Resource Sharing (CORS) | Configure proper CORS policies on resource servers |
| Token validation | Use introspection endpoint or JWT validation |
| Service-to-service authentication | Use client credentials flow with proper client authentication |

## OAuth 2.0 vs OAuth 1.0a

| Feature | OAuth 2.0 | OAuth 1.0a |
|---------|-----------|------------|
| Complexity | Simpler | More complex |
| Token format | Flexible (often JWT) | Opaque string |
| Signature | Not required (TLS) | Required cryptographic signature |
| Client types | Multiple flows for different clients | One flow for all clients |
| Security | Relies on TLS | Cryptographic signatures |
| Bearer tokens | Yes | No |
| Token expiration | Built-in | Not defined |

## Summary

OAuth 2.0 is a flexible, widely-adopted framework for authorization that enables secure delegation of access to protected resources. Its modular design allows for various client types and security requirements through different grant types and extensions. By focusing on authorization rather than authentication, OAuth 2.0 solves the specific problem of controlled access delegation without credential sharing.

While OAuth 2.0 itself doesn't provide authentication, its extension OpenID Connect adds standardized identity functionality. Together, these protocols form the foundation of modern API security and single sign-on systems across the web.

## Further Reading

- [OAuth 2.0 Specification (RFC 6749)](https://tools.ietf.org/html/rfc6749)
- [OAuth 2.0 Bearer Token Usage (RFC 6750)](https://tools.ietf.org/html/rfc6750)
- [OAuth 2.0 Threat Model and Security Considerations (RFC 6819)](https://tools.ietf.org/html/rfc6819)
- [OAuth 2.0 for Native Apps (RFC 8252)](https://tools.ietf.org/html/rfc8252)
- [Proof Key for Code Exchange (RFC 7636)](https://tools.ietf.org/html/rfc7636)
- [OAuth 2.0 Token Introspection (RFC 7662)](https://tools.ietf.org/html/rfc7662)
- [OAuth.net Official Website](https://oauth.net/2/)
- [An Illustrated Guide to OAuth and OpenID Connect](https://www.youtube.com/watch?v=t18YB3xDfXI)
