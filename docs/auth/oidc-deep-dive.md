# OpenID Connect Deep Dive

## Introduction to OpenID Connect

OpenID Connect (OIDC) is an identity layer built on top of the OAuth 2.0 protocol. While OAuth 2.0 is designed for authorization (granting access to resources), OIDC extends it to provide authentication (verifying user identity). OIDC was developed to address the need for a standardized, secure way to verify user identities across different applications and domains.

Understanding the relationship between OAuth 2.0 and OIDC is crucial. Think of it this way:

* While OAuth is like giving a Client a "key" for specific permissions, **OIDC is like giving the Client a "badge"**
* This badge provides permissions (like the OAuth Access Token) **and also basic information about who you are**
* **OIDC enables a Client application to establish a login session (authentication)** and get identity information about the user
* When an Authorization Server supports OIDC, it is sometimes referred to as an **Identity Provider**, because it provides identity information back to the Client
* OIDC enables scenarios like **Single Sign-On (SSO)**, allowing one login to work across multiple applications

## The Problem OAuth and OIDC Solve

In the past, when one service needed to access your data or perform actions on your behalf in another service, the common (and insecure) practice was to simply **give the first service your username and password** for the second service. This allowed the service to log in as you and access your account.

However, this approach is highly risky:
* There's **no guarantee** the organization receiving your credentials will keep them safe
* There's **no guarantee** they won't access more personal information than necessary

Sharing your username and password directly with another service should **never be required**.

## OAuth 2.0: Delegated Authorization

OAuth 2.0 is a **security standard** that allows you to **grant one application permission to access your data or perform actions on your behalf in another application**. Instead of sharing your password, you essentially give the application a **"key"** with **specific, limited permissions**. This process of granting permission is often called **authorization** or **delegated authorization**. A significant advantage is that you can **revoke this "key"** whenever you want.

### Example: Terrible Pun of the Day

Let's use the example of a website called "Terrible Pun of the Day". Suppose you create an account and want it to send terrible pun jokes via email to everyone in your contacts list. Manually writing emails to everyone would be a lot of work.

"Terrible Pun of the Day" has a feature to invite friends, which requires access to your email contacts. Instead of asking for your email password, it initiates an **OAuth flow**:

1. You choose your email provider on the "Terrible Pun of the Day" site and click it
2. You are **redirected to your email service** (the Authorization Server)
3. Your email service checks if you are logged in and prompts you to log in if necessary
4. After you are logged in, your email service asks you something like, "Do you want to give Terrible Pun of the Day access to your contacts?" This step is **Consent**
5. If you click **"allow"** (granting consent), you are **redirected back to the "Terrible Pun of the Day" site**
6. The application can now read your contacts (and only your contacts, based on the granted permission)

This process is part of an OAuth flow, specifically the **Authorization Code Flow**, which is the most common OAuth 2.0 flow.

## Core Components of OIDC

### 1. Participants in the OIDC Flow

- **End User** (Resource Owner): The person who wants to authenticate. You own your identity, data, and account actions.
- **Relying Party (RP)** (Client): The application that needs to verify the user's identity and wants to access your data or perform actions on your behalf.
- **OpenID Provider (OP)** (Authorization Server): The identity provider that authenticates the user and provides claims. This is the service where the Resource Owner already has an account.

### 2. Key Endpoints

- **Authorization Endpoint**: Where the user is redirected to authenticate
- **Token Endpoint**: Where the client exchanges codes for tokens
- **UserInfo Endpoint**: Where the client can get additional user information
- **JWKS Endpoint**: Provides the public keys needed to verify token signatures
- **Discovery Endpoint**: Provides configuration information about the OpenID Provider

### 3. Token Types

- **ID Token**: Contains claims about the authentication of the end user
- **Access Token**: Grants access to protected resources (UserInfo Endpoint)
- **Refresh Token**: Used to obtain new ID and access tokens when they expire

