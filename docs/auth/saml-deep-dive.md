# SAML Deep Dive

## Introduction to SAML

Security Assertion Markup Language (SAML) is an XML-based open standard for exchanging authentication and authorization data between parties. Developed by the OASIS Security Services Technical Committee, SAML has become a cornerstone of enterprise identity management, especially for web-based single sign-on (SSO) scenarios.

SAML 2.0, released in 2005, is the most widely deployed version and remains the standard for many enterprise identity solutions.

## Core Components of SAML

### 1. Key Participants

- **Identity Provider (IdP)**: The system that performs authentication and issues SAML assertions
- **Service Provider (SP)**: The application or service that the user wants to access
- **Principal**: The user who is being authenticated

### 2. SAML Assertions

Assertions are XML documents containing statements about a subject (typically a user). There are three types:

1. **Authentication Assertions**: State that the user was authenticated by a particular means at a specific time
2. **Attribute Assertions**: Contain specific attributes about the subject (e.g., email, role)
3. **Authorization Decision Assertions**: State whether the subject is permitted to access a resource

### 3. SAML Protocols

- **Authentication Request Protocol**: Used by SPs to request that an IdP authenticate a user
- **Artifact Resolution Protocol**: Used to retrieve a SAML message by reference
- **Single Logout Protocol**: Allows synchronized session logout across all SPs
- **Name Identifier Management Protocol**: Used to manage the lifecycle of subject identifiers

### 4. SAML Bindings

Bindings define how SAML messages are transported over underlying protocols:

- **HTTP Redirect Binding**: Uses URL encoding in the HTTP GET request
- **HTTP POST Binding**: Transmits messages via HTML form fields and browser POST
- **HTTP Artifact Binding**: Passes a reference to the message rather than the message itself
- **SAML SOAP Binding**: Uses SOAP messages for direct SAML communication

### 5. SAML Profiles

Profiles describe how SAML assertions, protocols, and bindings are combined to address specific use cases:

- **Web Browser SSO Profile**: The most common profile, used for browser-based single sign-on
- **Enhanced Client or Proxy (ECP) Profile**: Used for rich clients that can directly interact with SAML endpoints
- **Identity Provider Discovery Profile**: Helps applications discover which IdP to use
- **Single Logout Profile**: Defines how to implement synchronized logout

## SAML Authentication Flows

### Web Browser SSO - IdP-Initiated Flow

1. User navigates directly to the IdP and authenticates
2. User selects an application (SP) from a list of available services
3. IdP generates a SAML assertion and sends it to the SP via the user's browser
4. SP validates the assertion and creates a session for the user
5. User gains access to the SP application

### Web Browser SSO - SP-Initiated Flow

1. User attempts to access a protected resource at the SP
2. SP checks if the user has an active session; if not, generates a SAML authentication request
3. SP redirects the user to the IdP with the authentication request
4. User authenticates at the IdP (if not already authenticated)
5. IdP generates a SAML assertion and returns it to the SP via the user's browser
6. SP validates the assertion and creates a session for the user
7. User gains access to the protected resource

## SAML Assertion Structure

A typical SAML assertion contains:

```xml
<saml:Assertion
    xmlns:saml="urn:oasis:names:tc:SAML:2.0:assertion"
    ID="_93af655219464fb403b34436cfb0c5cb1d9a5502"
    IssueInstant="2021-10-01T18:37:09Z"
    Version="2.0">
    <saml:Issuer>https://idp.example.org/SAML2</saml:Issuer>
    <ds:Signature>...</ds:Signature>
    <saml:Subject>
        <saml:NameID Format="urn:oasis:names:tc:SAML:1.1:nameid-format:emailAddress">
            user@example.org
        </saml:NameID>
        <saml:SubjectConfirmation Method="urn:oasis:names:tc:SAML:2.0:cm:bearer">
            <saml:SubjectConfirmationData
                InResponseTo="id_of_the_authn_request"
                NotOnOrAfter="2021-10-01T18:42:09Z"
                Recipient="https://sp.example.com/SAML2/SSO/POST"/>
        </saml:SubjectConfirmation>
    </saml:Subject>
    <saml:Conditions
        NotBefore="2021-10-01T18:37:09Z"
        NotOnOrAfter="2021-10-01T18:42:09Z">
        <saml:AudienceRestriction>
            <saml:Audience>https://sp.example.com/SAML2</saml:Audience>
        </saml:AudienceRestriction>
    </saml:Conditions>
    <saml:AuthnStatement
        AuthnInstant="2021-10-01T18:37:09Z"
        SessionIndex="_be9967abd904ddcae3c0eb4189adbe3f71e327cf">
        <saml:AuthnContext>
            <saml:AuthnContextClassRef>
                urn:oasis:names:tc:SAML:2.0:ac:classes:PasswordProtectedTransport
            </saml:AuthnContextClassRef>
        </saml:AuthnContext>
    </saml:AuthnStatement>
    <saml:AttributeStatement>
        <saml:Attribute Name="uid" NameFormat="urn:oasis:names:tc:SAML:2.0:attrname-format:basic">
            <saml:AttributeValue xsi:type="xs:string">jdoe</saml:AttributeValue>
        </saml:Attribute>
        <saml:Attribute Name="mail" NameFormat="urn:oasis:names:tc:SAML:2.0:attrname-format:basic">
            <saml:AttributeValue xsi:type="xs:string">user@example.org</saml:AttributeValue>
        </saml:Attribute>
    </saml:AttributeStatement>
</saml:Assertion>
```

