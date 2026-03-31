# Technical Plan: Docs Authentication

## Architecture Overview

```
┌─────────────────────────────────────────────────────────────┐
│                     Docusaurus App                           │
│  ┌───────────────────────────────────────────────────────┐  │
│  │  Root.js (AuthContext Provider)                       │  │
│  │  ┌─────────────────────────────────────────────────┐  │  │
│  │  │  DocRoot Wrapper (Auth Check)                   │  │  │
│  │  │  ┌───────────────────────────────────────────┐  │  │  │
│  │  │  │  IF authenticated:                        │  │  │  │
│  │  │  │    → Render DocRoot (docs content)        │  │  │  │
│  │  │  │  ELSE:                                    │  │  │  │
│  │  │  │    → Render LoginPage                     │  │  │  │
│  │  │  └───────────────────────────────────────────┘  │  │  │
│  │  └─────────────────────────────────────────────────┘  │  │
│  └───────────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────────┘
```

## Component Design

### 1. AuthContext (src/theme/Root.js)
**Purpose:** Global authentication state management

**State:**
- `user`: Object with email, name, picture (or null)
- `loading`: Boolean for initial session check

**Methods:**
- `login(googleUser)`: Validate email and set user
- `logout()`: Clear user and localStorage

**Storage:**
- localStorage key: `docusaurus_auth_user`
- Value: JSON stringified user object

### 2. DocRoot Wrapper (src/theme/DocRoot/index.js)
**Purpose:** Intercept all docs routes and enforce auth

**Logic:**
```javascript
if (loading) return <Loading />;
if (!user) return <LoginPage />;
return <OriginalDocRoot {...props} />;
```

### 3. LoginPage (src/components/LoginPage/index.js)
**Purpose:** Google sign-in UI

**Features:**
- Load Google Identity Services script dynamically
- Render Google sign-in button
- Handle credential response (JWT decode)
- Show error for unauthorized emails
- Match site dark theme styling

### 4. LogoutButton (src/components/LogoutButton/index.js)
**Purpose:** Allow users to sign out

**Placement:** Docs sidebar footer or navbar

## Google Identity Services Integration

### Script Loading
```javascript
const script = document.createElement('script');
script.src = 'https://accounts.google.com/gsi/client';
script.async = true;
script.defer = true;
```

### Configuration
```javascript
window.google.accounts.id.initialize({
  client_id: 'YOUR_CLIENT_ID.apps.googleusercontent.com',
  callback: handleCredentialResponse,
});
```

### JWT Decoding
```javascript
const payload = JSON.parse(atob(credential.split('.')[1]));
const email = payload.email;
```

## File Structure

```
src/
├── theme/
│   ├── Root.js              # AuthContext provider
│   └── DocRoot/
│       └── index.js          # Wrapped DocRoot with auth check
└── components/
    ├── LoginPage/
    │   └── index.js          # Google sign-in UI
    └── LogoutButton/
        └── index.js          # Logout button component
```

## Configuration Changes

### docusaurus.config.js
```javascript
// Re-enable docs plugin
docs: {
  sidebarPath: require.resolve('./sidebars.js'),
  routeBasePath: 'docs',
},

// Add Google Client ID
customFields: {
  googleClientId: process.env.GOOGLE_CLIENT_ID || 'your-client-id',
},
```

## Security Considerations

1. **Client ID Exposure:** OAuth 2.0 client ID is public by design; restrict via Google Console authorized origins
2. **Email Validation:** Client-side only; sufficient for this use case (single user)
3. **Session Storage:** localStorage is accessible via XSS; acceptable for docs content
4. **No Sensitive Data:** Docs should not contain secrets or PII

## Styling

Match existing dark theme:
- Background: `#1b1b1d` (var(--ifm-background-color))
- Text: `#e3e3e3` (var(--ifm-font-color-base))
- Button: Google standard or custom styled
- Centered layout with flexbox

## Testing Strategy

### Local Development
1. `npm run start` - Dev server with hot reload
2. Test each component in isolation
3. Verify auth flow end-to-end

### Production Build
1. `npm run build` - Static build
2. `npm run serve` - Test production build locally
3. Verify no hydration mismatches

## Dependencies

**No new npm packages required.**

Google Identity Services loaded via CDN in component.

## Environment Variables

```bash
# .env.local (not committed)
GOOGLE_CLIENT_ID=your-client-id.apps.googleusercontent.com
```

## Rollback Plan

If issues occur:
1. Revert `docusaurus.config.js` to `docs: false`
2. Delete swizzled components
3. Site returns to blog-only mode
