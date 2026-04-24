# Test: EP Membership — Admin Settings + Frontend Registration/Login

## Target
- **Site:** dev3.elmspark.com
- **Admin URL:** https://dev3.elmspark.com/admin/plugins/?plugin=EP_Membership
- **Frontend pages:** /register, /login, /profile

## Prerequisites
- Logged into admin (run `pm-browser-login.sh` first)
- EP Membership is active on dev3.elmspark.com
- EP Courses is active (EP Membership declares `Model: EP_Courses`)
- EP Email is active (transactional emails)
- Pages exist with shortcodes: `/register` has `[register-form]`, `/login` has `[login-form]`, `/profile` has `[member-profile]`

## Important Rules
- After EVERY action, run `steer see --app Safari --json` for a fresh snapshot
- After every snapshot, check for "fatal error", "Warning:", or blank content
- If the page goes blank at any point, STOP and report the last action taken
- Do NOT click the main PageMotor "Save Options" button at the top of the page. It has a gold background and sits in a sticky bar. Only use EP Membership's own form buttons
- Use `steer wait --for` with expected text instead of fixed sleeps where possible. Fall back to `sleep 2` only when no specific text to wait for
- Dismiss native browser `confirm()` dialogs with `steer hotkey escape --json` (equivalent to Cancel)
- Save a screenshot at the start of each phase: `steer screenshot --app Safari --path /tmp/steer/ep-membership-phase-N.png --json`

---

## Phase 0: First Load and Table Creation

### 0.1 Navigate to EP Membership settings
The first admin visit creates `ep_membership_tokens` and `ep_membership_log` tables.
- `steer hotkey cmd+l --json`
- `steer type "https://dev3.elmspark.com/admin/plugins/?plugin=EP_Membership" --clear --json`
- `steer hotkey return --json`
- `sleep 5`
- `steer see --app Safari --json`
- **VERIFY:**
  - [ ] Page loaded (not blank)
  - [ ] No "fatal error" or "Warning:" in page text

### 0.2 Navigate into EP Membership settings
PageMotor plugin settings require a POST (clicking the plugin name from the list). The GET URL shows the plugin list. Click on "EP Membership" in the plugin list, or find its "Settings" button.
- Click the "Settings" button next to "EP Membership" in the plugin list
- `sleep 3`
- `steer see --app Safari --json`
- `steer screenshot --app Safari --path /tmp/steer/ep-membership-phase-0.png --json`
- **VERIFY:**
  - [ ] EP Suite header visible with "EP Membership" branding
  - [ ] EP Suite navigation bar visible (showing EP Email, EP GDPR, EP Newsletter links)
  - [ ] Tagline "Membership, registration, and access control" visible
  - [ ] Four collapsible settings groups visible: Registration, Login, Profile, Access Control
  - [ ] Each group has an SVG icon and a subtitle description
  - [ ] EP Suite footer visible: "ElmsPark Consultants · EP Membership v0.1 · Documentation"

---

## Phase 1: Settings Groups — Registration

### 1.1 Expand Registration group
- Click on the "Registration" section header
- `sleep 1`
- `steer see --app Safari --json`
- `steer screenshot --app Safari --path /tmp/steer/ep-membership-phase-1.png --json`
- **VERIFY:**
  - [ ] "Enable Registration" checkbox visible with label "Allow new registrations"
  - [ ] "Email Verification" checkbox visible with label "Require email verification before login"
  - [ ] "Default Language" select dropdown visible with 11 South African languages
  - [ ] "After Registration Redirect" text input visible with placeholder "/courses"
  - [ ] "Welcome Email" checkbox visible with label "Send welcome email after registration"
  - [ ] "Newsletter" checkbox visible with label "Show newsletter opt-in on registration form"

### 1.2 Verify language dropdown options
- Click on the "Default Language" dropdown
- `sleep 1`
- `steer see --app Safari --json`
- **VERIFY:**
  - [ ] "English" option visible
  - [ ] "isiZulu" option visible
  - [ ] "Afrikaans" option visible
  - [ ] At least 11 options total