## OIDC Flows

OIDC defines several authentication flows to accommodate different client types:

### 1. Authorization Code Flow

The most common and secure flow, suitable for server-side applications:

1. User attempts to access the application
2. Application redirects to the OpenID Provider's authorization endpoint
3. User authenticates and authorizes the application
4. OpenID Provider redirects back to the application with an authorization code
5. Application exchanges the code for ID and access tokens
6. Application validates the ID token and creates a session

### 2. Implicit Flow

Designed for browser-based applications that cannot securely store secrets:

1. User is redirected to the OpenID Provider
2. User authenticates
3. OpenID Provider redirects back with tokens directly in the URL fragment
4. Application validates the ID token and creates a session

**Note**: This flow is now considered less secure and has been largely superseded by the Authorization Code Flow with PKCE.

### 3. Hybrid Flow

Combines aspects of both Authorization Code and Implicit flows:

1. User is redirected to the OpenID Provider
2. User authenticates
3. OpenID Provider returns some tokens immediately and an authorization code
4. Application exchanges the code for additional tokens

### 4. Authorization Code Flow with PKCE (Proof Key for Code Exchange)

Enhanced security for public clients like mobile apps and SPAs:

1. Application generates a code verifier and code challenge
2. Application redirects the user to the OpenID Provider with the code challenge
3. User authenticates
4. OpenID Provider redirects back with an authorization code
5. Application exchanges the code and code verifier for tokens
6. Application validates the ID token and creates a session

## The OIDC Flow - Building on OAuth 2.0

OIDC leverages the OAuth 2.0 authorization framework and adds standardized layers for authentication and obtaining identity information. The key difference is in what is requested and what is received:

1. **Initiate Request with `openid` Scope:** In the initial request from the Client to the Authorization Server, a specific **Scope of `openid` is included**. This signal tells the Authorization Server that this will be an OpenID Connect exchange.

2. **Authorization Code Grant:** The Authorization Server proceeds through the same steps as the OAuth flow, including authentication, consent, and **issues an Authorization Code** back to the Client via the Resource Owner's browser.

3. **Token Exchange - Access Token + ID Token:** When the Client contacts the Authorization Server directly to exchange the Authorization Code for tokens, it receives **both an Access Token (for authorization) and an ID Token (for authentication/identity)**.

4. **Understanding the Tokens:**
   * The **Access Token** is still a value the Client doesn't necessarily understand; it's for interacting with the Resource Server.
   * The **ID Token** is different. It is a specially formatted string called a **JSON Web Token (JWT)**.

5. **Extracting Identity Information from JWT:** A JWT may look like gibberish, but the **Client can extract embedded information from it**. This embedded information is called **Claims**. Claims can include details like your ID, name, when you logged in, and the token's expiration time. JWTs also contain information that allows the Client to detect if the token has been tampered with.

### OIDC Analogy: ATM Card

The relationship between OIDC and OAuth can be thought of like using an ATM:
* The **ATM machine is the Client**. Its job is to access data (like balance) and perform transactions (withdraw, deposit).
* Your **bank card is the token** issued by the bank.
* The card gives the ATM access to your account details and the ability to perform transactions (**authorization**).
* But the card also has **basic information about your identity** (like your name) and authentication details (expiry, issuer).
* The ATM **relies on the underlying bank infrastructure**, just as **OIDC relies on and sits on top of the underlying OAuth framework**. OIDC cannot work without the underlying OAuth.

## ID Tokens in Detail

The ID Token is a JSON Web Token (JWT) containing claims about the authentication event and the user. A typical ID token payload looks like:

