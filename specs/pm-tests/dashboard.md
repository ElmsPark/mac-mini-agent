# Test: Admin Dashboard

## Prerequisites
- Logged into admin (run login.md first)

## Steps

### 1. Navigate to dashboard
- Open: $PM_DEV_URL/admin/
- Wait for page to load
- Screenshot and verify:
  - [ ] Page loads without PHP errors
  - [ ] Dashboard heading or breadcrumb visible

### 2. Verify module cards
- Search the accessibility tree for these text labels:
  - [ ] "Content" (content management module)
  - [ ] "Plugins" (plugin management module)
  - [ ] "Themes" (theme management module)
  - [ ] "Users" (user management module)

### 3. Verify navigation works
- Click on "Plugins" link/card
- Wait for navigation (3 seconds)
- Screenshot and verify:
  - [ ] Plugin list page loaded
  - [ ] No PHP errors

## Pass Criteria
Dashboard loads with module cards visible. Navigation to Plugins page works.

## On Failure
Report which module cards are missing. Screenshot both dashboard and the failed navigation.
