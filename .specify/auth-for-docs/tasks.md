# Tasks: Docs Authentication Implementation

## Dependencies
- T01 → T02 → T04 → T05 → T06 → T07 → T08 → T09 → T10 → T11-13
- T03 can run in parallel anytime before T05

---

## [T01] Create SDD Specification Files
**Description:** Create spec.md, plan.md, and tasks.md in .specify/auth-for-docs/

**Acceptance Criteria:**
- [ ] spec.md defines user stories, acceptance criteria, edge cases
- [ ] plan.md defines architecture, components, file structure
- [ ] tasks.md defines implementation tasks with dependencies

**Verification:** Review all three files for completeness

**Status:** ✅ COMPLETED

---

## [T02] Re-enable Docs Plugin
**Description:** Update docusaurus.config.js to enable docs with route `/docs`

**Files to modify:**
- `docusaurus.config.js`

**Changes:**
- Change `docs: false` to docs configuration object
- Set `routeBasePath: 'docs'`
- Add `sidebarPath: require.resolve('./sidebars.js')`

**Acceptance Criteria:**
- [ ] `npm run start` starts without errors
- [ ] Navigating to `/docs` shows docs content (currently public)
- [ ] Blog at `/` still works

**Verification:** `curl http://localhost:3000/docs` returns 200

**Status:** 🔄 READY

---

## [T03] Setup Google OAuth Credentials
**Description:** Create OAuth 2.0 credentials in Google Cloud Console

**Steps:**
1. Go to https://console.cloud.google.com/
2. Create new project or select existing
3. Navigate to "APIs & Services" > "Credentials"
4. Click "Create Credentials" > "OAuth client ID"
5. Application type: "Web application"
6. Name: "Docusaurus Docs Auth"
7. Authorized JavaScript origins:
   - `http://localhost:3000` (local dev)
   - `https://vishalgandhi.in` (production)
8. Click "Create"
9. Copy Client ID

**Acceptance Criteria:**
- [ ] OAuth 2.0 Client ID created
- [ ] localhost:3000 added to authorized origins
- [ ] Client ID copied and ready for use

**Verification:** Client ID ends with `.apps.googleusercontent.com`

**Status:** 🔄 READY (can run in parallel)

---

## [T04] Create AuthContext
**Description:** Create src/theme/Root.js with authentication context

**Files to create:**
- `src/theme/Root.js`

**Implementation:**
- Create AuthContext with React Context API
- useState for user and loading
- useEffect to check localStorage on mount
- login() method with email validation
- logout() method to clear session

**Acceptance Criteria:**
- [ ] Root.js exports AuthContext.Provider
- [ ] useAuth() hook available for components
- [ ] Session loaded from localStorage on startup
- [ ] Only `igandhivishal@gmail.com` is valid

**Verification:** Console log shows auth state changes

**Status:** 🔄 READY

---

## [T05] Create LoginPage Component
**Description:** Create Google sign-in UI component

**Files to create:**
- `src/components/LoginPage/index.js`
- `src/components/LoginPage/styles.module.css` (optional)

**Implementation:**
- Load GIS script dynamically
- Initialize with client ID from config
- Render Google sign-in button
- Handle credential response (decode JWT)
- Call authContext.login() on success
- Show error for unauthorized emails
- Style to match dark theme

**Acceptance Criteria:**
- [ ] Login page renders with Google button
- [ ] Clicking button opens Google OAuth popup
- [ ] Successful login stores user data
- [ ] Unauthorized email shows error message

**Verification:** Test sign-in flow manually

**Status:** 🔄 READY (depends on T03 for client ID)

---

## [T06] Swizzle and Wrap DocRoot
**Description:** Swizzle DocRoot component and add auth check

**Commands:**
```bash
npm run swizzle @docusaurus/theme-classic DocRoot -- --wrap
```

**Files to modify:**
- `src/theme/DocRoot/index.js` (created by swizzle)

**Implementation:**
- Import useAuth from Root
- Import LoginPage from components
- Check user and loading state
- Return LoginPage if not authenticated
- Return original DocRoot if authenticated

**Acceptance Criteria:**
- [ ] DocRoot swizzled successfully
- [ ] Unauthenticated users see LoginPage
- [ ] Authenticated users see docs content
- [ ] No console errors

**Verification:** Navigate to `/docs`, should see login page

**Status:** 🔄 READY (depends on T04, T05)

---

## [T07] Implement Email Validation
**Description:** Ensure only igandhivishal@gmail.com can authenticate

**Files to modify:**
- `src/theme/Root.js` (login method)
- `src/components/LoginPage/index.js` (error handling)

**Implementation:**
- Hardcode ALLOWED_EMAIL constant
- Check email before setting user state
- Show "Access Denied" for unauthorized emails
- Log unauthorized attempts to console

