# Test: Admin Login

## Prerequisites
- Safari is open
- PM_DEV_URL, PM_ADMIN_USER, PM_ADMIN_PASS are set in environment

## Steps

### 1. Navigate to admin
- Open: $PM_DEV_URL/admin/
- Wait for page to load (3-5 seconds)
- Screenshot and verify:
  - [ ] Page loads (not blank)
  - [ ] No PHP errors in visible text
  - [ ] Login form is visible (look for "Log In" button or "Username" field)

### 2. Enter credentials
- Find the username/email field and type $PM_ADMIN_USER
- Tab to the password field and type $PM_ADMIN_PASS
- Click the "Log In" button

### 3. Verify dashboard
- Wait for page to load (3-5 seconds)
- Screenshot and verify:
  - [ ] Admin dashboard is visible
  - [ ] No PHP errors
  - [ ] "Content" or "Plugins" or "Themes" text is visible (dashboard module cards)

## Pass Criteria
All checkboxes above must pass. The admin dashboard must be reachable after login.

## On Failure
Capture a screenshot and report which step failed. Check if the dev site is responsive with a curl first.