- Press Escape to close the dropdown: `steer hotkey escape --json`

---

## Phase 2: Settings Groups — Login

### 2.1 Collapse Registration, expand Login
- Click "Registration" header to collapse it
- Click "Login" header to expand it
- `sleep 1`
- `steer see --app Safari --json`
- **VERIFY:**
  - [ ] "Login Page Slug" text input visible with placeholder "login"
  - [ ] "Registration Page Slug" text input visible with placeholder "register"
  - [ ] "After Login Redirect" text input visible with placeholder "/courses"
  - [ ] "After Logout Redirect" text input visible with placeholder "/"
  - [ ] "Remember Me (days)" number input visible with placeholder "30"
  - [ ] "Max Login Attempts" number input visible with placeholder "5"
  - [ ] "Lockout Duration (minutes)" number input visible with placeholder "15"

---

## Phase 3: Settings Groups — Profile and Access Control

### 3.1 Collapse Login, expand Profile
- Click "Login" header to collapse it
- Click "Profile" header to expand it
- `sleep 1`
- `steer see --app Safari --json`
- **VERIFY:**
  - [ ] "Profile Page" checkbox visible with label "Enable member profile page"
  - [ ] "Profile Page Slug" text input visible with placeholder "profile"

### 3.2 Collapse Profile, expand Access Control
- Click "Profile" header to collapse it
- Click "Access Control" header to expand it
- `sleep 1`
- `steer see --app Safari --json`
- `steer screenshot --app Safari --path /tmp/steer/ep-membership-phase-3.png --json`
- **VERIFY:**
  - [ ] "Lesson Access" checkbox visible with label "Require login to view lessons"
  - [ ] "Enrolment Access" checkbox visible with label "Require login to enrol in courses"

### 3.3 Collapse Access Control
- Click "Access Control" header to collapse it
- `sleep 1`
- `steer see --app Safari --json`
- **VERIFY:**
  - [ ] All four groups are collapsed
  - [ ] No fields visible (only group headers with icons and subtitles)

---

## Phase 4: Settings Persistence — Save and Verify

### 4.1 Change a setting and save
- Click "Login" header to expand it
- `sleep 1`
- Find the "Max Login Attempts" input field
- Click on it and clear the value
- `steer type "10" --json`
- `sleep 1`
- Scroll to the top of the page
- Click the gold "Save Options" button in the PageMotor sticky bar (this is the ONLY time we click this button, to test settings persistence)
- `sleep 3`
- `steer see --app Safari --json`
- **VERIFY:**
  - [ ] Page reloaded without errors
  - [ ] No "fatal error" or "Warning:" visible

### 4.2 Navigate back to verify persistence
- Click the "Settings" button next to "EP Membership" in the plugin list
- `sleep 3`
- Click "Login" header to expand it
- `sleep 1`
- `steer see --app Safari --json`
- **VERIFY:**
  - [ ] "Max Login Attempts" field shows "10" (the value we just saved)

---

## Phase 5: Frontend — Registration Form

### 5.1 Navigate to register page
- `steer hotkey cmd+l --json`
- `steer type "https://dev3.elmspark.com/register" --clear --json`
- `steer hotkey return --json`
- `sleep 3`
- `steer see --app Safari --json`
- `steer screenshot --app Safari --path /tmp/steer/ep-membership-phase-5.png --json`
- **VERIFY:**
  - [ ] Page loaded (not blank)
  - [ ] No "fatal error" or "Warning:" visible
  - [ ] Registration form visible with class "auth-form"
  - [ ] "Full Name" field visible
  - [ ] "Email Address" field visible
  - [ ] "Preferred Language" dropdown visible
  - [ ] "Password" field visible
  - [ ] "Confirm Password" field visible
  - [ ] "Register" submit button visible
  - [ ] "Already have an account? Log in" link visible