### Key Components of an Assertion

1. **Issuer**: Identifies the identity provider that issued the assertion
2. **Signature**: Digital signature to ensure integrity and authenticity
3. **Subject**: Identifies the principal (user) that the assertion is about
4. **Conditions**: Specifies conditions under which the assertion is valid
5. **AuthnStatement**: Contains information about the authentication event
6. **AttributeStatement**: Contains attributes about the subject

## SAML Security Considerations

### 1. XML Signature Validation

SAML assertions must be signed to ensure they haven't been tampered with. Service providers must:
- Validate the digital signature using the IdP's public key
- Ensure the signature covers the entire assertion
- Check certificate validity and trust

### 2. Replay Protection

To prevent replay attacks:
- Check the `InResponseTo` attribute matches a request ID
- Verify the assertion's validity period using `NotBefore` and `NotOnOrAfter`
- Maintain a cache of used assertion IDs

### 3. Recipient Validation

The service provider should verify that:
- It is the intended recipient of the assertion
- The assertion was delivered via the expected endpoint

### 4. TLS Protection

All SAML communication should take place over TLS/HTTPS to protect:
- The confidentiality of assertions
- The integrity of requests and responses
- Authentication information during transmission

## SAML vs. OIDC: When to Choose SAML

### Advantages of SAML

1. **Enterprise Maturity**: SAML has been the standard for enterprise SSO for many years
2. **Rich Access Control**: Supports complex access control via extensive attribute statements
3. **No Cookies Required**: Doesn't rely on browser cookies for session management
4. **Strong Security**: Digital signatures and sophisticated validation mechanisms
5. **Non-Browser Support**: Can be used outside of browser contexts with appropriate bindings

### Challenges with SAML

1. **Complexity**: XML processing can be complex and resource-intensive
2. **Size**: SAML messages tend to be larger than JWT tokens
3. **Mobile Support**: Not as well-suited for mobile applications as OIDC
4. **Implementation Difficulty**: More difficult to implement correctly than OIDC
5. **Modern Web Compatibility**: Can have challenges with modern web architecture

## Implementing SAML with Dex

Dex supports SAML 2.0 in two ways:

### 1. Dex as a SAML Service Provider

Dex can authenticate users against external SAML Identity Providers, then issue OIDC tokens to your applications. This is useful when:
- Your organization already uses a SAML IdP like Okta, OneLogin, or ADFS
- You want to build modern applications using OIDC but need to integrate with existing SAML infrastructure

### 2. Dex with SAML Connectors

To configure Dex to use a SAML IdP, you would add a connector to your Dex configuration:

```yaml
connectors:
- type: saml
  id: saml-idp
  name: Corporate SAML Identity Provider
  config:
    entityIssuer: https://dex.example.com/saml
    ssoURL: https://idp.example.org/SAML2/SSO/Redirect
    caData: <base64-encoded-certificate>
    redirectURI: https://dex.example.com/callback
    usernameAttr: email
    emailAttr: email
    groupsAttr: groups
```

This configuration:
- Identifies Dex to the SAML IdP (`entityIssuer`)
- Specifies the IdP's SSO endpoint (`ssoURL`)
- Provides the certificate to validate IdP signatures (`caData`)
- Maps SAML attributes to OIDC claims

## Conclusion

SAML remains a critical protocol for enterprise identity management, especially in organizations with established identity infrastructure. While OIDC has gained popularity for modern web and mobile applications, SAML continues to provide robust security and mature features for complex SSO scenarios.

Understanding both SAML and OIDC allows you to:
1. Select the right protocol for your specific requirements
2. Integrate with existing identity infrastructure
3. Bridge between legacy and modern authentication systems
4. Implement comprehensive identity management solutions

With Dex, you can leverage the strengths of both protocols: use SAML for integration with enterprise identity providers, while exposing OIDC to your applications for a more developer-friendly experience.
