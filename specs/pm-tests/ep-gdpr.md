# Test: EP GDPR Settings Page

## Prerequisites
- Logged into admin
- EP GDPR is active on the dev site

## Steps

### 1. Navigate to EP GDPR settings
- Open: $PM_DEV_URL/admin/plugins/?plugin=EP_GDPR
- Wait for page to load (5 seconds)
- Screenshot and verify:
  - [ ] Page loads without PHP errors
  - [ ] "GDPR" text visible in heading or breadcrumb

### 2. Verify form fields
- Verify:
  - [ ] At least one text input or checkbox exists
  - [ ] Cookie banner settings are present (look for "cookie" or "consent" text)

### 3. Verify save button
- [ ] Save button exists and is enabled
- [ ] Do NOT click save

## Pass Criteria
Settings page loads with GDPR-specific form fields. No PHP errors.

## On Failure
Check if EP GDPR's settings() method or class-ep-suite.php crashed.