### 5.2 Test client-side validation — password mismatch
- Click on the "Full Name" field
- `steer type "Test User" --json`
- Click on the "Email Address" field
- `steer type "testuser@example.com" --json`
- Click on the "Password" field
- `steer type "password123" --json`
- Click on the "Confirm Password" field
- `steer type "differentpass" --json`
- Click the "Register" button
- `sleep 2`
- `steer see --app Safari --json`
- **VERIFY:**
  - [ ] Error message visible: "Passwords do not match" (client-side JS) or server-side equivalent
  - [ ] Form is still visible (not submitted successfully)
  - [ ] "Full Name" field still contains "Test User" (values preserved)

### 5.3 Test server-side validation — short password
- Clear the "Password" field and type a short password
- Click on the "Password" field, select all, then type: `steer type "short" --clear --json`
- Click on the "Confirm Password" field, select all, then type: `steer type "short" --clear --json`
- Click the "Register" button
- `sleep 2`
- `steer see --app Safari --json`
- **VERIFY:**
  - [ ] Error message visible: "Password must be at least 8 characters"
  - [ ] Form is still visible

### 5.4 Successful registration
- Clear all fields and fill in valid data:
  - Full Name: "Test Learner"
  - Email: "testlearner-TIMESTAMP@example.com" (use current timestamp to ensure unique email)
  - Preferred Language: select "English"
  - Password: "TestPass123!"
  - Confirm Password: "TestPass123!"
- Click the "Register" button
- `sleep 3`
- `steer see --app Safari --json`
- `steer screenshot --app Safari --path /tmp/steer/ep-membership-phase-5-success.png --json`
- **VERIFY (if email verification is enabled):**
  - [ ] Redirected to /register?verify=pending
  - [ ] Message visible: "Check your email. We sent a verification link"
- **VERIFY (if email verification is disabled):**
  - [ ] Redirected to /courses (or the configured registration_redirect)
  - [ ] User is logged in

### 5.5 Test duplicate email
- Navigate back to /register
- `steer hotkey cmd+l --json`
- `steer type "https://dev3.elmspark.com/register" --clear --json`
- `steer hotkey return --json`
- `sleep 3`
- Fill in the same email as 5.4 with valid data
- Click "Register"
- `sleep 2`
- `steer see --app Safari --json`
- **VERIFY:**
  - [ ] Error message visible: "That email is already registered. Log in instead?"
  - [ ] Form still visible

---

## Phase 6: Frontend — Login Form

### 6.1 Navigate to login page
- `steer hotkey cmd+l --json`
- `steer type "https://dev3.elmspark.com/login" --clear --json`
- `steer hotkey return --json`
- `sleep 3`
- `steer see --app Safari --json`
- `steer screenshot --app Safari --path /tmp/steer/ep-membership-phase-6.png --json`
- **VERIFY:**
  - [ ] Page loaded (not blank)
  - [ ] No "fatal error" or "Warning:" visible
  - [ ] Login form visible with class "auth-form"
  - [ ] "Email Address" field visible
  - [ ] "Password" field visible
  - [ ] "Remember me" checkbox visible
  - [ ] "Log in" button visible
  - [ ] "Forgot your password?" link visible
  - [ ] "Don't have an account? Register" link visible

### 6.2 Test wrong password
- Click on the "Email Address" field
- `steer type "testlearner@example.com" --json`
- Click on the "Password" field
- `steer type "wrongpassword" --json`
- Click the "Log in" button
- `sleep 2`
- `steer see --app Safari --json`
- **VERIFY:**
  - [ ] Error message visible: "Invalid email or password."
  - [ ] Form still visible
  - [ ] Email field still contains the entered email

### 6.3 Test forgot password link
- Click "Forgot your password?" link
- `sleep 2`
- `steer see --app Safari --json`
- **VERIFY:**
  - [ ] Password reset form visible
  - [ ] "Email Address" field visible
  - [ ] "Send Reset Link" button visible
  - [ ] "Back to login" link visible
  - [ ] Text visible: "Enter your email address and we will send you a link to reset your password"