**Acceptance Criteria:**
- [ ] Authorized email grants access
- [ ] Unauthorized email shows error
- [ ] Error message is user-friendly

**Verification:** Test with different Google accounts

**Status:** 🔄 READY (depends on T05)

---

## [T08] Add Session Persistence
**Description:** Persist auth state in localStorage

**Files to modify:**
- `src/theme/Root.js`

**Implementation:**
- localStorage.setItem('docusaurus_auth_user', JSON.stringify(user))
- localStorage.getItem on mount to restore session
- localStorage.removeItem on logout
- Handle JSON parse errors gracefully

**Acceptance Criteria:**
- [ ] Session saved to localStorage on login
- [ ] Session restored on page refresh
- [ ] Session cleared on logout
- [ ] Invalid session data handled gracefully

**Verification:** Login, refresh page, still authenticated

**Status:** 🔄 READY (depends on T04)

---

## [T09] Create LogoutButton
**Description:** Add logout functionality to docs pages

**Files to create:**
- `src/components/LogoutButton/index.js`

**Files to modify:**
- `src/theme/DocRoot/index.js` (add button to layout)

**Implementation:**
- Create LogoutButton component
- Call authContext.logout() on click
- Style as secondary button
- Place in docs sidebar or header

**Acceptance Criteria:**
- [ ] Logout button visible when authenticated
- [ ] Clicking logout clears session
- [ ] Returns to login page after logout
- [ ] Google session also signed out

**Verification:** Login, click logout, verify localStorage cleared

**Status:** 🔄 READY (depends on T04, T06)

---

## [T10] Style Login Page
**Description:** Match login page to site dark theme

**Files to modify:**
- `src/components/LoginPage/index.js`
- `src/components/LoginPage/styles.module.css` (if created)

**Design:**
- Centered layout with flexbox
- Dark background matching site theme
- Typography consistent with Docusaurus
- Error message styling (red text)
- Responsive for mobile

**Acceptance Criteria:**
- [ ] Login page matches dark theme
- [ ] Centered vertically and horizontally
- [ ] Mobile responsive
- [ ] Error messages clearly visible

**Verification:** Visual inspection on desktop and mobile

**Status:** 🔄 READY (depends on T05)

---

## [T11] Test Authentication Flow
**Description:** Complete end-to-end testing

**Test Cases:**
1. Navigate to `/docs` → see login page
2. Click Google sign-in → OAuth popup opens
3. Sign in with authorized email → see docs content
4. Refresh page → still authenticated
5. Click logout → return to login page
6. Navigate to `/` (blog) → no login required
7. Navigate to `/about` → no login required

**Acceptance Criteria:**
- [ ] All test cases pass
- [ ] No console errors
- [ ] No hydration mismatches

**Verification:** Manual testing checklist

**Status:** 🔄 READY (depends on T06-T10)

---

## [T12] Test Edge Cases
**Description:** Test error conditions and edge cases

**Test Cases:**
1. Sign in with unauthorized email → access denied
2. Close OAuth popup without signing in → stay on login
3. Direct URL to `/docs/intro` while logged out → login page
4. Corrupt localStorage data → clear and show login
5. Navigate blog → docs → blog → docs → session persists

**Acceptance Criteria:**
- [ ] All edge cases handled gracefully
- [ ] No crashes or infinite loops
- [ ] Clear error messages

**Verification:** Manual testing with intentional errors

**Status:** 🔄 READY (depends on T06-T10)

---

## [T13] Production Build Test
**Description:** Verify production build works correctly

**Commands:**
```bash
npm run build
npm run serve
```

**Test:**
- Repeat T11 and T12 test cases on production build
- Check for hydration mismatches
- Verify no 404 errors

**Acceptance Criteria:**
- [ ] Build completes without errors
- [ ] Production server serves all routes
- [ ] Auth flow works in production build
- [ ] No console warnings

**Verification:** `curl http://localhost:3000/docs` returns login page HTML

**Status:** 🔄 READY (depends on T11, T12)

---

## Summary

| Task | Status | Dependencies |
|------|--------|--------------|
| T01 | ✅ Done | - |
| T02 | 🔄 Ready | - |
| T03 | 🔄 Ready | - |
| T04 | 🔄 Ready | T02 |
| T05 | 🔄 Ready | T03, T04 |
| T06 | 🔄 Ready | T04, T05 |
| T07 | 🔄 Ready | T05 |
| T08 | 🔄 Ready | T04 |
| T09 | 🔄 Ready | T04, T06 |
| T10 | 🔄 Ready | T05 |
| T11 | 🔄 Ready | T06-T10 |
| T12 | 🔄 Ready | T06-T10 |
| T13 | 🔄 Ready | T11, T12 |

**Next:** Start with T02 (re-enable docs plugin)
