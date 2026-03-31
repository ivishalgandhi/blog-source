# Spec: Google OAuth Authentication for Docusaurus Docs

## Overview
Enable Google OAuth authentication to protect all `/docs/*` routes while keeping blog and main pages public. Only authorized email (`igandhivishal@gmail.com`) can access docs.

## User Stories

### US-1: Protected Documentation
**As a** site owner  
**I want** to restrict access to my documentation  
**So that** only I can view and manage private docs content

**Acceptance Criteria:**
- [ ] All routes under `/docs/*` require authentication
- [ ] Unauthenticated users see a login page with Google sign-in
- [ ] Blog (`/`) and `/about` remain publicly accessible
- [ ] Direct URL access to docs routes is protected

### US-2: Google OAuth Sign-In
**As a** site owner  
**I want** to sign in with my Google account  
**So that** I don't need to manage separate credentials

**Acceptance Criteria:**
- [ ] Login page displays Google sign-in button
- [ ] Clicking button opens Google OAuth consent screen
- [ ] Successful authentication grants access to docs
- [ ] Only `igandhivishal@gmail.com` is authorized

### US-3: Session Persistence
**As a** site owner  
**I want** my session to persist across page refreshes  
**So that** I don't need to sign in repeatedly

**Acceptance Criteria:**
- [ ] Session stored in localStorage after successful login
- [ ] Session restored automatically on page load
- [ ] Session persists across browser sessions

### US-4: Logout Functionality
**As a** site owner  
**I want** to sign out when done  
**So that** I can end my session

**Acceptance Criteria:**
- [ ] Logout button visible when authenticated on docs pages
- [ ] Clicking logout clears session and returns to login page
- [ ] Google session is also signed out

## Edge Cases & Constraints

### EC-1: Unauthorized Email
**Given** a user signs in with Google  
**When** the email is NOT `igandhivishal@gmail.com`  
**Then** show "Access Denied" message and do not grant access

### EC-2: Cancelled Sign-In
**Given** user clicks Google sign-in button  
**When** user closes the OAuth popup or cancels  
**Then** remain on login page without error

### EC-3: Expired/Invalid Session
**Given** user has a stored session  
**When** session data is corrupted or invalid  
**Then** clear storage and show login page

### EC-4: Direct URL Access
**Given** user is not authenticated  
**When** user navigates directly to `/docs/some-page`  
**Then** show login page, not the docs content

### EC-5: Navigation Between Public/Protected
**Given** user is authenticated on docs  
**When** user navigates to blog then back to docs  
**Then** docs remain accessible (session persists)

## Technical Constraints
- Client-side only (no backend server)
- Use Google Identity Services (GIS) via CDN
- Docusaurus 3.x with swizzled components
- Match existing dark theme styling
- No additional npm dependencies for auth

## Out of Scope
- Server-side authentication (Passport.js)
- Multiple authorized users/roles
- Password-based authentication
- Session expiration/timeout logic
- Blog or main page authentication