```json
{
  "iss": "https://dex.example.com",      // Issuer - who issued the token
  "sub": "123456789",                    // Subject - unique user identifier
  "aud": "client_id",                    // Audience - intended recipient
  "exp": 1516239022,                     // Expiration time
  "iat": 1516235422,                     // Issued at time
  "auth_time": 1516235421,               // Time of authentication
  "nonce": "n-0S6_WzA2Mj",              // Request nonce for replay protection
  "name": "John Doe",                    // User's full name
  "email": "johndoe@example.com",        // User's email
  "email_verified": true                 // Whether email has been verified
}
```

### ID Token Validation

The client must validate the ID token to ensure it's legitimate:

1. Verify the signature using the OpenID Provider's public key
2. Verify the issuer (iss) matches the expected issuer
3. Verify the audience (aud) includes the client ID
4. Check that the token hasn't expired (exp)
5. Verify the nonce if one was sent in the authentication request

## Scopes and Claims in OIDC

OIDC defines standard scopes that map to sets of claims:

- **openid**: Required scope for OIDC. Provides the sub (subject) claim.
- **profile**: User's basic profile information (name, picture, etc.)
- **email**: User's email address and verification status
- **address**: User's physical address
- **phone**: User's phone number and verification status

## OIDC Session Management

OIDC includes mechanisms for managing sessions and performing logout:

### 1. Client-initiated Logout

The client can direct the user to the OpenID Provider's end_session_endpoint to terminate the session.

### 2. RP-initiated Logout

When the user logs out of one application, they can be logged out of all applications connected to the same OpenID Provider.

### 3. Session Monitoring

Applications can monitor the user's session status at the OpenID Provider using techniques like:

- Hidden iframes to the check_session_endpoint
- Periodic checking of ID token validity

## Security Considerations

### 1. Token Storage

- Never store tokens in local storage or session storage (vulnerable to XSS)
- Use httpOnly, secure cookies for server-rendered applications
- Consider using in-memory storage for single-page applications

### 2. Token Validation

- Always validate ID tokens before trusting them
- Verify signatures using the appropriate algorithms and keys
- Check all required claims

### 3. Transport Security

- Always use HTTPS for all OIDC-related communications
- Protect redirect URIs from tampering
- Implement proper CSRF protection

## Advanced OIDC Features

### 1. Claims Requesting

Clients can request specific claims using the claims parameter:

```json
{
  "id_token": {
    "email": {"essential": true},
    "phone_number": null
  },
  "userinfo": {
    "given_name": {"essential": true},
    "family_name": {"essential": true}
  }
}
```

### 2. Request Objects

Complex authentication requests can be packaged as signed JWTs:

```
https://server.example.com/authorize?
  response_type=code
  &client_id=client%5Fid
  &request=eyJhbG...
```

### 3. Pairwise Identifiers

OpenID Providers can use different subject identifiers for the same user across different clients, enhancing privacy.

## Implementing OIDC with Dex

Dex serves as an identity broker, implementing OIDC to provide authentication services for your applications while potentially delegating actual authentication to other systems.

### 1. Dex as an OIDC Provider

Dex implements:
- All required OIDC endpoints
- Standard OIDC flows
- JWT token generation and validation
- User session management

### 2. Dex as an Identity Broker

Dex can authenticate users via:
- Local username/password database
- LDAP/Active Directory
- SAML providers
- Other OAuth2/OIDC providers (Google, GitHub, etc.)

### 3. Key Dex Concepts

- **Connectors**: Plugins that integrate with external identity systems
- **Clients**: Applications that rely on Dex for authentication
- **Static Password Database**: Simple built-in authentication for testing
- **Identity Federation**: Combining identities from multiple sources

## Conclusion

OpenID Connect provides a robust, standardized framework for authentication that's both secure and flexible. With OIDC, you can:

1. Implement single sign-on across multiple applications
2. Delegate authentication to trusted identity providers
3. Maintain a clear separation between authentication and application logic
4. Access standardized user information in a consistent format
5. Build applications that work with a wide variety of identity providers

Understanding OIDC is essential for implementing modern authentication systems, and Dex provides an excellent way to experiment with and implement OIDC in your applications.