### 6.4 Submit password reset request
- Click on the "Email Address" field
- `steer type "testlearner@example.com" --json`
- Click "Send Reset Link"
- `sleep 2`
- `steer see --app Safari --json`
- **VERIFY:**
  - [ ] Success message visible: "If that email is registered, you will receive a reset link"
  - [ ] No error messages

### 6.5 Back to login
- Click "Back to login" link
- `sleep 2`
- `steer see --app Safari --json`
- **VERIFY:**
  - [ ] Login form visible again
  - [ ] "Email Address" and "Password" fields visible

---

## Phase 7: Frontend — Already Logged In State

If a test user is logged in from Phase 5.4 (email verification disabled), test these. Otherwise skip to Phase 8.

### 7.1 Visit register page while logged in
- `steer hotkey cmd+l --json`
- `steer type "https://dev3.elmspark.com/register" --clear --json`
- `steer hotkey return --json`
- `sleep 3`
- `steer see --app Safari --json`
- **VERIFY:**
  - [ ] Message visible: "You are already registered. View your profile."
  - [ ] "View your profile" is a link to /profile
  - [ ] Registration form is NOT visible

### 7.2 Visit login page while logged in
- `steer hotkey cmd+l --json`
- `steer type "https://dev3.elmspark.com/login" --clear --json`
- `steer hotkey return --json`
- `sleep 3`
- `steer see --app Safari --json`
- **VERIFY:**
  - [ ] Message visible: "Welcome back, [display name]"
  - [ ] Links visible: "Courses", "Profile", "Log out"
  - [ ] Login form is NOT visible

### 7.3 Visit profile page while logged in
- `steer hotkey cmd+l --json`
- `steer type "https://dev3.elmspark.com/profile" --clear --json`
- `steer hotkey return --json`
- `sleep 3`
- `steer see --app Safari --json`
- `steer screenshot --app Safari --path /tmp/steer/ep-membership-phase-7.png --json`
- **VERIFY:**
  - [ ] "Your Profile" heading visible
  - [ ] "Display Name" field visible
  - [ ] "Email" field visible (disabled/read-only)
  - [ ] "Preferred Language" dropdown visible
  - [ ] "Save Changes" button visible
  - [ ] "Change Password" section visible
  - [ ] "Current Password", "New Password", "Confirm New Password" fields visible
  - [ ] "Your Courses" section visible (may show "You have not enrolled in any courses yet")
  - [ ] "Log out" link visible

### 7.4 Update display name
- Click on the "Display Name" field
- Select all and type: `steer type "Updated Test Name" --clear --json`
- Click "Save Changes"
- `sleep 2`
- `steer see --app Safari --json`
- **VERIFY:**
  - [ ] Success message visible: "Profile updated."
  - [ ] "Display Name" field shows "Updated Test Name"

### 7.5 Logout
- Click the "Log out" link
- `sleep 3`
- `steer see --app Safari --json`
- **VERIFY:**
  - [ ] Redirected to homepage (or configured after_logout_redirect)
  - [ ] No longer logged in

---

## Phase 8: Frontend — Profile Requires Login

### 8.1 Visit profile page while logged out
- `steer hotkey cmd+l --json`
- `steer type "https://dev3.elmspark.com/profile" --clear --json`
- `steer hotkey return --json`
- `sleep 3`
- `steer see --app Safari --json`
- **VERIFY:**
  - [ ] Login form visible (profile redirects to login when not authenticated)
  - [ ] Profile content is NOT visible

---

## Phase 9: Admin — Learner Blocked from Admin

### 9.1 Log in as a learner and try to access admin
This test requires a learner account created in Phase 5.4 with email verification disabled, or a manually verified account. If no learner can log in, skip this phase.
- Log in as the test learner via /login
- `sleep 3`
- `steer hotkey cmd+l --json`
- `steer type "https://dev3.elmspark.com/admin/" --clear --json`
- `steer hotkey return --json`
- `sleep 3`
- `steer see --app Safari --json`
- `steer screenshot --app Safari --path /tmp/steer/ep-membership-phase-9.png --json`
- **VERIFY:**
  - [ ] Learner is NOT on the admin page
  - [ ] Redirected to /profile (the configured profile page slug)
  - [ ] No admin dashboard content visible

---

## Phase 10: Frontend Smoke Test

### 10.1 Verify frontend still loads
- `steer hotkey cmd+l --json`
- `steer type "https://dev3.elmspark.com/" --clear --json`
- `steer hotkey return --json`
- `sleep 3`
- `steer see --app Safari --json`
- `steer screenshot --app Safari --path /tmp/steer/ep-membership-phase-10.png --json`
- **VERIFY:**
  - [ ] Page loaded (not blank)
  - [ ] No "fatal error" or "Warning:" visible

### 10.2 HTTP confirmation
- Run: `curl -sL -o /dev/null -w '%{http_code} %{size_download}' 'https://dev3.elmspark.com/'`
- **VERIFY:**
  - [ ] Status code is 200
  - [ ] Size is > 1000 bytes

### 10.3 Verify admin still loads
- Run: `curl -sL -o /dev/null -w '%{http_code} %{size_download}' 'https://dev3.elmspark.com/admin/'`
- **VERIFY:**
  - [ ] Status code is 200
  - [ ] Size is > 1000 bytes

---

## Pass Criteria

ALL of the following must be true:
1. Settings page loads with EP Suite header, nav bar, and four styled groups (SVG icons + subtitles)
2. Registration group expands to show all 6 fields with correct types and defaults
3. Login group expands to show all 7 fields with correct placeholders
4. Profile group expands to show 2 fields; Access Control group expands to show 2 fields
5. Settings save and persist across page loads
6. Registration form renders with all fields, honeypot hidden, CSRF token present
7. Client-side validation catches password mismatch before submit
8. Server-side validation catches short passwords and duplicate emails
9. Successful registration either redirects to verify-pending or auto-logs in
10. Login form renders with email, password, remember me, and navigation links
11. Wrong password shows "Invalid email or password." without revealing which is wrong
12. Forgot password form shows, submits, and returns a success message
13. Logged-in users see welcome messages on /register and /login instead of forms
14. Profile page shows editable fields, password change section, and enrolled courses
15. Profile update saves and shows success message
16. Logout clears session and redirects
17. Profile page shows login form when not authenticated
18. Learners are redirected away from /admin/ to /profile
19. Frontend homepage still loads normally

## On Failure

Report each failed step with:
- Step number and name
- What was expected vs what happened
- Screenshot path (if captured)
- The last Steer command executed before the failure

### Common failure patterns

| Symptom | Likely cause |
|---------|-------------|
| Blank screen on every page | `if (!defined('PM_VERSION')) die();` guard in plugin.php. PageMotor does not define this constant |
| Settings page shows plugin list, not settings | Settings require POST, not GET. Must click the plugin "Settings" button |
| No SVG icons on group headers | Missing `ep_section_label()` call. Groups use bare string labels instead |
| No EP Suite styling | Missing `ep-suite-admin.css` file or wrong path in `css_settings()` |
| Registration form not visible on /register | Page does not have `[register-form]` shortcode. Create the page in PageMotor admin |
| Login fails with valid credentials | Email not verified. Check `require_email_verification` setting. Disable it for testing |
| "Too many failed attempts" immediately | Previous test runs left `login_failed` entries in `ep_membership_log`. Clear the table or wait for lockout to expire |
| Profile page blank | User cookie expired or was cleared. Log in again |
| Learner not redirected from admin | `construct()` admin guard not checking user type correctly. Check `$motor->user->options['type']` |
| Form submits but no redirect | `$motor->redirect()` requires `exit` after `header()`. Check redirect calls |
| CSRF error on every form submit | `set_frontend_csrf_cookie()` not called in `construct()` for non-admin pages |
| PHP fatal on frontend | `settings()` or `construct()` calling undefined method. Check `load_includes()` is NOT used |
